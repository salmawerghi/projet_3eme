// =====================================================================
// DarImmo - [3.1] [3.2] ViewModel de l'accueil (Provider)
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Chargement progressif : 10 annonces par page, la suite est demandée
// quand on approche du bas de la liste.
// Changer de filtre pendant un chargement : la réponse de l'ancien filtre
// est IGNORÉE (numéro de génération), elle ne se mélange pas à la nouvelle liste.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/data/models/filtre_recherche.dart';
import 'package:darimmo/features/search/data/repositories/recherche_repository.dart';

class AccueilViewModel extends ChangeNotifier {
  AccueilViewModel(this._repository);
  final RechercheRepository _repository;

  final List<AnnonceRecherche> _annonces = [];
  List<AnnonceRecherche> get annonces => List.unmodifiable(_annonces);

  FiltreRecherche filtre = FiltreRecherche.vide;

  /// Une page est en cours de chargement (la première ou la suivante).
  bool chargement = false;

  /// Il reste des annonces à charger.
  bool aEncore = true;

  /// Erreur de la première page (écran d'erreur) …
  String? erreur;

  /// … ou de la page suivante (bandeau « Réessayer » en bas de la liste).
  String? erreurSuite;

  int _page = 0;
  int _generation = 0;
  bool _detruit = false;

  bool get premierChargement => _annonces.isEmpty && chargement;

  Future<void> demarrer() => recharger();

  /// Repart de la première page (nouveau filtre, « tirer pour rafraîchir »).
  Future<void> recharger() {
    _generation++;
    _annonces.clear();
    _page = 0;
    aEncore = true;
    erreur = null;
    erreurSuite = null;
    chargement = false;
    return _chargerPage();
  }

  /// Page suivante (appelée en approchant du bas de la liste).
  Future<void> chargerSuite() async {
    if (chargement || !aEncore || erreur != null || erreurSuite != null) return;
    await _chargerPage();
  }

  /// Bouton « Réessayer » sous la liste.
  Future<void> reessayerSuite() {
    erreurSuite = null;
    return _chargerPage();
  }

  Future<void> _chargerPage() async {
    final generation = _generation;
    chargement = true;
    _notifier();
    try {
      final lot = await _repository.page(filtre, _page);
      if (generation != _generation) return; // le filtre a changé entre-temps
      _annonces.addAll(lot);
      aEncore = lot.length == RechercheRepository.taillePage;
      _page++;
    } on RechercheException catch (e) {
      if (generation != _generation) return;
      if (_annonces.isEmpty) {
        erreur = e.message;
      } else {
        erreurSuite = e.message;
      }
    } finally {
      if (generation == _generation) {
        chargement = false;
        _notifier();
      }
    }
  }

  /// Nouveaux filtres (feuille de filtres, barre de recherche, puces).
  Future<void> appliquer(FiltreRecherche nouveau) {
    if (nouveau == filtre && erreur == null) return Future.value();
    filtre = nouveau;
    return recharger();
  }

  Future<void> chercher(String texte) => appliquer(filtre.copie(texte: () => texte));

  // ----- Puces rapides (maquette B1) : toucher une puce active la désactive.
  Future<void> toutAfficher() => appliquer(FiltreRecherche.vide);

  Future<void> basculerOffre(TypeOffre o) =>
      appliquer(filtre.copie(typeOffre: () => filtre.typeOffre == o ? null : o, prixMin: () => null, prixMax: () => null));

  Future<void> basculerType(TypeBien t) => appliquer(filtre.copie(
        typeBien: () => filtre.typeBien == t ? null : t,
        sPlusMin: () => t == TypeBien.terrain ? null : filtre.sPlusMin,
      ));

  // ----- Pour la feuille de filtres
  Future<int> compter(FiltreRecherche f) => _repository.compter(f);

  List<String>? _villes;
  Future<List<String>> villes() async {
    try {
      return _villes ??= await _repository.villes();
    } on RechercheException {
      return const []; // les suggestions sont un plus : on peut toujours taper la ville
    }
  }

  void _notifier() {
    if (!_detruit) notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
