import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class UnreachablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\\:',
              style: Theme.of(context).textTheme.headline2,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).unreachableMessage,
              maxLines: null,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: BlocProvider.of<AuthCubit>(context).refresh,
              child: Text(AppLocalizations.of(context).refresh),
            ),
            Text(AppLocalizations.of(context).or),
            TextButton(
                onPressed: () =>
                    BlocProvider.of<AuthCubit>(context).removeServer(),
                child: Text(AppLocalizations.of(context).serverChange)),
          ],
        ),
      ),
    );
  }
}
