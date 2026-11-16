import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, String> parametresCallback(Uri uri) {
  final fragment = uri.fragment.isEmpty
      ? <String, String>{}
      : Uri.splitQueryString(uri.fragment);
  return {...fragment, ...uri.queryParameters};
}

Future<void> finaliserCallbackRecuperation(
  SupabaseClient client,
  Uri uri,
) async {
  final estRouteRecuperation =
      uri.path == '/reset-password' || uri.host == 'reset-password';
  if (!estRouteRecuperation || client.auth.currentSession != null) return;

  final parametres = parametresCallback(uri);
  final code = parametres['code'];
  if (code != null && code.isNotEmpty) {
    await client.auth.getSessionFromUrl(uri);
    return;
  }

  final accessToken = parametres['access_token'];
  if (accessToken != null && accessToken.isNotEmpty) {
    await client.auth.getSessionFromUrl(uri);
    return;
  }

  final tokenHash = parametres['token_hash'];
  if (tokenHash != null &&
      tokenHash.isNotEmpty &&
      parametres['type'] == 'recovery') {
    await client.auth.verifyOTP(tokenHash: tokenHash, type: OtpType.recovery);
  }
}
