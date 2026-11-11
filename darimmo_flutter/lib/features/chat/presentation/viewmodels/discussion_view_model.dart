// =====================================================================
// DarImmo - [7.2] ViewModel de la discussion (Provider)
// Membre C
//
// Critères d'acceptation :
//   - le message apparaît chez le destinataire sans recharger (Realtime) ;
//   - heure d'envoi affichée ;
//   - historique conservé (rechargé à l'ouverture et après une coupure) ;
//   - seuls les deux participants lisent / écrivent (RLS, côté base).
// Un message envoyé s'affiche tout de suite (« envoi… »), puis devient
// définitif, ou passe en « échec » avec « Réessayer ».
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:darimmo/features/chat/data/models/infos_discussion.dart';
import 'package:darimmo/features/chat/data/models/message.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart' show formaterJourDiscussion;
import 'package:darimmo/features/chat/data/repositories/chat_repository.dart';

/// Ce que la liste affiche : un séparateur de jour ou une bulle.
sealed class ElementDiscussion {
  const ElementDiscussion();
}

class SeparateurJour extends ElementDiscussion {
  const SeparateurJour(this.texte);
  final String texte;
}

class BulleMessage extends ElementDiscussion {
  const BulleMessage(this.message, {required this.deMoi});
  final Message message;
  final bool deMoi;
}

class DiscussionViewModel extends ChangeNotifier {
  DiscussionViewModel(this._repository, this.idConversation, {DateTime Function()? horloge})
      : _horloge = horloge ?? DateTime.now;

  final ChatRepository _repository;
  final String idConversation;
  final DateTime Function() _horloge;

  final List<Message> _messages = [];
  InfosDiscussion? infos;
  bool chargement = false;
  String? erreur;
  StreamSubscription<EvenementChat>? _abonnement;
  int _compteurLocal = 0;
  bool _detruit = false;

  String? get moi => _repository.moi;
  List<Message> get messages => List.unmodifiable(_messages);
  bool get vide => _messages.isEmpty;

  /// Ouverture : abonnement temps réel AVANT l'historique, pour ne rater
  /// aucun message envoyé entre les deux (les doublons sont ignorés).
  Future<void> demarrer() async {
    _abonnement ??= _repository.evenements(idConversation).listen(_surEvenement);
    unawaited(_chargerInfos());
    await charger();
  }

  Future<void> _chargerInfos() async {
    try {
      infos = await _repository.infos(idConversation);
      _notifier();
    } on ChatException catch (e) {
      debugPrint('[7.2] en-tête : $e'); // l'en-tête n'est pas indispensable
    }
  }

  /// Charge (ou recharge) l'historique et le fusionne avec l'affichage.
  /// [silencieux] : sans indicateur de chargement (reconnexion, retour au premier plan).
  Future<void> charger({bool silencieux = false}) async {
    if (!silencieux) {
      chargement = true;
      erreur = null;
      _notifier();
    }
    try {
      final historique = await _repository.historique(idConversation);
      for (final m in historique) {
        _fusionner(m);
      }
      erreur = null;
      unawaited(_marquerLu());
    } on ChatException catch (e) {
      if (!silencieux || _messages.isEmpty) erreur = e.message;
    } finally {
      chargement = false;
      _notifier();
    }
  }

  void _surEvenement(EvenementChat e) {
    switch (e) {
      case MessageRecu(:final message):
        _fusionner(message);
        if (message.idExpediteur != moi) unawaited(_marquerLu());
        _notifier();
      case ConnexionRetablie():
        unawaited(charger(silencieux: true));
    }
  }

  /// Ajoute un message enregistré, sans doublon. Si c'est l'un de MES
  /// messages encore « en cours », il remplace la bulle provisoire.
  void _fusionner(Message m) {
    if (_messages.any((x) => x.id == m.id)) return;
    if (m.idExpediteur == moi) {
      final i = _messages.indexWhere((x) => x.etat == EtatEnvoi.enCours && x.contenu == m.contenu);
      if (i >= 0) _messages.removeAt(i);
    }
    _messages.add(m);
    _messages.sort(Message.comparer);
  }

  Future<void> _marquerLu() async {
    try {
      await _repository.marquerLu(idConversation);
    } on ChatException catch (e) {
      debugPrint('[7.2] marquer lu : $e');
    }
  }

  /// Texte prêt à envoyer (sans espaces autour), ou null s'il est vide.
  static String? texteValide(String saisie) {
    final t = saisie.trim();
    return t.isEmpty ? null : t;
  }

  /// Envoie le texte. Renvoie false s'il n'y a rien à envoyer.
  Future<bool> envoyer(String saisie) async {
    final texte = texteValide(saisie);
    final expediteur = moi;
    if (texte == null || expediteur == null) return false;
    final local = Message.local(
      cle: 'local-${_compteurLocal++}',
      idConversation: idConversation,
      idExpediteur: expediteur,
      contenu: texte.length > longueurMaxMessage ? texte.substring(0, longueurMaxMessage) : texte,
      date: _horloge(),
    );
    _messages.add(local);
    _notifier();
    await _envoyerLocal(local);
    return true;
  }

  /// Renvoie un message en échec.
  Future<void> reessayer(Message m) async {
    final i = _messages.indexWhere((x) => x.cleLocale == m.cleLocale);
    if (i < 0 || m.etat != EtatEnvoi.echec) return;
    _messages[i] = m.avecEtat(EtatEnvoi.enCours);
    _notifier();
    await _envoyerLocal(_messages[i]);
  }

  /// Retire un message en échec qu'on ne veut plus envoyer.
  void abandonner(Message m) {
    _messages.removeWhere((x) => x.cleLocale == m.cleLocale && x.etat == EtatEnvoi.echec);
    _notifier();
  }

  Future<void> _envoyerLocal(Message local) async {
    try {
      final enregistre = await _repository.envoyer(idConversation, local.contenu);
      _messages.removeWhere((x) => x.cleLocale == local.cleLocale);
      // Realtime a pu livrer ce message avant la réponse de l'insert.
      if (!_messages.any((x) => x.id == enregistre.id)) _messages.add(enregistre);
      _messages.sort(Message.comparer);
    } on ChatException catch (e) {
      debugPrint('[7.2] envoi : $e');
      final i = _messages.indexWhere((x) => x.cleLocale == local.cleLocale);
      if (i >= 0) _messages[i] = _messages[i].avecEtat(EtatEnvoi.echec);
    }
    _notifier();
  }

  /// Séparateurs de jour et bulles, du plus ANCIEN au plus récent.
  List<ElementDiscussion> elements() {
    final maintenant = _horloge();
    final resultat = <ElementDiscussion>[];
    DateTime? jourPrecedent;
    for (final m in _messages) {
      final jour = DateTime(m.dateEnvoi.year, m.dateEnvoi.month, m.dateEnvoi.day);
      if (jour != jourPrecedent) {
        resultat.add(SeparateurJour(formaterJourDiscussion(m.dateEnvoi, maintenant)));
        jourPrecedent = jour;
      }
      resultat.add(BulleMessage(m, deMoi: m.idExpediteur == moi));
    }
    return resultat;
  }

  void _notifier() {
    if (!_detruit) notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    _abonnement?.cancel();
    super.dispose();
  }
}
