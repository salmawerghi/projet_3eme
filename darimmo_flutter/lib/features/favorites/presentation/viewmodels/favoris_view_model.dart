// =====================================================================
// DarImmo - [5.2] État de l'écran « Mes favoris » (maquette B6)
// Tâche du membre B, réalisée par le membre C.
//
// Suit EtatFavoris : un favori retiré (ici ou sur le détail) disparaît tout
// de suite de la liste ; un favori ajouté ailleurs fait relire la liste.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/favorites/data/repositories/favoris_repository.dart';
import 'package:darimmo/features/favorites/presentation/viewmodels/etat_favoris.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeOffre;
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';

class FavorisViewModel extends ChangeNotifier {
  FavorisViewModel({required this.repository, required this.etat}) {
    etat.addListener(_surChangementFavoris);
  }

  final FavorisRepository repository;
  final EtatFavoris etat;

  List<AnnonceRecherche> _annonces = const [];
  bool chargement = false;
  String? erreur;

  /// Puces Tous / Vente / Location (null = tous).
  TypeOffre? filtre;

  bool _ferme = false;
  int _requete = 0;

  /// Mes favoris encore cochés (un retrait est visible avant la réponse du serveur).
  List<AnnonceRecherche> get favoris => [for (final a in _annonces) if (etat.estFavori(a.id)) a];

  List<AnnonceRecherche> get affiches => [for (final a in favoris) if (filtre == null || a.typeOffre == filtre) a];

  int nombre(TypeOffre? offre) => favoris.where((a) => offre == null || a.typeOffre == offre).length;

  Future<void> charger() async {
    final numero = ++_requete;
    chargement = true;
    erreur = null;
    notifyListeners();
    try {
      final annonces = await repository.liste();
      if (_ferme || numero != _requete) return;
      _annonces = annonces;
    } on FavorisException catch (e) {
      if (_ferme || numero != _requete) return;
      erreur = e.message;
    }
    chargement = false;
    notifyListeners();
  }

  void choisirFiltre(TypeOffre? offre) {
    filtre = offre;
    notifyListeners();
  }

  void _surChangementFavoris() {
    if (_ferme) return;
    if (!etat.estConnecte) {
      _annonces = const [];
      notifyListeners();
      return;
    }
    // Favori ajouté depuis un autre écran : il manque à la liste -> relecture,
    // une fois l'ajout confirmé par le serveur (sinon la liste ne l'aurait pas encore).
    final connus = {for (final a in _annonces) a.id};
    final manquants = etat.ids
        .where((id) => !connus.contains(id) && !_dejaDemandes.contains(id) && !etat.enCours(id))
        .toSet();
    if (etat.charge && !chargement && manquants.isNotEmpty) {
      _dejaDemandes.addAll(manquants);
      charger();
    } else {
      notifyListeners();
    }
  }

  /// Ids qui ont déjà provoqué une relecture. Un favori vendu ou masqué n'est
  /// jamais renvoyé par le serveur (RLS) : sans cette liste, on relirait sans fin.
  final _dejaDemandes = <String>{};

  @override
  void dispose() {
    _ferme = true;
    etat.removeListener(_surChangementFavoris);
    super.dispose();
  }
}
