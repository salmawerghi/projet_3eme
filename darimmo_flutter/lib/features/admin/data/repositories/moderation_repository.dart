// =====================================================================
// DarImmo - [9.2] ModerationRepository : valider ou rejeter une annonce
// Tâche du membre A, réalisée par le membre C.
//
// Sécurité dans la base (déjà en place) :
//   - RLS : seul un admin peut modifier l'annonce d'un autre ;
//   - trigger annonces_statut : motif obligatoire pour « rejetee », motif
//     effacé à la publication ;
//   - webhook -> Edge Function send-push : l'annonceur est notifié (8.2).
// On ne change que des annonces encore « en_attente » : si un autre admin
// les a déjà traitées, rien n'est écrasé et on le signale.
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';

class ModerationException implements Exception {
  const ModerationException(this.message, {this.dejaTraitee = false});
  final String message;

  /// L'annonce n'est plus en attente (traitée ailleurs, ou modifiée).
  final bool dejaTraitee;

  static const messageDejaTraitee = 'Cette annonce a déjà été traitée. La liste est mise à jour.';

  @override
  String toString() => message;
}

abstract class ModerationRepository {
  /// [9.2] Annonces en attente, la plus ancienne d'abord.
  Future<List<AnnonceAModerer>> enAttente();

  Future<void> valider(String idAnnonce);

  Future<void> rejeter(String idAnnonce, String motif);
}

class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this._client);
  final SupabaseClient _client;

  Future<R> _appel<R>(Future<R> Function() requete) async {
    try {
      return await requete();
    } on ModerationException {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('[9.2] ${e.code} : ${e.message}');
      if (e.code == 'P0001') throw ModerationException(e.message); // message du trigger (motif…)
      throw ModerationException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[9.2] $e');
      throw const ModerationException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<List<AnnonceAModerer>> enAttente() => _appel(() async {
        final lignes = await _client
            .from('annonces')
            .select(AnnonceAModerer.colonnes)
            .eq('statut', 'en_attente')
            .order('date_maj', ascending: true)
            .limit(200);
        return [for (final l in lignes) AnnonceAModerer.depuisLigne(l)];
      });

  Future<void> _changerStatut(String idAnnonce, Map<String, dynamic> valeurs) => _appel(() async {
        final modifiees = await _client
            .from('annonces')
            .update(valeurs)
            .eq('id', idAnnonce)
            .eq('statut', 'en_attente')
            .select('id');
        // 0 ligne : déjà traitée, supprimée, ou compte non admin (RLS)
        if (modifiees.isEmpty) {
          throw const ModerationException(ModerationException.messageDejaTraitee, dejaTraitee: true);
        }
      });

  @override
  Future<void> valider(String idAnnonce) => _changerStatut(idAnnonce, {'statut': 'publiee'});

  @override
  Future<void> rejeter(String idAnnonce, String motif) =>
      _changerStatut(idAnnonce, {'statut': 'rejetee', 'motif_rejet': motif.trim()});
}
