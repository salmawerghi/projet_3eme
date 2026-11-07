// =====================================================================
// DarImmo - [6.1] Écran « Annonce envoyée » (maquette C4)
// Membre C
// Montre que l'annonce est enregistrée au statut « en attente de validation ».
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

/// 385000 -> « 385 000 » ; 98.5 -> « 98,5 »
String formaterPrix(double v) {
  final entier = v.truncate();
  final groupes = entier.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  final dec = ((v - entier) * 100).round();
  return dec == 0 ? groupes : '$groupes,${dec.toString().padLeft(2, '0')}';
}

class AnnonceEnvoyeePage extends StatelessWidget {
  const AnnonceEnvoyeePage({super.key, required this.annonce});
  final Annonce annonce;

  @override
  Widget build(BuildContext context) {
    final h = annonce.dateCreation;
    final heure = '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
    final unite = annonce.typeOffre == TypeOffre.location ? 'DT/mois' : 'DT';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Center(
              child: Container(
                width: 108, height: 108,
                decoration: const BoxDecoration(color: DarColors.successSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 70, height: 70,
                  decoration: const BoxDecoration(color: DarColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Annonce envoyée !',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Un administrateur va vérifier votre annonce. Elle sera visible par tous dès qu’elle sera validée.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.45, color: DarColors.text2),
            ),
            const SizedBox(height: 22),
            _Carte(children: [
              Row(children: [
                Expanded(
                  child: Text('${annonce.typeBien.libelle.toUpperCase()} · '
                      '${annonce.typeOffre == TypeOffre.vente ? 'VENTE' : 'LOCATION'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DarColors.accent, letterSpacing: .7)),
                ),
                const _BadgeEnAttente(),
              ]),
              const SizedBox(height: 8),
              Text(annonce.titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_outlined, size: 15, color: DarColors.muted),
                const SizedBox(width: 4),
                Text(annonce.ville, style: const TextStyle(fontSize: 13, color: DarColors.muted)),
              ]),
              const SizedBox(height: 8),
              Text('${formaterPrix(annonce.prix)} $unite',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: DarColors.primary)),
            ]),
            const SizedBox(height: 14),
            _Carte(children: [
              _Etape(etat: _EtatEtape.fait, titre: 'Annonce créée', sous: 'Aujourd’hui à $heure'),
              const _Etape(etat: _EtatEtape.enCours, titre: 'Vérification par un administrateur', sous: 'Statut « en attente »'),
              const _Etape(etat: _EtatEtape.aVenir, titre: 'Publication', sous: 'Visible par tous les utilisateurs', derniere: true),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Terminer'),
          ),
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DarColors.surface,
          border: Border.all(color: DarColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _BadgeEnAttente extends StatelessWidget {
  const _BadgeEnAttente();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(color: DarColors.warningSoft, borderRadius: BorderRadius.circular(13)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule, size: 13, color: DarColors.warning),
          SizedBox(width: 5),
          Text('En attente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DarColors.warning)),
        ]),
      );
}

enum _EtatEtape { fait, enCours, aVenir }

class _Etape extends StatelessWidget {
  const _Etape({required this.etat, required this.titre, required this.sous, this.derniere = false});
  final _EtatEtape etat;
  final String titre;
  final String sous;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final (couleur, fond, icone) = switch (etat) {
      _EtatEtape.fait => (DarColors.success, DarColors.successSoft, Icons.check),
      _EtatEtape.enCours => (DarColors.warning, DarColors.warningSoft, Icons.schedule),
      _EtatEtape.aVenir => (DarColors.muted, DarColors.surface2, Icons.radio_button_unchecked),
    };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
            child: Icon(icone, size: 16, color: couleur),
          ),
          if (!derniere) Expanded(child: Container(width: 2, color: DarColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: derniere ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: etat == _EtatEtape.aVenir ? DarColors.muted : DarColors.text)),
              Text(sous, style: const TextStyle(fontSize: 12, color: DarColors.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}
