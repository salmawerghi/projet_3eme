// =====================================================================
// DarImmo - [5.1] [5.2] FavorisRepository : table public.favoris
// Tâches du membre B, réalisées par le membre C.
//
// Seule classe du module qui parle à Supabase (créée dans core/services.dart ;
// les tests utilisent un faux repository).
// RLS (03_rls.sql) : chacun ne lit, n'ajoute et ne retire que SES favoris.
// Les favoris sont en base : ils sont conservés après fermeture de
// l'application et retrouvés sur un autre téléphone (critère 5.1).
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/search/data/models/annonce_recherche.dart';

class FavorisException implements Exception {
  const FavorisException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class FavorisRepository {
  /// Identifiants des annonces que j'ai mises en favori (pour les cœurs).
  Future<Set<String>> ids();

  Future<void> ajouter(String idAnnonce);

  Future<void> retirer(String idAnnonce);

  /// [5.2] Mes favoris, le plus récent d'abord.
  Future<List<AnnonceRecherche>> liste();
}

class SupabaseFavorisRepository implements FavorisRepository {
  SupabaseFavorisRepository(this._client);
  final SupabaseClient _client;

  String get _moi {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const FavorisException('Connectez-vous pour gérer vos favoris.');
    return id;
  }

  Future<R> _appel<R>(Future<R> Function() requete) async {
    try {
      return await requete();
    } on FavorisException {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('[5.1] ${e.code} : ${e.message}');
      throw FavorisException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[5.1] $e');
      throw const FavorisException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<Set<String>> ids() => _appel(() async {
        final lignes = await _client.from('favoris').select('id_annonce');
        return {for (final l in lignes) l['id_annonce'] as String};
      });

  @override
  Future<void> ajouter(String idAnnonce) => _appel(() async {
        try {
          await _client.from('favoris').insert({'id_user': _moi, 'id_annonce': idAnnonce});
        } on PostgrestException catch (e) {
          if (e.code == '23505') return; // déjà en favori (autre téléphone) : c'est le résultat voulu
          rethrow;
        }
      });

  @override
  Future<void> retirer(String idAnnonce) => _appel(() async {
        await _client.from('favoris').delete().eq('id_user', _moi).eq('id_annonce', idAnnonce);
      });

  @override
  Future<List<AnnonceRecherche>> liste() => _appel(() async {
        final lignes = await _client
            .from('favoris')
            .select('date, annonce:annonces(${AnnonceRecherche.colonnes})')
            .order('date', ascending: false);
        // annonce = null : elle n'est plus visible (vendue, louée, masquée : RLS) -> pas affichée.
        return [
          for (final l in lignes)
            if (l['annonce'] case final Map<String, dynamic> a) AnnonceRecherche.depuisLigne(a),
        ];
      });
}
