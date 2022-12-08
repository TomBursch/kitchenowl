import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/views_enum.dart';

mixin HomePageItem on Widget {
  // ignore: no-empty-block
  void onSelected(BuildContext context, bool alreadySelected) {}
  ViewsEnum type();
  String label(BuildContext context) => type().toLocalizedString(context);
  IconData icon(BuildContext context) => type().toIcon();
  Widget? floatingActionButton(BuildContext context) => null;
  bool isActive(BuildContext context) => true;
}
