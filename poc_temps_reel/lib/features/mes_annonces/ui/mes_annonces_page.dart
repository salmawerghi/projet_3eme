// =====================================================================
// DarImmo - [6.3] [6.5] Écran « Mes annonces » (maquette C5)
// Membre C
//
// Critères d'acceptation couverts à cette étape :
//   - 6.3 : liste « Mes annonces » avec statut
//   - 6.5 : statut en attente, publiée, rejetée, vendue / louée ou masquée,
//           motif affiché en cas de rejet ou de masquage
//   - 6.3 : modifier (formulaire de la 6.1 pré-rempli), marquer vendue / louée,
//           supprimer avec confirmation (maquette C6)
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/darimmo_theme.dart';
import '../../publish/models/annonce.dart';
import '../data/mes_annonces_repository.dart';
import '../mes_annonces_view_model.dart';
import '../models/mon_annonce.dart';
import 'annonce_card.dart';

/// Ouvre le formulaire de la 6.1 en mode modification ; renvoie l'annonce
/// enregistrée, ou null si l'utilisateur a fermé sans enregistrer.
typedef OuvrirModification = Future<Annonce?> Function(BuildContext context, EditionAnnonce edition);

class MesAnnoncesPage extends StatelessWidget {
  const MesAnnoncesPage({super.key, required this.repository, this.onPublier, this.onModifier});
  final MesAnnoncesRepository repository;

  /// Ouvre le formulaire de la 6.1 (bouton « + »). La liste est rechargée au retour.
  final Future<void> Function(BuildContext context)? onPublier;

  /// Ouvre le formulaire de la 6.1 pré-rempli (bouton « Modifier »).
  final OuvrirModification? onModifier;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MesAnnoncesViewModel(repository)..charger(),
      child: _Contenu(onPublier: onPublier, onModifier: onModifier),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({this.onPublier, this.onModifier});
  final Future<void> Function(BuildContext context)? onPublier;
  final OuvrirModification? onModifier;

  // ------------------------------------------------------------------
  // Actions (6.3)
  // ------------------------------------------------------------------
  Future<void> _modifier(BuildContext context, MonAnnonce a) async {
    final edition = a.versEdition();
    if (edition == null || onModifier == null) return;
    final vm = context.read<MesAnnoncesViewModel>();
    final resultat = await onModifier!(context, edition);
    // Toujours recharger : l'étape 1 a pu enregistrer des changements (et des
    // photos) même si l'utilisateur a quitté avant la fin du parcours.
    await vm.charger();
    if (resultat == null || !context.mounted) return;
    final repasseEnAttente = resultat.statut == StatutAnnonce.enAttente && a.statut != StatutAnnonce.enAttente;
    _info(context, repasseEnAttente
        ? 'Annonce modifiée : elle est de nouveau en attente de validation.'
        : 'Modifications enregistrées.');
  }

  Future<void> _conclure(BuildContext context, MonAnnonce a) async {
    final louee = a.statutConclu == StatutAnnonce.louee;
    final ok = await _confirmer(
      context,
      icone: louee ? Icons.key_outlined : Icons.sell_outlined,
      danger: false,
      titre: louee ? 'Marquer comme louée ?' : 'Marquer comme vendue ?',
      texte: '« ${a.titre} » ne sera plus proposée dans les recherches. '
          'Ce changement est définitif.',
      action: louee ? 'Marquer louée' : 'Marquer vendue',
    );
    if (!ok || !context.mounted) return;
    final erreur = await context.read<MesAnnoncesViewModel>().marquerConclue(a);
    if (context.mounted) {
      _info(context, erreur ?? (louee ? 'Annonce marquée louée.' : 'Annonce marquée vendue.'), erreur: erreur != null);
    }
  }

