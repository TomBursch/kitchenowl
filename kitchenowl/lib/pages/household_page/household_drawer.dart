import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:transparent_image/transparent_image.dart';

class HouseholdDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<ViewsEnum> pages;
  final void Function(BuildContext, ViewsEnum, ViewsEnum) onPageSelected;
  final bool popOnSelection;

  const HouseholdDrawer({
    super.key,
    required this.selectedIndex,
    required this.pages,
    required this.onPageSelected,
    this.popOnSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      selectedIndex: selectedIndex >= pages.length - 1 ? null : selectedIndex,
      onDestinationSelected: (i) {
        if (popOnSelection) Navigator.of(context).pop();
        if (i < pages.length - 1) {
          onPageSelected(
            context,
            pages[i],
            pages[selectedIndex],
          );
        } else if (i == pages.length - 1) {
          context.go("/household");
        } else if (i == pages.length) {
          context.push("/settings/account").then((res) {
            if (res == UpdateEnum.updated) {
              context.read<AuthCubit>().refreshUser();
            }
          });
        } else if (i == pages.length + 1) {
          context.push(
            "/settings",
            extra: context.read<HouseholdCubit>().state.household,
          );
        }
      },
      children: [
        BlocBuilder<HouseholdCubit, HouseholdState>(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.household.image != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 150,
                        child: FadeInImage(
                          fit: BoxFit.cover,
                          placeholder: state.household.imageHash != null
                              ? BlurHashImage(state.household.imageHash!)
                              : MemoryImage(kTransparentImage) as ImageProvider,
                          image: getImageProvider(
                            context,
                            state.household.image!,
                          ),
                        ),
                      ),
                    ),
                  ),
                Text(
                  state.household.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        ...pages.where((e) => e != ViewsEnum.profile).map(
          (ViewsEnum destination) {
            return NavigationDrawerDestination(
              label: Text(
                destination.toLocalizedString(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              icon: Icon(destination.toIcon(context)),
              selectedIcon: Icon(destination.toSelectedIcon(context)),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 10),
          child: Divider(),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.swap_horiz_rounded),
          label: Text(
            AppLocalizations.of(context)!.householdSwitch,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        NavigationDrawerDestination(
          icon: Icon(
            App.isOffline ? Icons.cloud_off_rounded : Icons.person_rounded,
          ),
          label: Text(
            AppLocalizations.of(context)!.profile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings),
          label: Text(
            AppLocalizations.of(context)!.settings,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
