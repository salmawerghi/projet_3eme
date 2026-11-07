// =====================================================================
// DarImmo - [6.4] ViewModel de l'écran « Emplacement » (Provider)
// Membre C
//
// Trois façons de placer le bien : recherche d'adresse, position actuelle,
// ou marqueur déplacé à la main (glisser, ou toucher la carte).
// À l'ouverture d'une NOUVELLE annonce, la carte se centre sur l'adresse
// saisie à l'étape 1 (position « approximative » à affiner).
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'data/geocodage.dart';
import 'data/localisation.dart';

class PositionViewModel extends ChangeNotifier {
  PositionViewModel(this._geocodage, this._localisation, {LatLng? initiale, this.rechercheInitiale})
      : position = initiale,
        _initiale = initiale;

  final Geocodage _geocodage;
  final Localisation _localisation;
  final LatLng? _initiale;

  /// Adresse + ville de l'étape 1, pour centrer la carte d'une nouvelle annonce.
  final String? rechercheInitiale;

  /// Position choisie (null tant qu'aucune).
  LatLng? position;

  /// Vrai si la position vient de la recherche automatique : à vérifier.
  bool approximative = false;

  List<ResultatAdresse> resultats = const [];
  bool rechercheEnCours = false;
  bool localisationEnCours = false;
  String? erreur;

  /// Appelé quand la carte doit se déplacer (recherche, GPS) ; branché par l'écran.
  void Function(LatLng point)? onCentrer;

  bool get modifiee => position != _initiale;

  /// Centre la carte sur l'adresse de l'étape 1 si l'annonce n'a pas encore de position.
  Future<void> initialiser() async {
    final q = rechercheInitiale?.trim() ?? '';
    if (position != null || q.isEmpty) return;
    try {
      final r = await _geocodage.rechercher(q);
      if (r.isEmpty || position != null) return; // rien trouvé, ou l'utilisateur a déjà placé le marqueur
      position = r.first.position;
      approximative = true;
      notifyListeners();
      onCentrer?.call(position!);
    } on GeocodageException {
      // Silencieux : l'utilisateur peut chercher ou placer le marqueur lui-même.
    }
  }

  Future<void> rechercher(String texte) async {
    if (texte.trim().length < 3) {
      erreur = 'Tapez au moins 3 caractères.';
      notifyListeners();
      return;
    }
    rechercheEnCours = true;
    erreur = null;
    resultats = const [];
    notifyListeners();
    try {
      resultats = await _geocodage.rechercher(texte);
      if (resultats.isEmpty) erreur = 'Aucune adresse trouvée. Essayez avec le quartier ou la ville.';
    } on GeocodageException catch (e) {
      erreur = e.message;
    } finally {
      rechercheEnCours = false;
      notifyListeners();
    }
  }

  void choisirResultat(ResultatAdresse r) {
    resultats = const [];
    _placer(r.position, centrer: true);
  }

  void fermerResultats() {
    resultats = const [];
    notifyListeners();
  }

  Future<void> utiliserMaPosition() async {
    if (localisationEnCours) return;
    localisationEnCours = true;
    erreur = null;
    notifyListeners();
    try {
      final p = await _localisation.positionActuelle();
      _placer(p, centrer: true);
    } on LocalisationException catch (e) {
      erreur = e.message;
    } finally {
      localisationEnCours = false;
      notifyListeners();
    }
  }

  /// Marqueur déplacé à la main (glisser ou toucher la carte).
  void placer(LatLng p) => _placer(p, centrer: false);

  void _placer(LatLng p, {required bool centrer}) {
    position = LatLng(_arrondir(p.latitude), _arrondir(p.longitude));
    approximative = false;
    erreur = null;
    notifyListeners();
    if (centrer) onCentrer?.call(position!);
  }

  /// 6 décimales ≈ 10 cm : largement suffisant.
  static double _arrondir(double v) => (v * 1e6).roundToDouble() / 1e6;
}
