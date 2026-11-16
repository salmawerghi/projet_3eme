// =====================================================================
// DarImmo - Point d'entrée (tâche 1.6)
//
// Lancer avec les clés (fichier env.json non versionné, voir env.example.json) :
//   flutter run --dart-define-from-file=env.json
// =====================================================================
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/app.dart';
import 'package:darimmo/core/config/env.dart';
import 'package:darimmo/core/router/app_router.dart';
import 'package:darimmo/core/services.dart';
import 'package:darimmo/features/auth/data/services/callback_recuperation.dart';
import 'package:darimmo/features/notifications/data/push_service.dart';

/// Notification reçue application fermée / en arrière-plan : Android l'affiche
/// lui-même. Doit être une fonction de haut niveau.
@pragma('vm:entry-point')
Future<void> _messageEnArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp();
}

String? _routeDepuisLien(Uri? uri) {
  if (uri == null) return null;
  if (uri.host == 'reset-password' || uri.path == '/reset-password') {
    return '/reset-password';
  }
  if (uri.host == 'connexion' || uri.path == '/connexion') {
    return '/bienvenue/connexion';
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.complet) {
    runApp(const _ConfigurationManquante());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey,
  );
  final client = Supabase.instance.client;
  try {
    await finaliserCallbackRecuperation(client, Uri.base);
  } on AuthException catch (e) {
    debugPrint('Callback de récupération Supabase refusé (${e.code}).');
  } catch (e) {
    debugPrint('Impossible de finaliser le callback de récupération: $e');
  }
  final services = Services.supabase(client);

  String? initiale = kIsWeb ? _routeDepuisLien(Uri.base) : null;
  final appLinks = AppLinks();
  try {
    if (!kIsWeb) {
      final lienInitial = await appLinks.getInitialLink();
      final routeInitiale = _routeDepuisLien(lienInitial);
      if (routeInitiale != null) initiale = routeInitiale;
    }
  } catch (_) {
    // Le deep link n’est pas disponible en l’absence d’un scheme valide.
  }

  final routeur = creerRouteur(
    services,
    initiale:
        initiale ?? (services.auth.estConnecte ? '/accueil' : '/bienvenue'),
  );
  appLinks.uriLinkStream.listen((uri) {
    final route = _routeDepuisLien(uri);
    if (route != null) {
      routeur.go(route);
      if (kIsWeb) {
        finaliserCallbackRecuperation(client, uri).catchError((Object e) {
          debugPrint('Impossible de finaliser le lien de récupération: $e');
        });
      }
    }
  });

  // Notifications push : Android uniquement, et seulement si Firebase est
  // configuré (android/app/google-services.json). Sinon l'app marche sans.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_messageEnArrierePlan);
      services.push = PushService(
        Supabase.instance.client,
        ouvrir: routeur.push,
        messager: cleMessager,
      );
      if (services.auth.estConnecte) {
        services.push!.enregistrer(); // session déjà ouverte
      }
    } catch (e) {
      debugPrint('Firebase non configuré : notifications désactivées ($e)');
    }
  }

  runApp(DarImmoApp(routeur: routeur));
}

/// Affiché si l'app est lancée sans --dart-define-from-file=env.json.
class _ConfigurationManquante extends StatelessWidget {
  const _ConfigurationManquante();
  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Clés Supabase manquantes.\n\nCopiez env.example.json en env.json, remplissez-le, '
            'puis lancez :\nflutter run --dart-define-from-file=env.json',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
