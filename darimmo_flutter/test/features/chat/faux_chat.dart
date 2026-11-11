// Faux ChatRepository pour les tests de [7.2] (aucun accès à Supabase).
import 'dart:async';

import 'package:darimmo/features/chat/data/models/infos_discussion.dart';
import 'package:darimmo/features/chat/data/models/message.dart';
import 'package:darimmo/features/chat/data/repositories/chat_repository.dart';

const moiId = 'u-moi';
const autreId = 'u-autre';

Message msg(int id, String texte, DateTime date, {String de = autreId, String conv = 'c1'}) => Message(
      id: id,
      idConversation: conv,
      idExpediteur: de,
      contenu: texte,
      dateEnvoi: date,
    );

class FauxChat implements ChatRepository {
  FauxChat({List<Message>? historique, this.infosResultat}) : historiqueResultat = historique ?? [];

  List<Message> historiqueResultat;
  InfosDiscussion? infosResultat;

  /// Erreur renvoyée par historique() / envoyer() (null = succès).
  String? erreurHistorique;
  String? erreurEnvoi;

  /// Si non null, envoyer() attend ce Completer (pour voir l'état « envoi… »).
  Completer<void>? bloquerEnvoi;

  final envoyes = <String>[];
  int marquesLus = 0;
  int chargementsHistorique = 0;
  int _prochainId = 1000;
  final _flux = StreamController<EvenementChat>.broadcast();
  bool ecoute = false;

  /// Simule un message arrivé par Realtime.
  void recevoir(Message m) => _flux.add(MessageRecu(m));

  /// Simule une reconnexion Realtime.
  void reconnecter() => _flux.add(const ConnexionRetablie());

  @override
  String? get moi => moiId;

  @override
  Future<InfosDiscussion?> infos(String idConversation) async => infosResultat;

  @override
  Future<List<Message>> historique(String idConversation) async {
    chargementsHistorique++;
    if (erreurHistorique != null) throw ChatException(erreurHistorique!);
    return List.of(historiqueResultat);
  }

  @override
  Future<Message> envoyer(String idConversation, String contenu) async {
    if (bloquerEnvoi != null) await bloquerEnvoi!.future;
    if (erreurEnvoi != null) throw ChatException(erreurEnvoi!);
    envoyes.add(contenu);
    return msg(_prochainId++, contenu, DateTime(2026, 11, 7, 14, 40), de: moiId, conv: idConversation);
  }

  @override
  Future<void> marquerLu(String idConversation) async => marquesLus++;

  @override
  Stream<EvenementChat> evenements(String idConversation) {
    ecoute = true;
    return _flux.stream;
  }
}
