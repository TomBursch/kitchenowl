import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/token.dart';
import 'package:kitchenowl/widgets/settings/token_bottom_sheet.dart';

class TokenCard extends StatelessWidget {
  final Token token;
  final void Function()? onLogout;

  const TokenCard({super.key, required this.token, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final child = Card(
      child: ListTile(
        title: Text(
          token.name,
        ),
        subtitle: token.lastUsedAt != null
            ? Text(
                "${AppLocalizations.of(context)!.lastUsed}: ${DateFormat.yMMMEd().add_jm().format(
                      token.lastUsedAt!,
                    )}",
              )
            : null,
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (context) => TokenBottomSheet(
            token: token,
            onLogout: onLogout,
          ),
        ),
      ),
    );

    if (onLogout == null) return child;

    return Dismissible(
      key: ValueKey<Token>(token),
      confirmDismiss: (direction) async {
        return (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.lltDelete,
          ),
          content: Text(
            AppLocalizations.of(context)!.lltDeleteConfirmation(
              token.name,
            ),
          ),
        ));
      },
      onDismissed: (_) => onLogout!(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: child,
    );
  }
}
