// =====================================================================
// DarImmo - [6.3] MesAnnoncesRepository : les annonces de l'utilisateur
// Membre C
//
// Seule classe du module qui parle à Supabase (comme pour la 6.1).
// L'écran et le ViewModel passent par l'interface, ce qui permet de
// les tester avec un faux repository (test/mes_annonces/).
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/data/models/mon_annonce.dart';

/// Erreur compréhensible par l'utilisateur.
class MesAnnoncesException implements Exception {
  const MesAnnoncesException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class MesAnnoncesRepository {
  /// Toutes les annonces de l'utilisateur connecté, quel que soit leur statut,
  /// de la plus récemment modifiée à la plus ancienne.
  Future<List<MonAnnonce>> lister();

  /// [6.3] publiee -> vendue (offre de vente) ou louee (offre de location).
  Future<void> marquerConclue(MonAnnonce annonce);

  /// [6.3] Supprime l'annonce et ses photos (base + stockage).
  /// Les conversations liées sont gardées (id_annonce passe à null).
  Future<void> supprimer(MonAnnonce annonce);
}

class SupabaseMesAnnoncesRepository implements MesAnnoncesRepository {
  SupabaseMesAnnoncesRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<MonAnnonce>> lister() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const MesAnnoncesException('Connectez-vous pour voir vos annonces.');
    try {
      // Le filtre id_annonceur est nécessaire : la règle RLS laisse aussi voir
      // les annonces publiées des autres (et tout, pour un administrateur).
      final lignes = await _client
          .from('annonces')
          .select(MonAnnonce.colonnes)
          .eq('id_annonceur', user.id)
          .order('date_maj', ascending: false);
      return lignes.map(MonAnnonce.depuisLigne).toList();
    } on PostgrestException catch (e) {
      throw MesAnnoncesException('Erreur du serveur (${e.code ?? 'inconnue'}) : ${e.message}');
    } on AuthException catch (_) {
      throw const MesAnnoncesException('Session expirée : reconnectez-vous.');
    } catch (_) {
      throw const MesAnnoncesException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<void> marquerConclue(MonAnnonce annonce) async {
    final statut = annonce.statutConclu == StatutAnnonce.louee ? 'louee' : 'vendue';
    await _executer(() async {
      // Le trigger annonces_statut n'autorise que publiee -> vendue | louee.
      final lignes = await _client.from('annonces').update({'statut': statut}).eq('id', annonce.id).select('id');
      if (lignes.isEmpty) throw const MesAnnoncesException('Annonce introuvable ou modification refusée.');
    });
  }

  @override
  Future<void> supprimer(MonAnnonce annonce) async {
    await _executer(() async {
      // 1) Les fichiers d'abord : la règle de suppression du stockage vérifie que
      //    l'annonce existe et appartient à l'utilisateur. Après le DELETE de la
      //    ligne, ce ne serait plus possible et les fichiers resteraient orphelins.
      //    Seuls les fichiers du dossier de l'annonce sont concernés (les photos
      //    du seed pointent vers « seed/... » et des URL externes).
      final fichiers = annonce.cheminsPhotos.where((c) => c.startsWith('${annonce.id}/')).toList();
      if (fichiers.isNotEmpty) {
        try {
          await _client.storage.from(bucketPhotos).remove(fichiers);
        } on StorageException catch (e) {
          // On supprime quand même l'annonce : l'utilisateur l'a demandé, et des
          // fichiers orphelins sont moins graves qu'une annonce impossible à retirer.
          debugPrint('[6.3] Photos non effacées du stockage (${annonce.id}) : ${e.message}');
        }
      }
      // 2) La ligne : photos, favoris et signalements suivent (on delete cascade),
      //    les conversations sont gardées (on delete set null).
      final lignes = await _client.from('annonces').delete().eq('id', annonce.id).select('id');
      if (lignes.isEmpty) throw const MesAnnoncesException('Annonce introuvable ou suppression refusée.');
    });
  }

  static const bucketPhotos = 'annonces-photos';

  /// Traduit les erreurs techniques en messages pour l'utilisateur.
  Future<void> _executer(Future<void> Function() action) async {
    if (_client.auth.currentUser == null) throw const MesAnnoncesException('Connectez-vous pour gérer vos annonces.');
    try {
      await action();
    } on MesAnnoncesException {
      rethrow;
    } on PostgrestException catch (e) {
      // P0001 = refus du trigger (ex : « Changement de statut non autorisé »)
      throw MesAnnoncesException(e.code == 'P0001' ? e.message : 'Erreur du serveur (${e.code ?? 'inconnue'}) : ${e.message}');
    } on AuthException catch (_) {
      throw const MesAnnoncesException('Session expirée : reconnectez-vous.');
    } catch (_) {
      throw const MesAnnoncesException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }
}
