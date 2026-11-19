// =====================================================================
// DarImmo - Espace administrateur « Modération » (maquettes A7, A8)
// Tâches du membre A, réalisées par le membre C.
//
// [9.1] Écran réservé à l'admin : le routeur renvoie les autres comptes
//       vers l'accueil, et le lien du profil n'est visible que pour lui.
// [9.2] Onglet « En attente » : valider, ou rejeter avec motif obligatoire.
//       L'annonceur est notifié par la base (8.2, send-push).
// [9.4] Onglet « Signalements » : masquer l'annonce ou classer sans suite.
// [9.3] Onglet « Comptes » : à venir.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/bientot_disponible.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';
import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/moderation_view_model.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/signalements_view_model.dart';
import 'package:darimmo/features/admin/presentation/widgets/carte_moderation.dart';
import 'package:darimmo/features/admin/presentation/widgets/carte_signalement.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.moderation,
    required this.onOuvrirAnnonce,
    this.maintenant,
  });

  final ModerationRepository moderation;
  final void Function(BuildContext context, String idAnnonce) onOuvrirAnnonce;

  /// Heure de référence pour « il y a 3 h » (fixée dans les tests).
  final DateTime Function()? maintenant;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final _vm = ModerationViewModel(widget.moderation)..charger();
  late final _signalements = SignalementsViewModel(widget.moderation)..charger();

  @override
  void dispose() {
    _vm.dispose();
    _signalements.dispose();
    super.dispose();
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _valider(String id, String titre) async {
    final erreur = await _vm.valider(id);
    if (mounted) _message(erreur ?? '« $titre » est publiée. L’annonceur est prévenu.');
  }

  Future<bool> _rejeter(String id, String titre, String motif) async {
    final erreur = await _vm.rejeter(id, motif);
    if (mounted) _message(erreur ?? '« $titre » est rejetée. L’annonceur est prévenu.');
    return erreur == null;
  }

  Future<void> _masquer(AnnonceSignalee a) async {
    final erreur = await _signalements.masquer(a);
    if (mounted) _message(erreur ?? '« ${a.titre} » est masquée. L’annonceur est prévenu.');
  }

  Future<void> _classer(AnnonceSignalee a) async {
    final erreur = await _signalements.classer(a);
    if (mounted) _message(erreur ?? 'Signalement classé sans suite : « ${a.titre} » reste en ligne.');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Modération', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('Espace administrateur', style: TextStyle(fontSize: 13, color: DarColors.muted)),
          ]),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.shield_outlined, color: DarColors.accent),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (_, _) => Text(_vm.chargement && _vm.annonces.isEmpty
                    ? 'En attente'
                    : 'En attente · ${_vm.annonces.length}'),
              ),
            ),
            Tab(
              child: ListenableBuilder(
                listenable: _signalements,
                builder: (_, _) => Text(_signalements.chargement && _signalements.annonces.isEmpty
                    ? 'Signalements'
                    : 'Signalements · ${_signalements.total}'),
              ),
            ),
            const Tab(text: 'Comptes'),
          ]),
        ),
        body: TabBarView(children: [
          ListenableBuilder(listenable: _vm, builder: (context, _) => _enAttente()),
          ListenableBuilder(listenable: _signalements, builder: (context, _) => _listeSignalements()),
          const BientotDisponible(
            titre: 'Comptes',
            stories: '9.3 Bloquer ou débloquer un compte',
            responsable: 'Membre A',
            icone: Icons.person_off_outlined,
            avecAppBar: false,
          ),
        ]),
      ),
    );
  }

  Widget _enAttente() {
    final annonces = _vm.annonces;
    if (_vm.chargement && annonces.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_vm.erreur != null && annonces.isEmpty) {
      return _Message(
        icone: Icons.wifi_off,
        texte: _vm.erreur!,
        bouton: FilledButton.icon(onPressed: _vm.charger, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      );
    }
    if (annonces.isEmpty) {
      return RefreshIndicator(
        onRefresh: _vm.charger,
        child: ListView(children: const [
          SizedBox(height: 80),
          _Message(icone: Icons.task_alt, texte: 'Aucune annonce en attente. Tout est à jour !'),
        ]),
      );
    }
    final maintenant = (widget.maintenant ?? DateTime.now)();
    return RefreshIndicator(
      onRefresh: _vm.charger,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: annonces.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Text('Les plus anciennes d’abord',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted));
          }
          final a = annonces[i - 1];
          return CarteModeration(
            key: ValueKey(a.id),
            annonce: a,
            maintenant: maintenant,
            enCours: _vm.enCours(a.id),
            onOuvrir: () => widget.onOuvrirAnnonce(context, a.id),
            onValider: () => _valider(a.id, a.titre),
            onRejeter: (motif) => _rejeter(a.id, a.titre, motif),
          );
        },
      ),
    );
  }
}

extension on _AdminPageState {
  Widget _listeSignalements() {
    final vm = _signalements;
    final annonces = vm.annonces;
    if (vm.chargement && annonces.isEmpty) return const Center(child: CircularProgressIndicator());
    if (vm.erreur != null && annonces.isEmpty) {
      return _Message(
        icone: Icons.wifi_off,
        texte: vm.erreur!,
        bouton: FilledButton.icon(onPressed: vm.charger, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      );
    }
    if (annonces.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.charger,
        child: ListView(children: const [
          SizedBox(height: 80),
          _Message(icone: Icons.verified_user_outlined, texte: 'Aucun signalement à traiter.'),
        ]),
      );
    }
    final maintenant = (widget.maintenant ?? DateTime.now)();
    return RefreshIndicator(
      onRefresh: vm.charger,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: annonces.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final a = annonces[i];
          return CarteSignalement(
            key: ValueKey(a.idAnnonce),
            annonce: a,
            maintenant: maintenant,
            enCours: vm.enCours(a.idAnnonce),
            onOuvrir: () => widget.onOuvrirAnnonce(context, a.idAnnonce),
            onMasquer: () => _masquer(a),
            onClasser: () => _classer(a),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.texte, this.bouton});
  final IconData icone;
  final String texte;
  final Widget? bouton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 48, color: DarColors.muted),
          const SizedBox(height: 14),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: DarColors.text2, height: 1.4)),
          if (bouton != null) ...[const SizedBox(height: 20), bouton!],
        ]),
      ),
    );
  }
}
