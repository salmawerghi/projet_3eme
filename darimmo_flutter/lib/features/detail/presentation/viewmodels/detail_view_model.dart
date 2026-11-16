// =====================================================================
// DarImmo - [3.3] État de l'écran de détail : chargement, erreur, annonce
// Tâche du membre B, réalisée par le membre C.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/detail/data/models/annonce_detail.dart';
import 'package:darimmo/features/detail/data/repositories/detail_repository.dart';

class DetailViewModel extends ChangeNotifier {
  DetailViewModel({required this.repository, required this.idAnnonce});

  final DetailRepository repository;
  final String idAnnonce;

  AnnonceDetail? annonce;
  bool chargement = false;
  String? erreur;

  /// true : l'annonce n'existe plus → pas de bouton « Réessayer ».
  bool introuvable = false;

  bool _ferme = false;

  Future<void> charger() async {
    if (chargement) return;
    chargement = true;
    erreur = null;
    introuvable = false;
    notifyListeners();
    try {
      final a = await repository.charger(idAnnonce);
      if (_ferme) return;
      annonce = a;
    } on DetailException catch (e) {
      if (_ferme) return;
      erreur = e.message;
      introuvable = e.introuvable;
    }
    chargement = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ferme = true;
    super.dispose();
  }
}
