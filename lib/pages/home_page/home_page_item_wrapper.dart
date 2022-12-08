import 'package:flutter/material.dart';
import 'package:kitchenowl/pages/home_page/home_page_item.dart';

class HomePageItemWrapper extends StatelessWidget {
  final HomePageItem homePageItem;

  const HomePageItemWrapper({super.key, required this.homePageItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(homePageItem.label(context))),
      body: homePageItem,
      floatingActionButton: homePageItem.floatingActionButton(context),
    );
  }
}
