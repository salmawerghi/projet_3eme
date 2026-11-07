// =====================================================================
// DarImmo - [6.3] [6.5] ViewModel de l'écran « Mes annonces » (Provider)
// Membre C
//
// Charge les annonces, gère le filtre par statut (puces en haut de l'écran)
// et calcule les compteurs (« 5 annonces · 2 en ligne »).
// =====================================================================
import 'package:flutter/foundation.dart';

import '../publish/models/annonce.dart';
import 'data/mes_annonces_repository.dart';
import 'models/mon_annonce.dart';

/// Puces de filtre de la maquette C5.
enum FiltreAnnonces {
  toutes('Toutes', {}),
  publiees('Publiées', {StatutAnnonce.publiee}),
  enAttente('En attente', {StatutAnnonce.enAttente}),
  rejetees('Rejetées', {StatutAnnonce.rejetee}),
  vendues('Vendues / louées', {StatutAnnonce.vendue, StatutAnnonce.louee}),
  masquees('Masquées', {StatutAnnonce.masquee}),
  brouillons('Brouillons', {StatutAnnonce.brouillon});

  const FiltreAnnonces(this.libelle, this.statuts);
  final String libelle;
  final Set<StatutAnnonce> statuts; // vide = toutes

  bool accepte(MonAnnonce a) => statuts.isEmpty || statuts.contains(a.statut);
}

class MesAnnoncesViewModel extends ChangeNotifier {
  MesAnnoncesViewModel(this._repository);
  final MesAnnoncesRepository _repository;

  List<MonAnnonce> _annonces = const [];
  bool chargement = false;
  String? erreur;
  FiltreAnnonces filtre = FiltreAnnonces.toutes;

  /// Vrai tant que le premier chargement n'a pas réussi.
  bool get jamaisCharge => _annonces.isEmpty && (chargement || erreur != null);

  List<MonAnnonce> get annonces => _annonces.where(filtre.accepte).toList();
  int get total => _annonces.length;
  int get enLigne => compter(FiltreAnnonces.publiees);
  int compter(FiltreAnnonces f) => _annonces.where(f.accepte).length;

  /// Puces à afficher : « Toutes » + les statuts présents.
  List<FiltreAnnonces> get filtresVisibles =>
      FiltreAnnonces.values.where((f) => f == FiltreAnnonces.toutes || compter(f) > 0).toList();

  /// « 5 annonces · 2 en ligne »
  String get resume {
    if (total == 0) return 'Aucune annonce';
    final a = total == 1 ? '1 annonce' : '$total annonces';
    return '$a · $enLigne en ligne';
  }

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();
    try {
      _annonces = await _repository.lister();
      // Le filtre choisi peut ne plus avoir d'annonce (ex : après suppression).
      if (compter(filtre) == 0) filtre = FiltreAnnonces.toutes;
    } on MesAnnoncesException catch (e) {
      erreur = e.message;
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  void choisirFiltre(FiltreAnnonces f) {
    filtre = f;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // [6.3] Actions sur une annonce (étape 2)
  // ------------------------------------------------------------------

  /// Annonces dont une action est en cours (boutons désactivés, évite le double appui).
  final Set<String> _enCours = {};
  bool estEnCours(MonAnnonce a) => _enCours.contains(a.id);

  /// Marque l'annonce vendue / louée. Renvoie null si tout va bien,
  /// sinon le message d'erreur à afficher.
  Future<String?> marquerConclue(MonAnnonce a) => _agir(a, () => _repository.marquerConclue(a));

  /// Supprime l'annonce (et ses photos). Même convention de retour.
  Future<String?> supprimer(MonAnnonce a) => _agir(a, () => _repository.supprimer(a));

  Future<String?> _agir(MonAnnonce a, Future<void> Function() action) async {
    if (!_enCours.add(a.id)) return null; // déjà en cours
    notifyListeners();
    try {
      await action();
      await charger(); // relit la liste : statut à jour, compteurs et filtres recalculés
      return null;
    } on MesAnnoncesException catch (e) {
      return e.message;
    } finally {
      _enCours.remove(a.id);
      notifyListeners();
    }
  }
}
