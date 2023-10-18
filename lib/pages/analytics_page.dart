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
                  title: const Text("Total users"),
                  trailing: Text(data['total_users'].toString()),
                ),
                ListTile(
                  title: const Text("Active users"),
                  subtitle: const Text("Online in the last 30 days"),
                  trailing: Text(
                    "${data['active_users'].toString()} (${NumberFormat.percentPattern().format(data['active_users'] / data['total_users'])})",
                  ),
                ),
                ListTile(
                  title: const Text("Households"),
                  trailing: Text(data['total_households'].toString()),
                ),
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
