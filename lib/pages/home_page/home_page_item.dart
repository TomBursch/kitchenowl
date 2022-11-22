import 'package:flutter/material.dart';

mixin HomePageItem on Widget {
  // ignore: no-empty-block
  void onSelected(BuildContext context, bool alreadySelected) {}
  IconData icon(BuildContext context);
  String label(BuildContext context);
  Widget? floatingActionButton(BuildContext context) => null;
  bool isActive(BuildContext context) => true;
}
