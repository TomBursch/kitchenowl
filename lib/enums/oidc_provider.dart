import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum OIDCProivder {
  custom,
  google,
  apple;

  Widget toIcon(BuildContext context) {
    return const [
      Icon(Icons.turn_slight_left_outlined),
      Image(
        image: AssetImage('assets/images/google_logo.png'),
        height: 32,
      ),
      Icon(Icons.apple_rounded),
    ][index];
  }

  String toLocalizedString() {
    return const ["OIDC", "Google", "Apple"][index];
  }

  @override
  String toString() {
    return name;
  }

  static OIDCProivder? parse(String str) {
    switch (str) {
      case 'custom':
        return OIDCProivder.custom;
      case 'google':
        return OIDCProivder.google;
      case 'apple':
        return OIDCProivder.apple;
      default:
        return null;
    }
  }

  Future<void> login(BuildContext context) async {
    if (this == OIDCProivder.apple) {
      final res = await ApiService.getInstance().getLoginOIDCUrl(toString());
      if (res.$2 == null || res.$3 == null) return;
      try {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          state: res.$2,
          nonce: res.$3,
        );
        return BlocProvider.of<AuthCubit>(context).loginOIDC(
          credential.state!,
          credential.authorizationCode,
          (message) => showSnackbar(
            context: context,
            content: Text((message?.contains("DONE") ?? false)
                ? AppLocalizations.of(context)!.done
                : AppLocalizations.of(context)!.error),
            width: null,
          ),
        );
      } catch (_) {
        showSnackbar(
          context: context,
          content: Text(AppLocalizations.of(context)!.error),
          width: null,
        );
      }
    } else {
      final url =
          (await ApiService.getInstance().getLoginOIDCUrl(toString())).$1;
      if (url != null) return openUrl(context, url);
    }
  }
}
