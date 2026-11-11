// =====================================================================
// DarImmo - [7.3] ConversationsRepository : liste + mises à jour en direct
// Membre C
//
// Seule classe du module qui parle à Supabase :
//   - public.mes_conversations() : la liste, déjà triée par date_dernier_message ;
//   - Realtime sur public.conversations : un nouveau message met à jour
//     date_dernier_message (trigger messages_dernier_message), ce qui
//     rafraîchit la liste sans recharger. RLS : seulement MES conversations.
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/chat/data/models/resume_conversation.dart';

class ConversationsException implements Exception {
  const ConversationsException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// [7.1] Erreur du bouton « Contacter ».
class ContactException implements Exception {
  const ContactException(this.message, {this.connexionRequise = false});
  final String message;

  /// Vrai si l'utilisateur doit d'abord se connecter (critère « compte obligatoire »).
  final bool connexionRequise;

  /// Traduit les erreurs levées par public.ouvrir_conversation (02_fonctions.sql).
  factory ContactException.depuisServeur(String message) {
    if (message.contains('Connexion obligatoire')) {
      return const ContactException('Connectez-vous pour contacter l’annonceur.', connexionRequise: true);
    }
    if (message.contains('vous-même')) {
      return const ContactException('C’est votre annonce : vous ne pouvez pas vous contacter vous-même.');
    }
    if (message.contains('introuvable')) {
      return const ContactException('Cette annonce n’est plus disponible.');
    }
    return const ContactException('Erreur du serveur. Réessayez.');
  }

  @override
  String toString() => message;
}

abstract class ConversationsRepository {
  /// Mes conversations, de la plus récente à la plus ancienne.
  Future<List<ResumeConversation>> lister();

  /// Émet un événement à chaque changement dans mes conversations.
  /// L'abonnement Realtime est fermé quand on annule l'écoute.
  Stream<void> changements();

  /// [7.1] Ouvre la conversation avec l'annonceur de [idAnnonce], ou reprend
  /// celle qui existe déjà. Renvoie son id. Lève [ContactException].
  Future<String> ouvrirAvecAnnonceur(String idAnnonce);
}

class SupabaseConversationsRepository implements ConversationsRepository {
  SupabaseConversationsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<String> ouvrirAvecAnnonceur(String idAnnonce) async {
    if (_client.auth.currentUser == null) {
      throw const ContactException('Connectez-vous pour contacter l’annonceur.', connexionRequise: true);
    }
    final Object? id;
    try {
      // La fonction SQL vérifie tout : connexion, annonce publiée, pas soi-même,
      // et « on conflict do nothing » reprend la conversation existante.
      id = await _client.rpc('ouvrir_conversation', params: {'p_annonce': idAnnonce});
    } on PostgrestException catch (e) {
      debugPrint('[7.1] ${e.code} : ${e.message}');
      throw ContactException.depuisServeur(e.message);
    } on AuthException catch (_) {
      throw const ContactException('Session expirée : reconnectez-vous.', connexionRequise: true);
    } catch (e) {
      debugPrint('[7.1] $e');
      throw const ContactException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
    if (id is! String) throw const ContactException('Erreur du serveur. Réessayez.');
    return id;
  }

  @override
  Future<List<ResumeConversation>> lister() async {
    if (_client.auth.currentUser == null) {
      throw const ConversationsException('Connectez-vous pour voir vos messages.');
    }
    try {
      final lignes = await _client.rpc('mes_conversations') as List;
      return [for (final l in lignes) ResumeConversation.depuisLigne(Map<String, dynamic>.from(l as Map))];
    } on PostgrestException catch (e) {
      debugPrint('[7.3] ${e.code} : ${e.message}');
      throw ConversationsException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } on AuthException catch (_) {
      throw const ConversationsException('Session expirée : reconnectez-vous.');
    } catch (e) {
      debugPrint('[7.3] $e');
      throw const ConversationsException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Stream<void> changements() {
    RealtimeChannel? canal;
    late final StreamController<void> flux;
    flux = StreamController<void>(
      onListen: () {
        canal = _client.channel('mes-conversations')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (_) => flux.add(null),
          )
          ..subscribe();
      },
      onCancel: () async {
        if (canal != null) await _client.removeChannel(canal!);
      },
    );
    return flux.stream;
  }
}
