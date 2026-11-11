// =====================================================================
// DarImmo - [7.2] ChatRepository : échanger en temps réel
// Membre C
//
// Seule classe de la discussion qui parle à Supabase :
//   - historique : select sur public.messages (RLS : participants seulement) ;
//   - envoi      : insert (RLS : participant non bloqué) ; le webhook
//                  push_messages déclenche ensuite la notification (8.1) ;
//   - temps réel : Realtime INSERT sur public.messages, filtré sur la
//                  conversation ;
//   - lu         : fonction public.marquer_conversation_lue (7.3).
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/chat/data/models/infos_discussion.dart';
import 'package:darimmo/features/chat/data/models/message.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';

class ChatException implements Exception {
  const ChatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Ce que le temps réel envoie à l'écran.
sealed class EvenementChat {
  const EvenementChat();
}

/// Un message vient d'être enregistré dans la conversation (reçu OU envoyé).
class MessageRecu extends EvenementChat {
  const MessageRecu(this.message);
  final Message message;
}

/// La connexion temps réel est (re)établie : des messages ont pu être
/// manqués pendant la coupure, il faut recharger l'historique.
class ConnexionRetablie extends EvenementChat {
  const ConnexionRetablie();
}

abstract class ChatRepository {
  /// Identifiant de l'utilisateur connecté (null si déconnecté).
  String? get moi;

  /// Interlocuteur et annonce liée ; null si la conversation est introuvable.
  Future<InfosDiscussion?> infos(String idConversation);

  /// Tous les messages de la conversation, du plus ancien au plus récent.
  Future<List<Message>> historique(String idConversation);

  /// Enregistre le message et renvoie la ligne créée (avec id et date).
  Future<Message> envoyer(String idConversation, String contenu);

  /// Remet à zéro les « non lus » de cette conversation.
  Future<void> marquerLu(String idConversation);

  /// Événements temps réel ; l'abonnement est fermé quand on annule l'écoute.
  Stream<EvenementChat> evenements(String idConversation);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);
  final SupabaseClient _client;

  @override
  String? get moi => _client.auth.currentUser?.id;

  /// Traduit les erreurs techniques en messages pour l'utilisateur.
  Future<T> _appel<T>(Future<T> Function() f) async {
    if (moi == null) throw const ChatException('Connectez-vous pour discuter.');
    try {
      return await f();
    } on PostgrestException catch (e) {
      debugPrint('[7.2] ${e.code} : ${e.message}');
      // 42501 = refusé par la RLS (compte bloqué, pas participant…)
      if (e.code == '42501') throw const ChatException('Action non autorisée sur cette conversation.');
      throw ChatException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } on AuthException catch (_) {
      throw const ChatException('Session expirée : reconnectez-vous.');
    } on ChatException {
      rethrow;
    } catch (e) {
      debugPrint('[7.2] $e');
      throw const ChatException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<InfosDiscussion?> infos(String idConversation) => _appel(() async {
        final lignes = await _client.rpc('mes_conversations') as List;
        final ligne = lignes.cast<Map>().where((l) => l['id'] == idConversation).firstOrNull;
        if (ligne == null) return null;
        final conversation = ResumeConversation.depuisLigne(Map<String, dynamic>.from(ligne));

        // Prix et ville : l'annonce peut ne plus être visible (RLS) -> null.
        Map<String, dynamic>? annonce;
        if (conversation.idAnnonce != null) {
          annonce = await _client
              .from('annonces')
              .select('prix, type_offre, ville')
              .eq('id', conversation.idAnnonce!)
              .maybeSingle();
        }
        return InfosDiscussion(
          conversation: conversation,
          prix: (annonce?['prix'] as num?)?.toDouble(),
          location: annonce?['type_offre'] == 'location',
          ville: annonce?['ville'] as String?,
        );
      });

  @override
  Future<List<Message>> historique(String idConversation) => _appel(() async {
        final lignes = await _client
            .from('messages')
            .select()
            .eq('id_conversation', idConversation)
            .order('date_envoi')
            .order('id');
        return [for (final l in lignes) Message.depuisLigne(l)];
      });

  @override
  Future<Message> envoyer(String idConversation, String contenu) => _appel(() async {
        final ligne = await _client
            .from('messages')
            .insert({'id_conversation': idConversation, 'id_expediteur': moi, 'contenu': contenu})
            .select()
            .single();
        return Message.depuisLigne(ligne);
      });

  /// Avec supabase_flutter, une requête n'est envoyée que si on l'attend (await).
  @override
  Future<void> marquerLu(String idConversation) => _appel(() async {
        await _client.rpc('marquer_conversation_lue', params: {'p_conversation': idConversation});
      });

  @override
  Stream<EvenementChat> evenements(String idConversation) {
    RealtimeChannel? canal;
    late final StreamController<EvenementChat> flux;
    var premiereConnexion = true;
    flux = StreamController<EvenementChat>(
      onListen: () {
        canal = _client.channel('discussion-$idConversation')
          ..onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id_conversation',
              value: idConversation,
            ),
            callback: (payload) => flux.add(MessageRecu(Message.depuisLigne(payload.newRecord))),
          )
          ..subscribe((statut, erreur) {
            if (erreur != null) debugPrint('[7.2] Realtime : $statut $erreur');
            if (statut != RealtimeSubscribeStatus.subscribed) return;
            // La 1re connexion suit le chargement de l'historique ; les
            // suivantes sont des reconnexions (réseau coupé, veille…).
            if (!premiereConnexion) flux.add(const ConnexionRetablie());
            premiereConnexion = false;
          });
      },
      onCancel: () async {
        if (canal != null) await _client.removeChannel(canal!);
      },
    );
    return flux.stream;
  }
}
