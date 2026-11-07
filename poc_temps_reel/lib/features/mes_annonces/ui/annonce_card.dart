// =====================================================================
// DarImmo - [6.3] [6.5] Carte d'une annonce dans « Mes annonces » (maquette C5)
// Membre C
//
// Vignette, badge de statut, titre, prix, ville, et le motif de l'admin
// pour une annonce rejetée ou masquée (critère de la 6.5).
// Boutons d'action (6.3) : Modifier (ou « Modifier et renvoyer » si rejetée),
// Marquer vendue / louée (si publiée), Supprimer (toujours).
// =====================================================================
import 'package:flutter/material.dart';

import '../../../core/darimmo_theme.dart';
import '../../publish/models/annonce.dart';
import '../../publish/ui/annonce_envoyee_page.dart' show formaterPrix;
import '../models/mon_annonce.dart';

class AnnonceCard extends StatelessWidget {
  const AnnonceCard({
    super.key,
    required this.annonce,
    this.enCours = false,
    this.onModifier,
    this.onConclure,
    this.onSupprimer,
  });
  final MonAnnonce annonce;

  /// Une action est en cours sur cette annonce : boutons désactivés.
  final bool enCours;
  final VoidCallback? onModifier;
  final VoidCallback? onConclure;
  final VoidCallback? onSupprimer;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final unite = a.typeOffre == TypeOffre.location ? 'DT/mois' : 'DT';
    final details = [
      if (a.typeBien != null) a.typeBien!.libelle,
      if (a.ville != null) a.ville!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarColors.surface,
        border: Border.all(color: DarColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _Vignette(url: a.photoUrl, type: a.typeBien),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StatutBadge(statut: a.statut),
              const SizedBox(height: 6),
              Text(a.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: DarColors.muted)),
              ],
              const SizedBox(height: 4),
              Text(a.prix == null ? 'Prix non renseigné' : '${formaterPrix(a.prix!)} $unite',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.primary)),
            ]),
          ),
        ]),
        if (_afficheMotif) ...[
          const SizedBox(height: 12),
          _Motif(statut: a.statut, texte: a.motif!),
        ],
        if (_actions(context) case final actions?) ...[
          const SizedBox(height: 12),
          actions,
        ],
      ]),
    );
  }

  /// Rangée de boutons (maquette C5), ou null s'il n'y a aucune action.
  Widget? _actions(BuildContext context) {
    final a = annonce;
    final modifier = onModifier != null && a.peutModifier;
    final conclure = onConclure != null && a.peutMarquerVendue;
    final supprimer = onSupprimer != null;
    if (!modifier && !conclure && !supprimer) return null;

    const taille = Size(0, 42);
    const forme = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)));
    const texte = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);
    final rejetee = a.statut == StatutAnnonce.rejetee;

    return Row(children: [
      if (modifier)
        Expanded(
          child: rejetee
              ? FilledButton.tonalIcon(
                  onPressed: enCours ? null : onModifier,
                  style: FilledButton.styleFrom(
                      minimumSize: taille, shape: forme, textStyle: texte,
                      backgroundColor: DarColors.primarySoft, foregroundColor: DarColors.primary),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Modifier et renvoyer', overflow: TextOverflow.ellipsis),
                )
              : OutlinedButton.icon(
                  onPressed: enCours ? null : onModifier,
                  style: OutlinedButton.styleFrom(
                      minimumSize: taille, shape: forme, textStyle: texte, padding: const EdgeInsets.symmetric(horizontal: 10)),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Modifier', overflow: TextOverflow.ellipsis),
                ),
        ),
      if (conclure) ...[
        if (modifier) const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: enCours ? null : onConclure,
            style: FilledButton.styleFrom(
                minimumSize: taille, shape: forme, textStyle: texte, padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: DarColors.primarySoft, foregroundColor: DarColors.primary),
            icon: Icon(a.statutConclu == StatutAnnonce.louee ? Icons.key_outlined : Icons.sell_outlined, size: 17),
            label: Text(a.statutConclu == StatutAnnonce.louee ? 'Marquer louée' : 'Marquer vendue',
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      if (supprimer) ...[
        if (modifier || conclure) const SizedBox(width: 8) else const Spacer(),
        IconButton(
          tooltip: 'Supprimer',
          onPressed: enCours ? null : onSupprimer,
          style: IconButton.styleFrom(
            fixedSize: const Size(42, 42),
            backgroundColor: DarColors.dangerSoft,
            foregroundColor: DarColors.danger,
            shape: forme,
          ),
          icon: enCours
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.delete_outline, size: 19),
        ),
      ],
    ]);
  }

  bool get _afficheMotif =>
      (annonce.statut == StatutAnnonce.rejetee || annonce.statut == StatutAnnonce.masquee) &&
      (annonce.motif?.trim().isNotEmpty ?? false);
}

/// Badge coloré du statut (couleurs et icônes de la maquette v3).
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut});
  final StatutAnnonce statut;

  @override
  Widget build(BuildContext context) {
    final (couleur, fond, icone) = switch (statut) {
      StatutAnnonce.brouillon => (DarColors.text2, DarColors.surface2, Icons.edit_outlined),
      StatutAnnonce.enAttente => (DarColors.warning, DarColors.warningSoft, Icons.schedule),
      StatutAnnonce.publiee => (DarColors.success, DarColors.successSoft, Icons.check_circle_outline),
      StatutAnnonce.rejetee => (DarColors.danger, DarColors.dangerSoft, Icons.close),
      StatutAnnonce.vendue => (DarColors.primary, DarColors.primarySoft, Icons.sell_outlined),
      StatutAnnonce.louee => (DarColors.primary, DarColors.primarySoft, Icons.key_outlined),
      StatutAnnonce.masquee => (DarColors.text2, DarColors.surface2, Icons.visibility_off_outlined),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(13)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 13, color: couleur),
        const SizedBox(width: 5),
        Text(statut.libelle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: couleur)),
      ]),
    );
  }
}

class _Motif extends StatelessWidget {
  const _Motif({required this.statut, required this.texte});
  final StatutAnnonce statut;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final rejet = statut == StatutAnnonce.rejetee;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rejet ? DarColors.dangerSoft : DarColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rejet ? 'Motif du rejet' : 'Motif du masquage',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rejet ? DarColors.danger : DarColors.text2)),
        const SizedBox(height: 4),
        Text(texte, style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: DarColors.text)),
      ]),
    );
  }
}

/// Première photo de l'annonce, ou une icône du type de bien en attendant la 6.2.
class _Vignette extends StatelessWidget {
  const _Vignette({required this.url, required this.type});
  final String? url;
  final TypeBien? type;

  static const _icones = {
    TypeBien.appartement: Icons.apartment_rounded,
    TypeBien.villa: Icons.villa_outlined,
    TypeBien.terrain: Icons.landscape_outlined,
    TypeBien.local: Icons.storefront_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icone = Icon(_icones[type] ?? Icons.home_outlined, size: 30, color: DarColors.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 78,
        height: 78,
        color: DarColors.primarySoft,
        alignment: Alignment.center,
        child: url == null
            ? icone
            : Image.network(url!, width: 78, height: 78, fit: BoxFit.cover, errorBuilder: (_, _, _) => icone),
      ),
    );
  }
}
