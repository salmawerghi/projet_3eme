// =====================================================================
// DarImmo - [6.1] AnnonceRepository : accès à la table annonces
// Membre C
//
// Seule classe du module qui parle à Supabase. L'écran et le ViewModel
// n'en dépendent qu'à travers l'interface AnnonceRepository, ce qui permet
// de les tester avec un faux repository (test/publish/).
// =====================================================================
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/annonce.dart';

/// Erreur compréhensible par l'utilisateur.
class PublicationException implements Exception {
  const PublicationException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AnnonceRepository {
  /// Enregistre l'annonce au statut « en attente » pour l'utilisateur connecté.
  Future<Annonce> publier(NouvelleAnnonce annonce);
}

class SupabaseAnnonceRepository implements AnnonceRepository {
  SupabaseAnnonceRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Annonce> publier(NouvelleAnnonce annonce) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PublicationException('Connectez-vous pour publier une annonce.');
    }
    try {
      // INSERT ... RETURNING : la base renvoie la ligne créée (id, statut, date).
      // RLS : id_annonceur doit être l'utilisateur connecté et il ne doit pas être bloqué.
      final ligne = await _client
          .from('annonces')
          .insert(annonce.versLigne(user.id))
          .select('id, titre, type_bien, type_offre, prix, ville, statut, date_creation')
          .single();
      return Annonce.depuisLigne(ligne);
    } on PostgrestException catch (e) {
      throw PublicationException(_message(e));
    } on AuthException catch (_) {
      throw const PublicationException('Session expirée : reconnectez-vous.');
    } on PublicationException {
      rethrow;
    } catch (_) {
      throw const PublicationException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  /// Codes PostgreSQL : 42501 = refusé par RLS, 23514 = contrainte CHECK.
  static String _message(PostgrestException e) {
    switch (e.code) {
      case '42501':
        return 'Publication refusée : votre compte est peut-être bloqué.';
      case '23514':
        return 'Certaines valeurs ne sont pas acceptées (vérifiez le prix, la surface et le titre).';
      case 'PGRST301':
      case '401':
        return 'Session expirée : reconnectez-vous.';
      default:
        return 'Erreur du serveur (${e.code ?? 'inconnue'}) : ${e.message}';
    }
  }
}
