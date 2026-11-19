// =====================================================================
// DarImmo - [3.4] SignalementRepository : signaler une annonce
// Tâche du membre B, réalisée par le membre C.
//
// Table public.signalements (01_schema.sql) :
//   - contrainte signalement_unique (id_user, id_annonce) : un seul
//     signalement par utilisateur et par annonce (critère 3.4) ;
//   - RLS : un utilisateur connecté signale en son nom ; il ne relit que
//     ses propres signalements (l'admin les lit tous, 9.4).
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignalementException implements Exception {
  const SignalementException(this.message, {this.dejaSignale = false});
  final String message;
  final bool dejaSignale;

  static const messageDejaSignale = 'Vous avez déjà signalé cette annonce.';

  @override
  String toString() => message;
}

abstract class SignalementRepository {
  /// true si j'ai déjà signalé cette annonce.
  Future<bool> dejaSignale(String idAnnonce);

  /// [motif] : « Catégorie — précision » (3 à 500 caractères).
  Future<void> signaler(String idAnnonce, String motif);
}

class SupabaseSignalementRepository implements SignalementRepository {
  SupabaseSignalementRepository(this._client);
  final SupabaseClient _client;

  String get _moi {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const SignalementException('Connectez-vous pour signaler une annonce.');
    return id;
  }

  @override
  Future<bool> dejaSignale(String idAnnonce) async {
    final moi = _client.auth.currentUser?.id;
    if (moi == null) return false;
    try {
      final ligne = await _client
          .from('signalements')
          .select('id')
          .eq('id_annonce', idAnnonce)
          .eq('id_user', moi)
          .maybeSingle();
      return ligne != null;
    } catch (e) {
      debugPrint('[3.4] $e');
      return false; // au pire, la base refusera le doublon à l'envoi
    }
  }

  @override
  Future<void> signaler(String idAnnonce, String motif) async {
    try {
      await _client.from('signalements').insert({'id_annonce': idAnnonce, 'id_user': _moi, 'motif': motif});
    } on SignalementException {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('[3.4] ${e.code} : ${e.message}');
      if (e.code == '23505') {
        throw const SignalementException(SignalementException.messageDejaSignale, dejaSignale: true);
      }
      throw SignalementException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[3.4] $e');
      throw const SignalementException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }
}
