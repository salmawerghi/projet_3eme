// =====================================================================
// DarImmo - [6.4] Recherche d'adresse (géocodage) avec Nominatim (OSM)
// Membre C
//
// Service gratuit d'OpenStreetMap. Règles d'usage respectées :
//   - 1 requête à la fois, seulement quand l'utilisateur valide sa recherche
//     (pas à chaque lettre tapée) ;
//   - application identifiée (User-Agent ; le navigateur envoie le sien sur le web).
// Résultats limités à la Tunisie, en français.
// =====================================================================
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResultatAdresse {
  const ResultatAdresse({required this.libelle, required this.position});
  final String libelle;
  final LatLng position;
}

class GeocodageException implements Exception {
  const GeocodageException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class Geocodage {
  /// Adresses correspondant au [texte] (5 au plus, la plus pertinente d'abord).
  Future<List<ResultatAdresse>> rechercher(String texte);
}

class NominatimGeocodage implements Geocodage {
  NominatimGeocodage([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<List<ResultatAdresse>> rechercher(String texte) async {
    final q = texte.trim();
    if (q.length < 3) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'limit': '5',
      'countrycodes': 'tn',
      'accept-language': 'fr',
    });
    try {
      final reponse = await _client
          .get(uri, headers: {if (!kIsWeb) 'User-Agent': 'DarImmo-PoC/1.0 (projet etudiant, app Flutter)'})
          .timeout(const Duration(seconds: 10));
      if (reponse.statusCode == 429) {
        throw const GeocodageException('Trop de recherches : patientez quelques secondes.');
      }
      if (reponse.statusCode != 200) {
        throw GeocodageException('Recherche d’adresse indisponible (${reponse.statusCode}).');
      }
      return lireReponse(reponse.body);
    } on GeocodageException {
      rethrow;
    } catch (e) {
      debugPrint('[6.4] Nominatim : $e');
      throw const GeocodageException('Recherche impossible. Vérifiez votre connexion.');
    }
  }

  /// Lit la réponse JSON de Nominatim (lat / lon sont des chaînes).
  static List<ResultatAdresse> lireReponse(String json) => [
        for (final r in jsonDecode(json) as List)
          ResultatAdresse(
            libelle: r['display_name'] as String,
            position: LatLng(double.parse(r['lat'] as String), double.parse(r['lon'] as String)),
          ),
      ];
}
