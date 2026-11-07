// Faux services de la 6.4 (sans réseau ni GPS), partagés par les tests.
import 'package:latlong2/latlong.dart';
import 'package:poc_temps_reel/features/position/data/geocodage.dart';
import 'package:poc_temps_reel/features/position/data/localisation.dart';

const ennasr = LatLng(36.8601, 10.1655);
const lac2 = LatLng(36.8421, 10.2752);
const telephone = LatLng(36.4513, 10.7357); // Hammamet

class FauxGeocodage implements Geocodage {
  FauxGeocodage([Map<String, List<ResultatAdresse>>? reponses])
      : reponses = reponses ??
            {
              'ennasr': [const ResultatAdresse(libelle: 'Ennasr 2, Ariana, Tunisie', position: ennasr)],
              'lac': [
                const ResultatAdresse(libelle: 'Rue du Lac Léman, Les Berges du Lac 2, Tunis', position: lac2),
                const ResultatAdresse(libelle: 'Lac 1, Tunis', position: LatLng(36.83, 10.23)),
              ],
            };

  final Map<String, List<ResultatAdresse>> reponses;
  final recherches = <String>[];
  String? erreur;

  /// Renvoie les résultats de la première clé contenue dans le texte (insensible à la casse).
  @override
  Future<List<ResultatAdresse>> rechercher(String texte) async {
    recherches.add(texte);
    if (erreur != null) throw GeocodageException(erreur!);
    final t = texte.toLowerCase();
    for (final e in reponses.entries) {
      if (t.contains(e.key)) return e.value;
    }
    return const [];
  }
}

class FausseLocalisation implements Localisation {
  FausseLocalisation({this.erreur});
  String? erreur;
  int appels = 0;

  @override
  Future<LatLng> positionActuelle() async {
    appels++;
    if (erreur != null) throw LocalisationException(erreur!);
    return telephone;
  }
}
