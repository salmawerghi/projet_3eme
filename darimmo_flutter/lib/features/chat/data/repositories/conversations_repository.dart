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

abstract class ConversationsRepository {
  /// Mes conversations, de la plus récente à la plus ancienne.
  Future<List<ResumeConversation>> lister();

  /// Émet un événement à chaque changement dans mes conversations.
  /// L'abonnement Realtime est fermé quand on annule l'écoute.
  Stream<void> changements();
}

class SupabaseConversationsRepository implements ConversationsRepository {
  SupabaseConversationsRepository(this._client);
  final SupabaseClient _client;

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
