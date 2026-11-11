// =====================================================================
// DarImmo - AuthRepository (squelette 1.6 ; stories 2.1 / 2.2 du membre A)
//
// État de connexion de l'application. Le routeur (core/router) l'écoute
// pour envoyer vers l'écran de connexion quand il n'y a pas de session.
//
// [2.1] S'inscrire : signUp avec le nom (et le téléphone) dans les
// métadonnées ; le trigger public.creer_profil() crée la ligne profiles.
// Le projet Supabase exige la confirmation de l'email : après l'inscription
// il n'y a pas encore de session, l'utilisateur doit cliquer sur le lien.
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

/// Champ du formulaire d'inscription concerné par une erreur.
enum ChampInscription { email, motDePasse, general }

class InscriptionException implements Exception {
  const InscriptionException(this.message, {this.champ = ChampInscription.general});
  final String message;
  final ChampInscription champ;
  @override
  String toString() => message;
}

enum ResultatInscription {
  /// Session ouverte tout de suite (confirmation d'email désactivée).
  connecte,

  /// Compte créé : il faut cliquer sur le lien reçu par email.
  confirmationEmail,
}

/// Adresse ouverte par le lien de confirmation : elle rouvre l'app
/// (intent-filter dans AndroidManifest.xml) et supabase_flutter ouvre la
/// session tout seul. Doit être autorisée dans Supabase > Authentication >
/// URL Configuration > Redirect URLs, sinon Supabase renvoie vers le Site URL.
const lienRetourConfirmation = 'com.darimmo://connexion';

const messageEmailDejaUtilise ='Cet email est déjà utilisé. Connectez-vous ou choisissez une autre adresse.';

/// ChangeNotifier : prévient le routeur à chaque connexion / déconnexion.
abstract class AuthRepository extends ChangeNotifier {
  bool get estConnecte;
  String? get idUtilisateur;
  String? get email;

  Future<void> connecter({required String email, required String motDePasse});
  Future<void> deconnecter();

  /// [2.1] Crée le compte (et le profil, par trigger).
  /// Lève [InscriptionException] si l'email est déjà utilisé, etc.
  Future<ResultatInscription> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
  });

  /// Renvoie l'email de confirmation de l'inscription.
  Future<void> renvoyerConfirmation(String email);
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
      throw ConnexionException(switch (e.code) {
        'invalid_credentials' => 'Email ou mot de passe incorrect.',
        'email_not_confirmed' => 'Adresse email pas encore confirmée : ouvrez le lien reçu par email, puis réessayez.',
        _ => e.message,
      });
    } catch (_) {
      throw const ConnexionException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<void> deconnecter() => _client.auth.signOut();

  @override
  Future<ResultatInscription> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
  }) async {
    final AuthResponse reponse;
    try {
      reponse = await _client.auth.signUp(
        email: email.trim(),
        password: motDePasse,
        emailRedirectTo: kIsWeb ? null : lienRetourConfirmation,
        data: {'nom': nom.trim(), 'telephone': ?telephone},
      );
    } on AuthException catch (e) {
      throw _erreurInscription(e);
    } catch (_) {
      throw const InscriptionException('Inscription impossible. Vérifiez Internet et réessayez.');
    }
    // Email déjà inscrit : par sécurité Supabase ne renvoie pas d'erreur
    // mais un faux compte sans identité (rien n'est créé en base).
    final identites = reponse.user?.identities;
    if (reponse.user == null || (identites != null && identites.isEmpty)) {
      throw const InscriptionException(messageEmailDejaUtilise, champ: ChampInscription.email);
    }
    return reponse.session != null ? ResultatInscription.connecte : ResultatInscription.confirmationEmail;
  }

  @override
  Future<void> renvoyerConfirmation(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: kIsWeb ? null : lienRetourConfirmation,
      );
    } on AuthException catch (e) {
      throw _erreurInscription(e);
    } catch (_) {
      throw const InscriptionException('Envoi impossible. Vérifiez Internet et réessayez.');
    }
  }

  static InscriptionException _erreurInscription(AuthException e) => switch (e.code) {
        'user_already_exists' || 'email_exists' =>
          const InscriptionException(messageEmailDejaUtilise, champ: ChampInscription.email),
        'email_address_invalid' =>
          const InscriptionException('Adresse email refusée. Vérifiez-la.', champ: ChampInscription.email),
        'weak_password' => const InscriptionException(
            'Mot de passe trop faible : mélangez lettres, chiffres et symboles.',
            champ: ChampInscription.motDePasse),
        'over_email_send_rate_limit' || 'over_request_rate_limit' =>
          const InscriptionException('Trop de tentatives. Réessayez dans quelques minutes.'),
        'email_address_not_authorized' => const InscriptionException(
            'Le serveur ne peut pas encore envoyer d’email à cette adresse (envoi d’emails non configuré).'),
        'signup_disabled' => const InscriptionException('Les inscriptions sont fermées pour le moment.'),
        _ => InscriptionException(e.message),
      };

  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}
