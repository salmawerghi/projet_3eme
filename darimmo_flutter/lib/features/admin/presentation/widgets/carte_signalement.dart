// =====================================================================
// DarImmo - [9.4] Carte d'une annonce signalée (maquette A8)
// Tâche du membre A, réalisée par le membre C.
//
// L'annonce (photo, titre, ville · prix, nombre de signalements), la liste
// des signalements (motif, auteur, date), puis « Classer » ou « Masquer
// l'annonce » (avec confirmation : l'annonce disparaît des recherches).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show StatutAnnonce, TypeBien;
import 'package:darimmo/features/search/presentation/widgets/carte_annonce_recherche.dart' show formaterAnciennete;

class CarteSignalement extends StatelessWidget {
  const CarteSignalement({
    super.key,
    required this.annonce,
    required this.maintenant,
    required this.enCours,
    required this.onOuvrir,
    required this.onMasquer,
    required this.onClasser,
  });

  final AnnonceSignalee annonce;
  final DateTime maintenant;
  final bool enCours;
  final VoidCallback onOuvrir;
  final VoidCallback onMasquer;
  final VoidCallback onClasser;

  Future<void> _confirmerMasquage(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masquer cette annonce ?'),
        content: Text(
          '« ${annonce.titre} » ne sera plus visible dans les recherches. '
          'L’annonceur sera prévenu par une notification.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: DarColors.danger),
            child: const Text('Masquer'),
          ),
        ],
      ),
    );
    if (ok == true) onMasquer();
  }

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final n = a.signalements.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarColors.danger, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: onOuvrir,
          borderRadius: BorderRadius.circular(14),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 64, height: 64, child: _Photo(url: a.photoCouverture, type: a.typeBien)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DarColors.dangerSoft, borderRadius: BorderRadius.circular(8)),
                  child: Text(n == 1 ? '1 SIGNALEMENT' : '$n SIGNALEMENTS',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DarColors.danger)),
                ),
                const SizedBox(height: 4),
                Text(a.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
                Text(
                  [a.resume, if (a.nomAnnonceur != null) a.nomAnnonceur!, if (a.statut != StatutAnnonce.publiee) 'non publiée']
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: DarColors.text2),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: DarColors.muted),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            for (final (i, s) in a.signalements.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.flag, size: 16, color: DarColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.precision != null ? '« ${s.precision} »' : s.categorie,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.text)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (s.precision != null) s.categorie,
                        s.nomAuteur ?? 'Utilisateur',
                        formaterAnciennete(s.date, maintenant),
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: DarColors.muted),
                    ),
                  ]),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: enCours ? null : onClasser,
              child: const Text('Classer sans suite'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: enCours ? null : () => _confirmerMasquage(context),
              style: FilledButton.styleFrom(backgroundColor: DarColors.danger),
              icon: enCours
                  ? const SizedBox.square(
                      dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.visibility_off_outlined),
              label: const Text('Masquer'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.type});
  final String? url;
  final TypeBien type;

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        switch (type) {
          TypeBien.villa => Icons.home_outlined,
          TypeBien.terrain => Icons.landscape_outlined,
          TypeBien.local => Icons.storefront_outlined,
          TypeBien.appartement => Icons.apartment_outlined,
        },
        size: 26,
        color: DarColors.primary,
      ),
    );
    if (url == null) return remplacement;
    return Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => remplacement);
  }
}
