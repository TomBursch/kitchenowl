import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/agent_chat_list_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';

/// Floating action button shown on the agent chat list page.
/// Tapping it creates a new chat and navigates to it.
///
/// If [personaId] is provided, the new chat is created for that persona;
/// otherwise the cubit falls back to the user's / household defaults.
/// The persona can still be changed from within the chat itself while the
/// conversation is still empty (see the persona switcher on the empty
/// chat hero in `AgentChatPage`).
class AgentNewChatFab extends StatelessWidget {
  final int? personaId;

  const AgentNewChatFab({super.key, this.personaId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'agentNewChat',
      onPressed: () => _createChat(context),
      child: const Icon(Icons.add_comment_outlined),
    );
  }

  Future<void> _createChat(BuildContext context) async {
    final household =
        context.read<HouseholdCubit>().state.household;
    final cubit = context.read<AgentChatListCubit>();
    final chatId = await cubit.createChat(personaId: personaId);
    if (chatId == null || !context.mounted) return;
    context.push(
      '/household/${household.id}/agent/$chatId',
      extra: household,
    );
  }
}
