// =====================================================================
// DarImmo - [9.3] État de l'onglet « Comptes » : rechercher, bloquer
// Tâche du membre A, réalisée par le membre C.
//
// Sans recherche : la liste des comptes bloqués (pour les débloquer).
// La recherche part 400 ms après la dernière lettre tapée ; une réponse
// arrivée en retard (ancienne recherche) est ignorée.
// =====================================================================
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:darimmo/features/admin/data/models/compte_admin.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';

class ComptesViewModel extends ChangeNotifier {
  ComptesViewModel(this.repository, {this.delai = const Duration(milliseconds: 400)});

  final ModerationRepository repository;
  final Duration delai;

  String recherche = '';
  List<CompteAdmin> comptes = const [];
  bool chargement = false;
  String? erreur;

  final _enCours = <String>{};
  bool enCours(String id) => _enCours.contains(id);

  Timer? _minuteur;
  int _requete = 0;
  bool _ferme = false;

  bool get modeBloques => recherche.trim().isEmpty;

  void chercher(String texte) {
    recherche = texte;
    _minuteur?.cancel();
    _minuteur = Timer(delai, charger);
  }

  Future<void> charger() async {
    final numero = ++_requete;
    chargement = true;
    erreur = null;
    _notifier();
    try {
      final resultat = await repository.comptes(recherche);
      if (_ferme || numero != _requete) return;
      comptes = resultat;
    } on ModerationException catch (e) {
      if (_ferme || numero != _requete) return;
      erreur = e.message;
    }
    chargement = false;
    _notifier();
  }

  /// Renvoie un message d'erreur, ou null si c'est fait.
  Future<String?> basculerBlocage(CompteAdmin c) async {
    if (c.estAdmin) return 'Un compte administrateur ne peut pas être bloqué ici.';
    if (_enCours.contains(c.id)) return null;
    _enCours.add(c.id);
    _notifier();
    try {
      await repository.bloquer(c.id, bloque: !c.bloque);
      comptes = [for (final x in comptes) x.id == c.id ? x.avecBlocage(!c.bloque) : x];
      return null;
    } on ModerationException catch (e) {
      return e.message;
    } finally {
      _enCours.remove(c.id);
      _notifier();
    }
  }

  void _notifier() {
    if (!_ferme) notifyListeners();
  }

  @override
  void dispose() {
    _ferme = true;
    _minuteur?.cancel();
    super.dispose();
  }
}
