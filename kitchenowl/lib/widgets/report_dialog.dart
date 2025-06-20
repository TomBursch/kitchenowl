import 'package:flutter/material.dart';
import 'package:kitchenowl/gen/l10n/app_localizations.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/api/report.dart';
import 'package:kitchenowl/widgets/text_dialog.dart';

class ReportDialog extends StatelessWidget {
  final Recipe? recipe;
  final User? user;

  const ReportDialog({super.key, this.recipe, this.user})
      : assert(recipe != null || user != null);

  @override
  Widget build(BuildContext context) {
    return TextDialog(
      title: recipe != null
          ? AppLocalizations.of(context)!.reportRecipe
          : AppLocalizations.of(context)!.reportUser,
      doneText: AppLocalizations.of(context)!.send,
      hintText: AppLocalizations.of(context)!.reason,
      onDone: (description) => {
        ApiService.getInstance().addReport(
          description: description,
          recipe: recipe,
          user: user,
        )
      },
    );
  }
}
