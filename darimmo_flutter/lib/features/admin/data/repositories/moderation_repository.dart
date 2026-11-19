// =====================================================================
// DarImmo - [9.2] [9.3] [9.4] ModerationRepository : valider ou rejeter
// une annonce ; bloquer un compte ; traiter les signalements.
// Tâches du membre A, réalisées par le membre C.
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
import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/admin/data/models/compte_admin.dart';

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

  /// [9.4] Signalements en attente, regroupés par annonce.
  Future<List<AnnonceSignalee>> signalements();

  /// [9.4] Masque l'annonce (statut masquee : plus visible, annonceur notifié
  /// par send-push) puis marque ses signalements « traite ».
  Future<void> masquer(String idAnnonce, List<int> idsSignalements);

  /// [9.4] Classe les signalements sans suite (statut classe) ; l'annonce reste en ligne.
  Future<void> classer(List<int> idsSignalements);

  /// [9.3] Comptes dont le nom ou l'email contient [recherche] ;
  /// sans recherche : les comptes bloqués.
  Future<List<CompteAdmin>> comptes(String? recherche);

  /// [9.3] Bloque ou débloque un compte (profiles.bloque). La base empêche
  /// alors le compte de publier et d'écrire (RLS est_bloque()) ; l'appli le
  /// déconnecte à sa prochaine connexion ou ouverture.
  Future<void> bloquer(String idCompte, {required bool bloque});
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

  @override
  Future<List<AnnonceSignalee>> signalements() => _appel(() async {
        final lignes = await _client
            .from('signalements')
            .select(AnnonceSignalee.colonnes)
            .eq('statut', 'en_attente')
            .order('date', ascending: true)
            .limit(500);
        return AnnonceSignalee.regrouper(lignes);
      });

  Future<void> _statutSignalements(List<int> ids, String statut) => _appel(() async {
        await _client.from('signalements').update({'statut': statut}).inFilter('id', ids);
      });

  @override
  Future<void> masquer(String idAnnonce, List<int> idsSignalements) async {
    await _appel(() async {
      final modifiees = await _client
          .from('annonces')
          .update({'statut': 'masquee'})
          .eq('id', idAnnonce)
          .select('id');
      if (modifiees.isEmpty) throw const ModerationException('Annonce introuvable : elle a peut-être été supprimée.');
    });
    await _statutSignalements(idsSignalements, 'traite');
  }

  @override
  Future<void> classer(List<int> idsSignalements) => _statutSignalements(idsSignalements, 'classe');

  @override
  Future<List<CompteAdmin>> comptes(String? recherche) => _appel(() async {
        var requete = _client.from('profiles').select(CompteAdmin.colonnes);
        // Retire les caractères qui ont un sens dans la syntaxe « or » de PostgREST.
        final texte = (recherche ?? '').replaceAll(RegExp(r'[,()"*%_\\:]'), ' ').trim();
        requete = texte.isEmpty ? requete.eq('bloque', true) : requete.or('nom.ilike.*$texte*,email.ilike.*$texte*');
        final lignes = await requete.order('nom').limit(30);
        return [for (final l in lignes) CompteAdmin.depuisLigne(l)];
      });

  @override
  Future<void> bloquer(String idCompte, {required bool bloque}) => _appel(() async {
        final modifies = await _client.from('profiles').update({'bloque': bloque}).eq('id', idCompte).select('id');
        if (modifies.isEmpty) throw const ModerationException('Compte introuvable.');
      });
}
