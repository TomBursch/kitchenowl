import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/loyalty_card_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/pages/loyalty_card_add_update_page.dart';
import 'package:kitchenowl/widgets/loyalty_card_item.dart';

class LoyaltyCardListPageStandalone extends StatelessWidget {
  final Household household;

  const LoyaltyCardListPageStandalone({
    super.key,
    required this.household,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<LoyaltyCardListCubit>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loyaltyCards),
        leading: BackButton(
          onPressed: () {
            // Check if we can pop, otherwise go back to the household items page
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/household/${household.id}/items');
            }
          },
        ),
      ),
      floatingActionButton: App.isOffline
          ? null
          : FloatingActionButton.extended(
              heroTag: 'addLoyaltyCardFab',
              onPressed: () async {
                final result = await Navigator.of(context).push<LoyaltyCard>(
                  MaterialPageRoute(
                    builder: (context) => LoyaltyCardAddUpdatePage(
                      household: household,
                    ),
                  ),
                );
                if (result != null) {
                  cubit.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.add),
            ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: BlocBuilder<LoyaltyCardListCubit, LoyaltyCardListCubitState>(
          bloc: cubit,
          builder: (context, state) {
            if (state is LoadingLoyaltyCardListCubitState &&
                state.loyaltyCards.isEmpty) {
              return _buildLoadingState(context);
            }

            if (state.loyaltyCards.isEmpty && !App.isOffline) {
              return _buildEmptyState(context, cubit);
            }

            if (state.loyaltyCards.isEmpty && App.isOffline) {
              return _buildOfflineState(context);
            }

            return _buildCardGrid(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }

  Widget _buildEmptyState(BuildContext context, LoyaltyCardListCubit cubit) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wallet_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.loyaltyCardsEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.loyaltyCardsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<LoyaltyCard>(
                  MaterialPageRoute(
                    builder: (context) => LoyaltyCardAddUpdatePage(
                      household: household,
                    ),
                  ),
                );
                if (result != null) {
                  cubit.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.loyaltyCardAdd),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.offlineMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(
    BuildContext context,
    LoyaltyCardListCubitState state,
  ) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final card = state.loyaltyCards[index];
                return Hero(
                  tag: 'loyalty_card_${card.id}',
                  child: LoyaltyCardItem(
                    loyaltyCard: card,
                    onTap: () {
                      context.push(
                        "/household/${household.id}/loyalty-cards/${card.id}",
                        extra: card,
                      );
                    },
                  ),
                );
              },
              childCount: state.loyaltyCards.length,
            ),
          ),
        ),
      ],
    );
  }
}