  Future<void> _supprimer(BuildContext context, MonAnnonce a) async {
    final photos = switch (a.nbPhotos) {
      0 => '',
      1 => ' et sa photo',
      final n => ' et ses $n photos',
    };
    final ok = await _confirmer(
      context,
      icone: Icons.delete_outline,
      danger: true,
      titre: 'Supprimer cette annonce ?',
      texte: '« ${a.titre} »$photos ${a.nbPhotos == 0 ? 'sera supprimée' : 'seront supprimés'} définitivement. '
          'Les conversations liées restent accessibles.',
      action: 'Supprimer',
    );
    if (!ok || !context.mounted) return;
    final erreur = await context.read<MesAnnoncesViewModel>().supprimer(a);
    if (context.mounted) _info(context, erreur ?? 'Annonce supprimée.', erreur: erreur != null);
  }

  void _info(BuildContext context, String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? DarColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MesAnnoncesViewModel>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mes annonces', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(vm.resume, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
        ]),
        actions: [
          if (onPublier != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton.filled(
                tooltip: 'Publier une annonce',
                onPressed: () async {
                  await onPublier!(context);
                  if (context.mounted) await context.read<MesAnnoncesViewModel>().charger();
                },
                icon: const Icon(Icons.add),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(onRefresh: vm.charger, child: _corps(context, vm)),
    );
  }

  Widget _corps(BuildContext context, MesAnnoncesViewModel vm) {
    // Premier chargement
    if (vm.jamaisCharge && vm.chargement) return const Center(child: CircularProgressIndicator());
    // Erreur sans aucune donnée à montrer
    if (vm.jamaisCharge && vm.erreur != null) {
      return _Message(
        icone: Icons.wifi_off_rounded,
        titre: 'Impossible de charger vos annonces',
        texte: vm.erreur!,
        bouton: OutlinedButton(onPressed: vm.charger, child: const Text('Réessayer')),
      );
    }
    if (vm.total == 0) {
      return const _Message(
        icone: Icons.home_work_outlined,
        titre: 'Aucune annonce pour l’instant',
        texte: 'Publiez votre premier bien : il apparaîtra ici avec son statut de validation.',
      );
    }

    final annonces = vm.annonces;
    return ListView(
      // AlwaysScrollable : le « tirer pour rafraîchir » marche même avec peu d'annonces.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(children: [
            for (final f in vm.filtresVisibles)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${f.libelle} · ${vm.compter(f)}'),
                  selected: vm.filtre == f,
                  showCheckmark: false,
                  onSelected: (_) => vm.choisirFiltre(f),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: vm.filtre == f ? Colors.white : DarColors.text2,
                  ),
                  selectedColor: DarColors.primary,
                  backgroundColor: DarColors.surface,
                  side: BorderSide(color: vm.filtre == f ? DarColors.primary : DarColors.border),
                  shape: const StadiumBorder(),
                ),
              ),
          ]),
        ),
        if (vm.erreur != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(vm.erreur!, style: const TextStyle(color: DarColors.danger, fontWeight: FontWeight.w600)),
          ),
        for (final a in annonces)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AnnonceCard(
              key: ValueKey(a.id),
              annonce: a,
              enCours: vm.estEnCours(a),
              onModifier: onModifier == null ? null : () => _modifier(context, a),
              onConclure: () => _conclure(context, a),
              onSupprimer: () => _supprimer(context, a),
            ),
          ),
      ],
    );
  }
}

/// Boîte de confirmation (maquette C6). Renvoie true si l'utilisateur confirme.
Future<bool> _confirmer(
  BuildContext context, {
  required IconData icone,
  required bool danger,
  required String titre,
  required String texte,
  required String action,
}) async {
  final couleur = danger ? DarColors.danger : DarColors.primary;
  final reponse = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: danger ? DarColors.dangerSoft : DarColors.primarySoft,
            child: Icon(icone, size: 28, color: couleur),
          ),
          const SizedBox(height: 14),
          Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(texte,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.43, color: DarColors.text2)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: couleur),
                child: Text(action, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
  return reponse ?? false;
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.titre, required this.texte, this.bouton});
  final IconData icone;
  final String titre;
  final String texte;
  final Widget? bouton;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 24),
      children: [
        Icon(icone, size: 56, color: DarColors.muted),
        const SizedBox(height: 16),
        Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.45, color: DarColors.text2)),
        if (bouton != null) ...[const SizedBox(height: 20), bouton!],
      ],
    );
  }
}
