import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/publish/data/models/photo_annonce.dart';

class ProfilException implements Exception {
  const ProfilException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DonneesProfil {
  const DonneesProfil({required this.nom, this.telephone, this.photoUrl});

  final String nom;
  final String? telephone;
  final String? photoUrl;

  factory DonneesProfil.depuisLigne(Map<String, dynamic> ligne) =>
      DonneesProfil(
        nom: ligne['nom'] as String? ?? '',
        telephone: ligne['telephone'] as String?,
        photoUrl: ligne['photo_url'] as String?,
      );
}

abstract class ProfilRepository {
  Future<DonneesProfil> charger();

  Future<DonneesProfil> enregistrer({
    required String nom,
    required String? telephone,
    PhotoChoisie? photo,
  });
}

class SupabaseProfilRepository implements ProfilRepository {
  SupabaseProfilRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'avatars';
  static const _tailleMax = 2 * 1024 * 1024;
  static final _hasard = Random.secure();

  @override
  Future<DonneesProfil> charger() => _executer(() async {
    final utilisateur = _client.auth.currentUser;
    if (utilisateur == null) {
      throw const ProfilException('Session expirée : reconnectez-vous.');
    }

    final ligne = await _client
        .from('profiles')
        .select('nom, telephone, photo_url')
        .eq('id', utilisateur.id)
        .single();
    return DonneesProfil.depuisLigne(ligne);
  });

  @override
  Future<DonneesProfil> enregistrer({
    required String nom,
    required String? telephone,
    PhotoChoisie? photo,
  }) => _executer(() async {
    final utilisateur = _client.auth.currentUser;
    if (utilisateur == null) {
      throw const ProfilException('Session expirée : reconnectez-vous.');
    }

    final valeurs = <String, dynamic>{
      'nom': nom.trim(),
      'telephone': telephone,
    };
    if (photo != null) {
      if (photo.octets.length > _tailleMax) {
        throw const ProfilException('Photo trop lourde (2 Mo maximum).');
      }
      final chemin =
          '${utilisateur.id}/avatar-${_nomAleatoire()}.${photo.extension}';
      final stockage = _client.storage.from(_bucket);
      await stockage.uploadBinary(
        chemin,
        photo.octets,
        fileOptions: FileOptions(
          contentType: photo.typeMime,
          cacheControl: '31536000',
        ),
      );
      valeurs['photo_url'] = stockage.getPublicUrl(chemin);
    }

    final ligne = await _client
        .from('profiles')
        .update(valeurs)
        .eq('id', utilisateur.id)
        .select('nom, telephone, photo_url')
        .single();
    return DonneesProfil.depuisLigne(ligne);
  });

  static String _nomAleatoire() => List.generate(
    16,
    (_) => _hasard.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  Future<T> _executer<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ProfilException {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('[2.3] PostgrestException ${e.code}: ${e.message}');
      throw const ProfilException(
        'Impossible d’enregistrer le profil. Vérifiez vos données et réessayez.',
      );
    } on StorageException catch (e) {
      debugPrint('[2.3] StorageException ${e.statusCode}: ${e.message}');
      throw ProfilException(switch (e.statusCode) {
        '413' => 'Photo trop lourde (2 Mo maximum).',
        '415' => 'Format non accepté : choisissez une photo JPEG, PNG ou WebP.',
        '401' || '403' => 'Envoi refusé : vérifiez votre session et les droits du bucket avatars.',
        _ => 'L’envoi de la photo a échoué. Vérifiez votre connexion puis réessayez.',
      });
    } on AuthException {
      throw const ProfilException('Session expirée : reconnectez-vous.');
    } catch (e) {
      debugPrint('[2.3] Erreur: $e');
      throw const ProfilException(
        'Connexion impossible. Vérifiez Internet et réessayez.',
      );
    }
  }
}
