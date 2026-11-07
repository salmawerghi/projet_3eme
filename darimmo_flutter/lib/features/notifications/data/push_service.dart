// =====================================================================
// DarImmo - [8.1] [8.2] Notifications push (Firebase Cloud Messaging)
// Membre C — repris du PoC (tâche 1.7)
//
// - après la connexion : autorisation (Android 13+), jeton FCM enregistré
//   dans public.device_tokens ;
// - Edge Function send_push + Database Webhooks (messages INSERT,
//   annonces UPDATE) envoient les notifications côté serveur ;
// - toucher une notification ouvre la discussion ou « Mes annonces ».
// Actif seulement sur Android ET si android/app/google-services.json existe.
// =====================================================================
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// getToken / onTokenRefresh sont dépréciés dans firebase_messaging 17 au profit
// de register() / onRegistered (identifiant d'installation). On garde le jeton
// FCM classique, que l'API d'envoi FCM v1 de l'Edge Function utilise.
// ignore_for_file: deprecated_member_use

class PushService {
  PushService(this._client, {required this.ouvrir, required this.messager});

  final SupabaseClient _client;

  /// Ouvre un écran de l'application (ex : `routeur.push('/messages/<id>')`).
  final void Function(String chemin) ouvrir;

  /// Pour afficher un bandeau quand une notification arrive app ouverte.
  final GlobalKey<ScaffoldMessengerState> messager;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  StreamSubscription<String>? _renouvellement;
  bool _ecoutesPretes = false;
  String? jeton;

  /// À appeler après la connexion.
  Future<void> enregistrer() async {
    await _fcm.requestPermission();
    jeton = await _fcm.getToken();
    if (jeton != null) await _sauver(jeton!);
    _renouvellement ??= _fcm.onTokenRefresh.listen((t) {
      jeton = t;
      _sauver(t);
    });

    if (_ecoutesPretes) return;
    _ecoutesPretes = true;
    // Application ouverte : Android n'affiche pas la notification, on montre un bandeau.
    FirebaseMessaging.onMessage.listen((m) {
      messager.currentState?.showSnackBar(SnackBar(
        content: Text('${m.notification?.title ?? 'Notification'}\n${m.notification?.body ?? ''}'),
        action: SnackBarAction(label: 'Ouvrir', onPressed: () => _ouvrir(m.data)),
      ));
    });
    // Notification touchée, application en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _ouvrir(m.data));
    // Notification touchée, application fermée.
    final initiale = await _fcm.getInitialMessage();
    if (initiale != null) _ouvrir(initiale.data);
  }

  /// À appeler AVANT la déconnexion : l'appareil ne reçoit plus les push de ce compte.
  Future<void> desinscrire() async {
    final t = jeton;
    if (t != null) await _client.from('device_tokens').delete().eq('token', t);
  }

  Future<void> _sauver(String t) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('device_tokens').upsert(
      {'id_user': user.id, 'token': t, 'plateforme': 'android', 'date_maj': DateTime.now().toIso8601String()},
      onConflict: 'token',
    );
  }

  /// Écran à ouvrir pour une notification (données envoyées par send_push).
  static String? cheminPour(Map<String, dynamic> data) {
    if (data['type'] == 'message' && data['id_conversation'] != null) return '/messages/${data['id_conversation']}';
    if (data['type'] == 'statut') return '/mes-annonces'; // [8.2] -> 6.3 / 6.5
    return null;
  }

  void _ouvrir(Map<String, dynamic> data) {
    final chemin = cheminPour(data);
    if (chemin != null) ouvrir(chemin);
  }
}
