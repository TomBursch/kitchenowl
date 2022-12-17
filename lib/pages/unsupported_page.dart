import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class UnsupportedPage extends StatelessWidget {
  final bool unsupportedBackend;
  final bool canForceOfflineMode;

  const UnsupportedPage({
    Key? key,
    required this.unsupportedBackend,
    this.canForceOfflineMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  '\\:',
                  style: Theme.of(context).textTheme.headline2,
                ),
                const SizedBox(height: 10),
                Text(
                  unsupportedBackend
                      ? AppLocalizations.of(context)!.unsupportedBackendMessage
                      : AppLocalizations.of(context)!
                          .unsupportedFrontendMessage,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.refresh),
                    onPressed: BlocProvider.of<AuthCubit>(context).refresh,
                  ),
                ),
                if (!kIsWeb && canForceOfflineMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 100,
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(AppLocalizations.of(context)!.or),
                      ),
                      const SizedBox(
                        width: 100,
                        child: Divider(),
                      ),
                    ],
                  ),
                if (!kIsWeb && canForceOfflineMode)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_off_rounded),
                      label:
                          Text(AppLocalizations.of(context)!.forceOfflineMode),
                      onPressed: () => BlocProvider.of<AuthCubit>(context)
                          .setForcedOfflineMode(true),
                    ),
                  ),
                const Spacer(),
                if (!kIsWeb)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      onPressed: () =>
                          BlocProvider.of<AuthCubit>(context).removeServer(),
                      label: Text(AppLocalizations.of(context)!.serverChange),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
