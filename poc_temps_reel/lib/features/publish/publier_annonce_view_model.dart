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
  PublierAnnonceViewModel(this._repository);
  final AnnonceRepository _repository;

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

  /// Envoie l'annonce. Renvoie l'annonce créée, ou null en cas d'erreur
  /// (le message est alors dans [erreur]).
  Future<Annonce?> envoyer(NouvelleAnnonce annonce) async {
    if (envoiEnCours) return null; // évite le double envoi (double appui)
    envoiEnCours = true;
    erreur = null;
    notifyListeners();
    try {
      return await _repository.publier(annonce);
    } on PublicationException catch (e) {
      erreur = e.message;
      return null;
    } finally {
      envoiEnCours = false;
      notifyListeners();
    }
  }
}
