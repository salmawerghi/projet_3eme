// =====================================================================
// DarImmo - [9.4] État de l'onglet « Signalements » (maquette A8)
// Tâche du membre A, réalisée par le membre C.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';

class SignalementsViewModel extends ChangeNotifier {
  SignalementsViewModel(this.repository);

  final ModerationRepository repository;

  List<AnnonceSignalee> annonces = const [];
  bool chargement = false;
  String? erreur;

  final _enCours = <String>{};
  bool enCours(String idAnnonce) => _enCours.contains(idAnnonce);

  /// Nombre total de signalements en attente (titre de l'onglet).
  int get total => annonces.fold(0, (n, a) => n + a.signalements.length);

  bool _ferme = false;

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    _notifier();
    try {
      annonces = await repository.signalements();
    } on ModerationException catch (e) {
      erreur = e.message;
    }
    chargement = false;
    _notifier();
  }

  /// Renvoie un message d'erreur, ou null si c'est fait (l'annonce quitte la liste).
  Future<String?> masquer(AnnonceSignalee a) => _traiter(a, () => repository.masquer(a.idAnnonce, a.ids));

  Future<String?> classer(AnnonceSignalee a) => _traiter(a, () => repository.classer(a.ids));

  Future<String?> _traiter(AnnonceSignalee a, Future<void> Function() action) async {
    if (_enCours.contains(a.idAnnonce)) return null;
    _enCours.add(a.idAnnonce);
    _notifier();
    try {
      await action();
      annonces = [for (final x in annonces) if (x.idAnnonce != a.idAnnonce) x];
      return null;
    } on ModerationException catch (e) {
      return e.message;
    } finally {
      _enCours.remove(a.idAnnonce);
      _notifier();
    }
  }

  void _notifier() {
    if (!_ferme) notifyListeners();
  }

  @override
  void dispose() {
    _ferme = true;
    super.dispose();
  }
}
