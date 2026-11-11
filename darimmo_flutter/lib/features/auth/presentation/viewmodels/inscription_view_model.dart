// =====================================================================
// DarImmo - [2.1] ViewModel de l'écran « Créer un compte » (Provider)
// Membre A
//
// Garde l'état qui n'est pas dans les champs texte : envoi en cours,
// conditions acceptées, erreurs renvoyées par le serveur, et l'email à
// confirmer une fois le compte créé.
// Les champs texte restent dans le Form de l'écran (TextEditingController).
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/validators_auth.dart';

class InscriptionViewModel extends ChangeNotifier {
  InscriptionViewModel(this._auth);
  final AuthRepository _auth;

  bool envoiEnCours = false;
  bool cguAcceptees = false;
  bool cguManquantes = false; // affiché après un essai sans cocher
  bool motDePasseVisible = false;

  /// Erreurs du serveur, affichées sous le champ concerné.
  String? erreurEmail;
  String? erreurMotDePasse;
  String? erreurGenerale;

  /// Rempli quand le compte est créé et attend la confirmation par email.
  String? emailAConfirmer;
  bool renvoiEnCours = false;
  String? infoRenvoi;

  void basculerCgu(bool? valeur) {
    cguAcceptees = valeur ?? false;
    if (cguAcceptees) cguManquantes = false;
    notifyListeners();
  }

  void basculerVisibilite() {
    motDePasseVisible = !motDePasseVisible;
    notifyListeners();
  }

  /// L'utilisateur retape l'email : l'erreur « déjà utilisé » n'est plus valable.
  void emailModifie() {
    if (erreurEmail == null) return;
    erreurEmail = null;
    notifyListeners();
  }

  void motDePasseModifie() {
    if (erreurMotDePasse == null) return;
    erreurMotDePasse = null;
    notifyListeners();
  }

  /// [formulaireValide] = résultat de Form.validate() (champs texte).
  /// Renvoie le résultat, ou null si rien n'a été créé.
  Future<ResultatInscription?> inscrire({
    required bool formulaireValide,
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
  }) async {
    if (envoiEnCours) return null;
    cguManquantes = !cguAcceptees;
    erreurGenerale = null;
    if (!formulaireValide || cguManquantes) {
      notifyListeners();
      return null;
    }
    envoiEnCours = true;
    erreurEmail = null;
    erreurMotDePasse = null;
    notifyListeners();
    try {
      final resultat = await _auth.inscrire(
        nom: nom,
        email: email,
        motDePasse: motDePasse,
        telephone: normaliserTelephone(telephone),
      );
      if (resultat == ResultatInscription.confirmationEmail) emailAConfirmer = email.trim();
      return resultat;
    } on InscriptionException catch (e) {
      switch (e.champ) {
        case ChampInscription.email:
          erreurEmail = e.message;
        case ChampInscription.motDePasse:
          erreurMotDePasse = e.message;
        case ChampInscription.general:
          erreurGenerale = e.message;
      }
      return null;
    } finally {
      envoiEnCours = false;
      notifyListeners();
    }
  }

  Future<void> renvoyerEmail() async {
    final email = emailAConfirmer;
    if (email == null || renvoiEnCours) return;
    renvoiEnCours = true;
    infoRenvoi = null;
    notifyListeners();
    try {
      await _auth.renvoyerConfirmation(email);
      infoRenvoi = 'Email renvoyé. Pensez à regarder dans les spams.';
    } on InscriptionException catch (e) {
      infoRenvoi = e.message;
    } finally {
      renvoiEnCours = false;
      notifyListeners();
    }
  }
}
