// =====================================================================
// DarImmo - [6.1] ViewModel de l'écran « Publier une annonce » (Provider)
// Membre C
//
// Garde l'état qui n'est pas dans les champs texte : offre, type de bien,
// nombre de pièces, envoi en cours, message d'erreur.
// Les champs texte restent dans le Form de l'écran (TextEditingController).
// =====================================================================
import 'package:flutter/foundation.dart';

import 'data/annonce_repository.dart';
import 'models/annonce.dart';

class PublierAnnonceViewModel extends ChangeNotifier {
  /// [edition] non nul = modification d'une annonce existante (6.3) :
  /// les choix sont pré-remplis avec ses valeurs.
  PublierAnnonceViewModel(this._repository, {this.edition}) : creation = edition == null {
    final v = edition?.valeurs;
    if (v != null) {
      typeOffre = v.typeOffre;
      typeBien = v.typeBien;
      if (v.nbPieces >= 1) nbPieces = v.nbPieces; // un terrain a 0 pièce : on garde 3 par défaut
    }
  }
  final AnnonceRepository _repository;

  /// Vrai si l'écran a été ouvert pour une NOUVELLE annonce (6.1).
  final bool creation;

  /// Annonce en cours d'édition. Pour une création, elle est remplie après
  /// l'étape 1 (brouillon créé) : revenir au formulaire puis « Continuer »
  /// met à jour ce brouillon au lieu d'en créer un second.
  EditionAnnonce? edition;

  /// Dernier état de l'annonce renvoyé par la base.
  Annonce? enregistree;

  bool get modification => !creation;

  TypeOffre typeOffre = TypeOffre.vente;
  TypeBien? typeBien; // null tant que l'utilisateur n'a pas choisi
  int nbPieces = 3;
  bool envoiEnCours = false;
  String? erreur;

  /// Affiche « Choisissez un type de bien » après un premier essai d'envoi.
  bool typeBienManquant = false;

  void choisirOffre(TypeOffre offre) {
    typeOffre = offre;
    notifyListeners();
  }

  void choisirType(TypeBien type) {
    typeBien = type;
    typeBienManquant = false;
    notifyListeners();
  }

  void changerPieces(int delta) {
    nbPieces = (nbPieces + delta).clamp(1, 50);
    notifyListeners();
  }

  /// Vérifie ce que le Form ne vérifie pas (le type de bien).
  bool verifierChoix() {
    typeBienManquant = typeBien == null;
    notifyListeners();
    return !typeBienManquant;
  }

  /// Étape 1 : enregistre les informations (brouillon créé, ou annonce mise à jour).
  /// Renvoie l'annonce, ou null en cas d'erreur (le message est dans [erreur]).
  Future<Annonce?> envoyer(NouvelleAnnonce annonce) async {
    if (envoiEnCours) return null; // évite le double envoi (double appui)
    envoiEnCours = true;
    erreur = null;
    notifyListeners();
    try {
      final e = edition;
      final a = e == null ? await _repository.creerBrouillon(annonce) : await _repository.modifier(e, annonce);
      enregistree = a;
      edition = EditionAnnonce(id: a.id, statut: a.statut, valeurs: annonce);
      return a;
    } on PublicationException catch (e) {
      erreur = e.message;
      return null;
    } finally {
      envoiEnCours = false;
      notifyListeners();
    }
  }

  /// Bouton final de l'étape 2 : « Envoyer / Renvoyer pour validation »
  /// (brouillon ou rejetée) ou « Terminer » (rien à changer).
  String get libelleValidation {
    if (!(edition?.renvoyerEnValidation ?? true)) return 'Terminer';
    return creation || edition?.statut == StatutAnnonce.brouillon ? 'Envoyer pour validation' : 'Renvoyer pour validation';
  }

  /// Fin du parcours (étape 2). Renvoie null si tout va bien, sinon le message d'erreur.
  Future<String?> valider() async {
    final e = edition;
    if (e == null) return 'Enregistrez d’abord les informations de l’annonce.';
    if (!e.renvoyerEnValidation) return null;
    try {
      final a = await _repository.envoyerEnValidation(e.id);
      enregistree = a;
      edition = e.copie(statut: a.statut);
      return null;
    } on PublicationException catch (x) {
      return x.message;
    }
  }
}
