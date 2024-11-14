import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/services/api/analytics.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(primary: true, slivers: [
        const SliverAppBar(
          title: Text("Dashboard"),
          floating: true,
        ),
        FutureBuilder(
          future: ApiService.getInstance().getAnalyticsOverview(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SliverToBoxAdapter(child: SizedBox());
            }
            final data = snapshot.data!;

            return SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  title: const Text("Users"),
                  trailing: Text(data['users']['total'].toString()),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Verified"),
                  subtitle: const Text("Verified their email"),
                  trailing: Text(
                    "${data['users']['verified'].toString()} (${NumberFormat.percentPattern().format(data['users']['verified'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Linked social account"),
                  trailing: Text(
                      "${data['users']['linked_account']} (${NumberFormat.percentPattern().format(data['users']['linked_account'] / data['users']['total'])})"),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Online"),
                  subtitle: const Text("Online in the last 15 minutes"),
                  trailing: Text(
                    "${data['users']['online'].toString()} (${NumberFormat.percentPattern().format(data['users']['online'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Montly Active"),
                  subtitle: const Text("Online in the last 30 days"),
                  trailing: Text(
                    "${data['users']['active'].toString()} (${NumberFormat.percentPattern().format(data['users']['active'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Daily Active"),
                  subtitle: const Text("Online today"),
                  trailing: Text(
                    "${data['users']['dau'].toString()} (${NumberFormat.percentPattern().format(data['users']['dau'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Weekly Active"),
                  subtitle: const Text("Online this week"),
                  trailing: Text(
                    "${data['users']['wau'].toString()} (${NumberFormat.percentPattern().format(data['users']['wau'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Older than 30 days"),
                  trailing: Text(
                    "${data['users']['old'].toString()} (${NumberFormat.percentPattern().format(data['users']['old'] / data['users']['total'])})",
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("Active and older than 30 days"),
                  trailing: Text(
                    "${data['users']['old_active'].toString()} (${NumberFormat.percentPattern().format(data['users']['old_active'] / data['users']['old'])})",
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Households"),
                  trailing: Text(data['households']['total'].toString()),
                ),
                ListTile(
                  dense: true,
                  title: const Text("with Balances"),
                  trailing: Text("${data['households']['expense_feature']}"),
                ),
                ListTile(
                  dense: true,
                  title: const Text("with Planner"),
                  trailing: Text("${data['households']['planner_feature']}"),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Available storage"),
                  trailing: Text(
                    "${_readableByteSize(data['available_storage'] - data['free_storage'])}/${_readableByteSize(data['available_storage'])}",
                  ),
                  subtitle: LinearProgressIndicator(
                    value: 1 - data['free_storage'] / data['available_storage']
                        as double,
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  String _readableByteSize(int value, {bool base1024 = false}) {
    final base = base1024 ? 1024 : 1000;
    if (value <= 0) return "0";
    final units = ["B", "kB", "MB", "GB", "TB"];
    int digitGroups = (log(value) / log(base)).floor();

    return "${NumberFormat("#,##0.#").format(value / pow(base, digitGroups))} ${units[digitGroups]}";
  }
}
