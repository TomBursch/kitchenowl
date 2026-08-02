import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/agent_settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/llm_config.dart';
import 'package:kitchenowl/pages/agent_personas_page.dart';

class AgentSettingsPage extends StatefulWidget {
  final Household household;

  const AgentSettingsPage({super.key, required this.household});

  @override
  State<AgentSettingsPage> createState() => _AgentSettingsPageState();
}

class _AgentSettingsPageState extends State<AgentSettingsPage> {
  late final AgentSettingsCubit _cubit;

  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _braveApiKeyCtrl = TextEditingController();
  final _systemPromptCtrl = TextEditingController();
  final _initialGreetingCtrl = TextEditingController();
  LLMProvider _provider = LLMProvider.openai;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _cubit = AgentSettingsCubit(widget.household);
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _braveApiKeyCtrl.dispose();
    _systemPromptCtrl.dispose();
    _initialGreetingCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _hydrate(LLMConfig cfg) {
    if (_initialized) return;
    _initialized = true;
    _provider = cfg.provider;
    _baseUrlCtrl.text = cfg.baseUrl ?? '';
    _modelCtrl.text = cfg.model ?? '';
    _systemPromptCtrl.text = cfg.systemPrompt ?? '';
    _initialGreetingCtrl.text = cfg.initialGreeting ?? '';
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await _cubit.save(
      provider: _provider,
      baseUrl: _baseUrlCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.isNotEmpty ? _apiKeyCtrl.text : null,
      braveSearchApiKey:
          _braveApiKeyCtrl.text.isNotEmpty ? _braveApiKeyCtrl.text : null,
      systemPrompt: _systemPromptCtrl.text,
      initialGreeting: _initialGreetingCtrl.text,
      enabled: true,
    );
    if (!mounted) return;
    if (ok) {
      _apiKeyCtrl.clear();
      _braveApiKeyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.saved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.agentSettings),
        ),
        body: BlocConsumer<AgentSettingsCubit, AgentSettingsState>(
          listenWhen: (a, b) => !_initialized && b.config != null,
          listener: (context, state) {
            if (state.config != null) {
              setState(() => _hydrate(state.config!));
            }
          },
          builder: (context, state) {
            if (state.loading && state.config == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final cfg = state.config;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    loc.agentSettingsDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<LLMProvider>(
                    value: _provider,
                    decoration: InputDecoration(labelText: loc.agentProvider),
                    items: LLMProvider.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(_providerLabel(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _provider = v ?? _provider;
                      if (_provider == LLMProvider.gemini &&
                          _modelCtrl.text.trim().isEmpty) {
                        _modelCtrl.text = 'gemini-flash-latest';
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentBaseUrl,
                      hintText: cfg?.defaultBaseUrl ?? '',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modelCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentModel,
                      hintText: 'gemini-flash-latest / gpt-4o-mini / ...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentApiKey,
                      helperText: cfg?.apiKeySet == true
                          ? loc.agentApiKeyStored
                          : loc.agentApiKeyMissing,
                    ),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _braveApiKeyCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentBraveApiKey,
                      helperText: cfg?.braveSearchApiKeySet == true
                          ? loc.agentBraveApiKeyStored
                          : loc.agentBraveApiKeyMissing,
                    ),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _initialGreetingCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentInitialGreeting,
                      helperText: loc.agentInitialGreetingHelp,
                      helperMaxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _systemPromptCtrl,
                    decoration: InputDecoration(
                      labelText: loc.agentPreferences,
                      helperText: loc.agentPreferencesHelp,
                      helperMaxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: state.saving ? null : () => _save(),
                          icon: state.saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(loc.save),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.testing
                              ? null
                              : () => _cubit.testConnection(),
                          icon: state.testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded),
                          label: Text(loc.agentTestConnection),
                        ),
                      ),
                    ],
                  ),
                  if (state.testMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: state.testOk == true
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          state.testOk == true
                              ? (state.testMessage == 'ok'
                                  ? loc.agentTestOk
                                  : '${loc.agentTestOk}: ${state.testMessage}')
                              : '${loc.agentTestFailed}: ${state.testMessage}',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(loc.agentPersonas),
                    subtitle: Text(loc.agentPersonasSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            AgentPersonasPage(household: widget.household),
                      ));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _providerLabel(LLMProvider p) {
    switch (p) {
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.gemini:
        return 'Google Gemini';
      case LLMProvider.custom:
        return 'Custom (OpenAI-compatible)';
    }
  }
}
