// =====================================================================
// DarImmo - Services partagés (tâche 1.6)
//
// UN SEUL endroit crée les repositories qui parlent à Supabase. Le routeur
// les donne aux écrans. Les tests construisent des Services avec de faux
// repositories (aucun accès réseau).
//
// Pour ajouter son module : déclarer son interface ici, la créer dans
// Services.supabase(...), puis la passer à son écran dans core/router.
// =====================================================================
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/chat/data/repositories/chat_repository.dart';
import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';
import 'package:darimmo/features/notifications/data/push_service.dart';
import 'package:darimmo/features/publish/data/repositories/annonce_repository.dart';
import 'package:darimmo/features/publish/data/repositories/mes_annonces_repository.dart';
import 'package:darimmo/features/publish/data/repositories/photos_repository.dart';
import 'package:darimmo/features/publish/data/services/choisir_photos.dart';
import 'package:darimmo/features/search/data/repositories/recherche_repository.dart';
import 'package:darimmo/core/location/geocodage.dart';
import 'package:darimmo/core/location/localisation.dart';

class Services {
  Services({
    required this.auth,
    required this.recherche,
    required this.annonces,
    required this.photos,
    required this.mesAnnonces,
    required this.conversations,
    required this.chat,
    required this.geocodage,
    required this.localisation,
    this.push,
    this.choisirPhotos = choisirDansLaGalerie,
    this.afficherTuilesCarte = true,
  });

  /// Version réelle : tout passe par Supabase.
  factory Services.supabase(SupabaseClient client) => Services(
        auth: SupabaseAuthRepository(client),
        recherche: SupabaseRechercheRepository(client),
        annonces: SupabaseAnnonceRepository(client),
        photos: SupabasePhotosRepository(client),
        mesAnnonces: SupabaseMesAnnoncesRepository(client),
        conversations: SupabaseConversationsRepository(client),
        chat: SupabaseChatRepository(client),
        geocodage: NominatimGeocodage(),
        localisation: const GeolocatorLocalisation(),
      );

  // ----- Membre A
  final AuthRepository auth;

  // ----- Membre B
  final RechercheRepository recherche;

  // ----- Membre C
  final AnnonceRepository annonces;
  final PhotosRepository photos;
  final MesAnnoncesRepository mesAnnonces;
  final ConversationsRepository conversations;
  final ChatRepository chat;

  /// null sur le web, ou si Firebase n'est pas configuré (pas de google-services.json).
  PushService? push;

  // ----- Partagés (carte, géolocalisation : aussi pour le membre B, 4.1 / 4.2)
  final Geocodage geocodage;
  final Localisation localisation;
  final ChoisirPhotos choisirPhotos;
  final bool afficherTuilesCarte; // false dans les tests

  /// Déconnexion propre : l'appareil ne reçoit plus les push de ce compte.
  Future<void> deconnecter() async {
    try {
      await push?.desinscrire();
    } finally {
      await auth.deconnecter();
    }
  }
}
