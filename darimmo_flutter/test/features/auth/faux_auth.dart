// Faux AuthRepository (en mémoire) pour les tests : aucun accès réseau.
import 'dart:async';

import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';

class FauxAuth extends AuthRepository {
  FauxAuth({this.connecte = false, this.confirmationEmail = true, Set<String>? emailsExistants})
      : emailsExistants = emailsExistants ?? {'vendeur@darimmo.test', 'acheteur@darimmo.test'};

  bool connecte;
  int connexions = 0;

  /// true = comme le vrai projet Supabase (lien à cliquer, pas de session).
  bool confirmationEmail;
  final Set<String> emailsExistants;

  /// Dernière inscription reçue (pour vérifier ce qui est envoyé).
  Map<String, String?>? derniereInscription;
  int renvois = 0;

  /// Erreur à lever à la prochaine inscription (ex : pas d'Internet).
  InscriptionException? erreurInscription;

  /// Si non nul, l'inscription attend ce Completer (pour tester « en cours »).
  Completer<void>? attente;

  @override
  bool get estConnecte => connecte;
  @override
  String? get idUtilisateur => connecte ? 'u1' : null;
  @override
  String? get email => connecte ? 'vendeur@darimmo.test' : null;

  @override
  Future<void> connecter({required String email, required String motDePasse}) async {
    if (motDePasse != 'Test1234!') throw const ConnexionException('Email ou mot de passe incorrect.');
    connexions++;
    connecte = true;
    notifyListeners();
  }

  @override
  Future<void> deconnecter() async {
    connecte = false;
    notifyListeners();
  }

  @override
  Future<ResultatInscription> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
  }) async {
    derniereInscription = {'nom': nom, 'email': email, 'motDePasse': motDePasse, 'telephone': telephone};
    await attente?.future;
    final erreur = erreurInscription;
    if (erreur != null) {
      erreurInscription = null;
      throw erreur;
    }
    final adresse = email.trim().toLowerCase();
    if (emailsExistants.contains(adresse)) {
      throw const InscriptionException(messageEmailDejaUtilise, champ: ChampInscription.email);
    }
    emailsExistants.add(adresse);
    if (confirmationEmail) return ResultatInscription.confirmationEmail;
    connecte = true;
    notifyListeners();
    return ResultatInscription.connecte;
  }

  @override
  Future<void> renvoyerConfirmation(String email) async => renvois++;
}
