// =====================================================================
// DarImmo - [7.3] ViewModel de l'écran « Messages » (Provider)
// Membre C
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';

class ConversationsViewModel extends ChangeNotifier {
  ConversationsViewModel(this._repository);
  final ConversationsRepository _repository;

  List<ResumeConversation> _toutes = const [];
  bool chargement = false;
  String? erreur;
  String recherche = '';
  StreamSubscription<void>? _abonnement;

  /// Vrai tant que le premier chargement n'a pas réussi.
  bool get jamaisCharge => _toutes.isEmpty && (chargement || erreur != null);
  int get total => _toutes.length;

  /// Filtrées par la recherche, triées de la plus récente à la plus ancienne
  /// (critère 7.3 ; la fonction SQL trie déjà, on le garantit ici aussi).
  List<ResumeConversation> get conversations =>
      _toutes.where((c) => c.correspond(recherche)).toList()
        ..sort((a, b) => b.dateDernierMessage.compareTo(a.dateDernierMessage));

  int get totalNonLus => _toutes.fold(0, (s, c) => s + c.nonLus);

  /// « 2 messages non lus » sous le titre (maquette C7).
  String get resume => switch (totalNonLus) {
        0 when total == 0 => 'Aucune conversation',
        0 => 'Tout est lu',
        1 => '1 message non lu',
        final n => '$n messages non lus',
      };

  /// Premier chargement + écoute des changements en direct.
  Future<void> demarrer() async {
    _abonnement ??= _repository.changements().listen((_) => charger(silencieux: true));
    await charger();
  }

  /// [silencieux] : rafraîchissement en arrière-plan, sans indicateur ni effacer la liste.
  Future<void> charger({bool silencieux = false}) async {
    if (!silencieux) {
      chargement = true;
      erreur = null;
      notifyListeners();
    }
    try {
      _toutes = await _repository.lister();
      erreur = null;
    } on ConversationsException catch (e) {
      erreur = e.message;
    } finally {
      chargement = false;
      if (!_detruit) notifyListeners();
    }
  }

  void chercher(String texte) {
    recherche = texte;
    notifyListeners();
  }

  bool _detruit = false;

  @override
  void dispose() {
    _detruit = true;
    _abonnement?.cancel();
    super.dispose();
  }
}
