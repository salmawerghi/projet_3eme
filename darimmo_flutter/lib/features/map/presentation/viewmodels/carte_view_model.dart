// =====================================================================
// DarImmo - [4.1] [4.2] État de l'écran Carte (maquette B3)
// Tâche du membre B, réalisée par le membre C.
//
// Deux modes :
//   toutes : toutes les annonces publiées qui ont une position (4.1) ;
//   autour : annonces dans un rayon choisi autour de ma position (4.2).
// La position n'est demandée QUE quand l'utilisateur touche « Autour de moi »
// (même règle que la 6.4). En cas de refus : message explicatif, on reste
// sur la carte de toutes les annonces.
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:darimmo/core/location/localisation.dart';
import 'package:darimmo/features/map/data/models/annonce_carte.dart';
import 'package:darimmo/features/map/data/repositories/carte_repository.dart';

enum ModeCarte { toutes, autour }

class CarteViewModel extends ChangeNotifier {
  CarteViewModel({required this.repository, required this.localisation});

  final CarteRepository repository;
  final Localisation localisation;

  /// Rayons proposés, en kilomètres.
  static const rayonsKm = [1, 2, 5, 10, 20];
  static const rayonParDefautKm = 5;

  List<AnnonceCarte> annonces = const [];
  bool chargement = false;
  String? erreur;

  ModeCarte mode = ModeCarte.toutes;
  LatLng? maPosition;
  int rayonKm = rayonParDefautKm;

  /// Recherche de la position en cours (bouton « Autour de moi »).
  bool localisationEnCours = false;

  /// Explication si la position est refusée ou introuvable (critère 4.2).
  String? messageLocalisation;

  String? _idSelection;

  /// Annonce dont l'aperçu est affiché (marqueur touché).
  AnnonceCarte? get selection {
    for (final a in annonces) {
      if (a.id == _idSelection) return a;
    }
    return null;
  }

  /// Numéro de la dernière requête : une réponse plus ancienne est ignorée
  /// (ex : rayon changé deux fois de suite).
  int _requete = 0;
  bool _ferme = false;

  /// [4.1] Toutes les annonces.
  Future<void> afficherToutes() {
    mode = ModeCarte.toutes;
    return _charger(repository.toutes);
  }

  /// [4.2] Demande la position (et l'autorisation si besoin), puis charge les
  /// annonces du rayon. Renvoie true si la carte doit se centrer sur ma position.
  Future<bool> activerAutourDeMoi() async {
    if (localisationEnCours) return false;
    localisationEnCours = true;
    messageLocalisation = null;
    notifyListeners();
    try {
      final position = await localisation.positionActuelle();
      if (_ferme) return false;
      maPosition = position;
    } on LocalisationException catch (e) {
      if (_ferme) return false;
      localisationEnCours = false;
      messageLocalisation = e.message;
      notifyListeners();
      return false;
    }
    localisationEnCours = false;
    mode = ModeCarte.autour;
    _idSelection = null;
    notifyListeners();
    await _chargerAutour();
    return true;
  }

  Future<void> changerRayon(int km) async {
    if (km == rayonKm) return;
    rayonKm = km;
    notifyListeners();
    if (mode == ModeCarte.autour) await _chargerAutour();
  }

  Future<void> _chargerAutour() {
    final centre = maPosition!;
    final rayonM = rayonKm * 1000;
    return _charger(() => repository.autour(centre, rayonM));
  }

  Future<void> reessayer() => mode == ModeCarte.autour ? _chargerAutour() : afficherToutes();

  void fermerMessageLocalisation() {
    messageLocalisation = null;
    notifyListeners();
  }

  void selectionner(String? id) {
    if (id == _idSelection) return;
    _idSelection = id;
    notifyListeners();
  }

  Future<void> _charger(Future<List<AnnonceCarte>> Function() requete) async {
    final numero = ++_requete;
    chargement = true;
    erreur = null;
    notifyListeners();
    try {
      final resultat = await requete();
      if (_ferme || numero != _requete) return;
      annonces = resultat;
      if (selection == null) _idSelection = null; // l'annonce choisie n'est plus dans le rayon
    } on CarteException catch (e) {
      if (_ferme || numero != _requete) return;
      erreur = e.message;
    }
    chargement = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ferme = true;
    super.dispose();
  }
}
