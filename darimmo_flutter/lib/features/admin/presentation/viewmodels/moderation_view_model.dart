// =====================================================================
// DarImmo - [9.2] État de l'onglet « En attente » (maquette A7)
// Tâche du membre A, réalisée par le membre C.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';

/// Motifs proposés en un geste (le texte reste modifiable).
const motifsRapides = [
  'Photos insuffisantes : ajoutez au moins 3 photos des pièces.',
  'Prix incohérent avec le bien décrit.',
  'Annonce en double.',
  'Description incomplète ou trompeuse.',
];

/// Longueur minimale du motif (il est envoyé à l'annonceur).
const motifMinimum = 10;

String? validerMotif(String? motif) {
  final m = (motif ?? '').trim();
  if (m.isEmpty) return 'Le motif est obligatoire : il est envoyé à l’annonceur.';
  if (m.length < motifMinimum) return 'Motif trop court ($motifMinimum caractères minimum).';
  if (m.length > 500) return 'Motif trop long (500 caractères maximum).';
  return null;
}

class ModerationViewModel extends ChangeNotifier {
  ModerationViewModel(this.repository);

  final ModerationRepository repository;

  List<AnnonceAModerer> annonces = const [];
  bool chargement = false;
  String? erreur;

  final _enCours = <String>{};
  bool enCours(String id) => _enCours.contains(id);

  bool _ferme = false;

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    _notifier();
    try {
      annonces = await repository.enAttente();
    } on ModerationException catch (e) {
      erreur = e.message;
    }
    chargement = false;
    _notifier();
  }

  /// Renvoie un message d'erreur, ou null si c'est fait (l'annonce quitte la liste).
  Future<String?> valider(String id) => _traiter(id, () => repository.valider(id));

  Future<String?> rejeter(String id, String motif) {
    final erreurMotif = validerMotif(motif);
    if (erreurMotif != null) return Future.value(erreurMotif);
    return _traiter(id, () => repository.rejeter(id, motif));
  }

  Future<String?> _traiter(String id, Future<void> Function() action) async {
    if (_enCours.contains(id)) return null;
    _enCours.add(id);
    _notifier();
    try {
      await action();
      annonces = [for (final a in annonces) if (a.id != id) a];
      return null;
    } on ModerationException catch (e) {
      if (e.dejaTraitee) annonces = [for (final a in annonces) if (a.id != id) a];
      return e.message;
    } finally {
      _enCours.remove(id);
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
