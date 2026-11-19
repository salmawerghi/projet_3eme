// =====================================================================
// DarImmo - [4.1] [4.2] CarteRepository : annonces publiées à placer sur la carte
// Tâche du membre B, réalisée par le membre C.
//
// Seule classe du module qui parle à Supabase (créée dans core/services.dart ;
// les tests utilisent un faux repository).
//   4.1 : toutes les annonces publiées qui ont une position (table annonces).
//   4.2 : fonction SQL PostGIS public.annonces_autour(lat, lng, rayon en m),
//         appelée en RPC (supabase/02_fonctions.sql). Elle renvoie des lignes
//         de la table annonces : PostgREST peut donc y joindre les photos.
// RLS : un visiteur (anon) ne lit que les annonces publiées.
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/map/data/models/annonce_carte.dart';

class CarteException implements Exception {
  const CarteException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class CarteRepository {
  /// Garde-fou : au-delà, la carte deviendrait illisible sans regroupement (4.3, bonus).
  static const maximum = 500;

  /// [4.1] Toutes les annonces publiées qui ont une position.
  Future<List<AnnonceCarte>> toutes();

  /// [4.2] Annonces publiées à moins de [rayonM] mètres de [centre], la plus proche d'abord.
  Future<List<AnnonceCarte>> autour(LatLng centre, int rayonM);
}

class SupabaseCarteRepository implements CarteRepository {
  SupabaseCarteRepository(this._client);
  final SupabaseClient _client;

  Future<List<AnnonceCarte>> _appel(Future<List<Map<String, dynamic>>> Function() requete) async {
    try {
      final lignes = await requete();
      return [for (final l in lignes) ?AnnonceCarte.depuisLigne(l)];
    } on PostgrestException catch (e) {
      debugPrint('[4.1] ${e.code} : ${e.message}');
      throw CarteException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[4.1] $e');
      throw const CarteException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<List<AnnonceCarte>> toutes() => _appel(() => _client
      .from('annonces')
      .select(AnnonceCarte.colonnes)
      .eq('statut', 'publiee') // un annonceur connecté verrait sinon ses brouillons
      .not('latitude', 'is', null)
      .order('date_creation', ascending: false)
      .limit(CarteRepository.maximum));

  @override
  Future<List<AnnonceCarte>> autour(LatLng centre, int rayonM) => _appel(() => _client
      .rpc<List<Map<String, dynamic>>>('annonces_autour', params: {
        'p_lat': centre.latitude,
        'p_lng': centre.longitude,
        'p_rayon_m': rayonM,
      })
      .select(AnnonceCarte.colonnes)
      .limit(CarteRepository.maximum));
}
