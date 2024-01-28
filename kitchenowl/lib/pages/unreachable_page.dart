import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class UnreachablePage extends StatelessWidget {
  const UnreachablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: !kIsWeb
          ? AppBar(
              actions: [
                PopupMenuButton(
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    PopupMenuItem<int>(
                      value: 0,
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz_rounded),
                        title: Text(AppLocalizations.of(context)!.serverChange),
                      ),
                    ),
                  ],
                  onSelected: (_) {
                    BlocProvider.of<AuthCubit>(context).removeServer();
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\\:',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.unreachableMessage,
                maxLines: null,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: BlocProvider.of<AuthCubit>(context).refresh,
                child: Text(AppLocalizations.of(context)!.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
