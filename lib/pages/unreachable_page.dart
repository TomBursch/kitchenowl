import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class UnreachablePage extends StatelessWidget {
  const UnreachablePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                '\\:',
                style: Theme.of(context).textTheme.headline2,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.unreachableMessage,
                maxLines: null,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: BlocProvider.of<AuthCubit>(context).refresh,
                child: Text(AppLocalizations.of(context)!.refresh),
              ),
              const Spacer(),
              if (!kIsWeb)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(AppLocalizations.of(context)!.serverChange),
                    onPressed: () =>
                        BlocProvider.of<AuthCubit>(context).removeServer(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
