import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';

import 'household_drawer.dart';

class HouseholdNavigationRail extends StatelessWidget {
  final bool extendedRail;
  final int selectedIndex;
  final List<ViewsEnum> pages;
  final void Function(BuildContext, ViewsEnum, ViewsEnum) onPageSelected;
  final void Function() openDrawer;

  const HouseholdNavigationRail({
    super.key,
    required this.extendedRail,
    required this.selectedIndex,
    required this.pages,
    required this.onPageSelected,
    required this.openDrawer,
  });

  @override
  Widget build(BuildContext context) {
    if (extendedRail) {
      return HouseholdDrawer(
        onPageSelected: onPageSelected,
        pages: pages,
        selectedIndex: selectedIndex,
      );
    }

    return NavigationRail(
      extended: extendedRail,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.menu_rounded),
          label: Text(AppLocalizations.of(context)!.more),
        ),
        ...pages
            .where((e) => e != ViewsEnum.more)
            .map((e) => NavigationRailDestination(
                  label: Text(e.toLocalizedString(context)),
                  icon: Icon(e.toIcon(context)),
                  selectedIcon: Icon(e.toSelectedIcon(context)),
                )),
      ],
      selectedIndex: selectedIndex + 1,
      onDestinationSelected: (i) {
        if (i == 0) {
          openDrawer();
        } else {
          i--;
          onPageSelected(
            context,
            pages[i],
            pages[selectedIndex],
          );
        }
      },
    );
  }
}
