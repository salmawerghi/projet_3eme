// =====================================================================
// DarImmo - AuthRepository (squelette 1.6 ; stories 2.1 / 2.2 du membre A)
//
// État de connexion de l'application. Le routeur (core/router) l'écoute
// pour envoyer vers l'écran de connexion quand il n'y a pas de session.
// Le membre A complète : inscription (2.1), mot de passe oublié (2.4)…
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnexionException implements Exception {
  const ConnexionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// ChangeNotifier : prévient le routeur à chaque connexion / déconnexion.
abstract class AuthRepository extends ChangeNotifier {
  bool get estConnecte;
  String? get idUtilisateur;
  String? get email;

  Future<void> connecter({required String email, required String motDePasse});
  Future<void> deconnecter();
}

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._client) {
    _abonnement = _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _abonnement;

  @override
  bool get estConnecte => _client.auth.currentSession != null;
  @override
  String? get idUtilisateur => _client.auth.currentUser?.id;
  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Future<void> connecter({required String email, required String motDePasse}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: motDePasse);
    } on AuthException catch (e) {
      throw ConnexionException(e.code == 'invalid_credentials' ? 'Email ou mot de passe incorrect.' : e.message);
    } catch (_) {
      throw const ConnexionException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<void> deconnecter() => _client.auth.signOut();

  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}
