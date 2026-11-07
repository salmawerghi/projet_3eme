// =====================================================================
// DarImmo - [6.2] PhotosRepository : bucket annonces-photos + table photos
// Membre C
//
// Seule classe du module qui parle à Supabase. Règles côté base :
//   - storage.objects : l'annonceur n'écrit que dans « <id_annonce>/ »
//     de SES annonces (04_storage_realtime.sql) ;
//   - public.photos   : ordre 0..9, unique par annonce (01_schema.sql) ;
//     contrainte DEFERRABLE : vérifiée à la fin de chaque requête, ce qui
//     permet de renuméroter toutes les photos en un seul upsert.
// =====================================================================
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/publish/data/models/photo_annonce.dart';

/// Erreur compréhensible par l'utilisateur.
class PhotosException implements Exception {
  const PhotosException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PhotosRepository {
  /// Photos de l'annonce, de la couverture (ordre 0) à la dernière.
  Future<List<PhotoEnregistree>> lister(String idAnnonce);

  /// Envoie le fichier dans « `<id_annonce>/` » puis crée la ligne avec cet [ordre].
  Future<PhotoEnregistree> envoyer(String idAnnonce, PhotoChoisie photo, int ordre);

  /// Efface le fichier du bucket puis la ligne.
  Future<void> supprimer(PhotoEnregistree photo);

  /// Renumérote les photos 0, 1, 2… dans l'ordre de la liste.
  Future<void> ordonner(List<PhotoEnregistree> photos);
}

class SupabasePhotosRepository implements PhotosRepository {
  SupabasePhotosRepository(this._client);
  final SupabaseClient _client;

  static const bucket = 'annonces-photos';

  @override
  Future<List<PhotoEnregistree>> lister(String idAnnonce) => _executer(() async {
        final lignes = await _client
            .from('photos')
            .select(PhotoEnregistree.colonnes)
            .eq('id_annonce', idAnnonce)
            .order('ordre');
        return lignes.map(PhotoEnregistree.depuisLigne).toList();
      });

  @override
  Future<PhotoEnregistree> envoyer(String idAnnonce, PhotoChoisie photo, int ordre) => _executer(() async {
        if (photo.octets.length > tailleMaxOctets) {
          throw const PhotosException('Photo trop lourde (5 Mo maximum).');
        }
        final chemin = '$idAnnonce/${_nomAleatoire()}.${photo.extension}';
        final fichiers = _client.storage.from(bucket);

        // 1) Le fichier
        await fichiers.uploadBinary(
          chemin,
          photo.octets,
          fileOptions: FileOptions(contentType: photo.typeMime, cacheControl: '31536000'),
        );

        // 2) La ligne. Si elle échoue, on retire le fichier pour ne pas laisser d'orphelin.
        try {
          final ligne = await _client
              .from('photos')
              .insert({
                'id_annonce': idAnnonce,
                'chemin_storage': chemin,
                'url': fichiers.getPublicUrl(chemin),
                'ordre': ordre,
              })
              .select(PhotoEnregistree.colonnes)
              .single();
          return PhotoEnregistree.depuisLigne(ligne);
        } catch (_) {
          await _effacerFichiers([chemin]);
          rethrow;
        }
      });

  @override
  Future<void> supprimer(PhotoEnregistree photo) => _executer(() async {
        // Le fichier d'abord : la règle du stockage vérifie que la photo
        // appartient à une annonce de l'utilisateur.
        if (photo.dansLeBucket) await _effacerFichiers([photo.chemin]);
        await _client.from('photos').delete().eq('id', photo.id);
      });

  @override
  Future<void> ordonner(List<PhotoEnregistree> photos) => _executer(() async {
        if (photos.isEmpty) return;
        // Un seul upsert = une seule requête : la contrainte d'unicité (id_annonce, ordre)
        // est vérifiée à la fin, donc échanger deux photos ne provoque pas de doublon.
        await _client.from('photos').upsert([
          for (final (i, p) in photos.indexed)
            {'id': p.id, 'id_annonce': p.idAnnonce, 'chemin_storage': p.chemin, 'url': p.url, 'ordre': i},
        ], onConflict: 'id');
      });

  Future<void> _effacerFichiers(List<String> chemins) async {
    try {
      await _client.storage.from(bucket).remove(chemins);
    } catch (e) {
      debugPrint('[6.2] Fichiers non effacés du stockage $chemins : $e');
    }
  }

  static final _hasard = Random.secure();

  /// 16 octets aléatoires en hexadécimal (évite d'ajouter le paquet uuid).
  static String _nomAleatoire() =>
      List.generate(16, (_) => _hasard.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  /// Traduit les erreurs techniques en messages clairs (critère « message clair »).
  Future<T> _executer<T>(Future<T> Function() action) async {
    if (_client.auth.currentUser == null) throw const PhotosException('Session expirée : reconnectez-vous.');
    try {
      return await action();
    } on PhotosException {
      rethrow;
    } on StorageException catch (e) {
      debugPrint('[6.2] StorageException ${e.statusCode} : ${e.message}');
      throw PhotosException(switch (e.statusCode) {
        '413' => 'Photo trop lourde (5 Mo maximum).',
        '415' => 'Format non accepté : choisissez une photo JPEG, PNG ou WebP.',
        '403' || '401' => 'Envoi refusé : cette annonce ne vous appartient pas ou la session a expiré.',
        _ => 'L’envoi de la photo a échoué. Vérifiez votre connexion puis réessayez.',
      });
    } on PostgrestException catch (e) {
      debugPrint('[6.2] PostgrestException ${e.code} : ${e.message}');
      throw PhotosException(switch (e.code) {
        '23514' => 'Une annonce ne peut pas avoir plus de $photosMax photos.',
        '23505' => 'Conflit dans l’ordre des photos : réessayez.',
        '42501' => 'Action refusée : cette annonce ne vous appartient pas.',
        _ => 'Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.',
      });
    } on AuthException catch (_) {
      throw const PhotosException('Session expirée : reconnectez-vous.');
    } catch (e) {
      debugPrint('[6.2] Erreur : $e');
      throw const PhotosException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }
}
