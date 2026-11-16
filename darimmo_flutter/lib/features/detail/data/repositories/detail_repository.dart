// =====================================================================
// DarImmo - [3.3] DetailRepository : charge une annonce par son id
// Tâche du membre B, réalisée par le membre C.
//
// RLS (03_rls.sql) : tout le monde lit les annonces « publiee » ;
// l'annonceur lit aussi les siennes (brouillon, en attente…), l'admin
// lit tout. Une annonce cachée par la RLS revient VIDE (pas d'erreur) :
// on la traite comme « introuvable ».
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/detail/data/models/annonce_detail.dart';

class DetailException implements Exception {
  const DetailException(this.message, {this.introuvable = false});

  static const messageIntrouvable = 'Cette annonce n’existe plus ou n’est plus visible.';

  final String message;

  /// true : inutile de réessayer (annonce supprimée, retirée ou lien faux).
  final bool introuvable;

  @override
  String toString() => message;
}

abstract class DetailRepository {
  Future<AnnonceDetail> charger(String idAnnonce);
}

class SupabaseDetailRepository implements DetailRepository {
  SupabaseDetailRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<AnnonceDetail> charger(String idAnnonce) async {
    final Map<String, dynamic>? ligne;
    try {
      ligne = await _client.from('annonces').select(AnnonceDetail.colonnes).eq('id', idAnnonce).maybeSingle();
    } on PostgrestException catch (e) {
      debugPrint('[3.3] ${e.code} : ${e.message}');
      // 22P02 : l'id du lien n'est pas un uuid valide.
      if (e.code == '22P02') throw const DetailException(DetailException.messageIntrouvable, introuvable: true);
      throw DetailException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[3.3] $e');
      throw const DetailException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
    if (ligne == null) throw const DetailException(DetailException.messageIntrouvable, introuvable: true);

    final annonce = AnnonceDetail.depuisLigne(ligne);
    return annonce.avecNbAnnonces(await _compterAnnonces(annonce.idAnnonceur));
  }

  /// « 8 annonces » sous le nom de l'annonceur : facultatif, une erreur ici
  /// ne doit pas empêcher d'afficher l'annonce.
  Future<int?> _compterAnnonces(String idAnnonceur) async {
    try {
      final r = await _client
          .from('annonces')
          .select('id')
          .eq('id_annonceur', idAnnonceur)
          .eq('statut', 'publiee')
          .count(CountOption.exact);
      return r.count;
    } catch (e) {
      debugPrint('[3.3] compteur annonceur : $e');
      return null;
    }
  }
}
