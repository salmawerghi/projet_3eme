// =====================================================================
// DarImmo - [4.1] Aperçu d'une annonce en bas de la carte (maquette B3)
// Tâche du membre B, réalisée par le membre C.
//
// Critères 4.1 : « Toucher un marqueur affiche photo et prix » ;
//                « Toucher l'aperçu ouvre le détail ».
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/map/data/models/annonce_carte.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;

class ApercuAnnonceCarte extends StatelessWidget {
  const ApercuAnnonceCarte({super.key, required this.annonce, required this.onOuvrir});

  final AnnonceCarte annonce;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final offre = a.typeOffre == TypeOffre.vente ? 'Vente' : 'Location';
    return Material(
      key: const Key('apercu-annonce'),
      color: DarColors.surface,
      elevation: 6,
      shadowColor: const Color(0x550B1220),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 88, height: 88, child: _Photo(url: a.photoCouverture, type: a.typeBien)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(libellePrixComplet(a),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DarColors.primary)),
                const SizedBox(height: 2),
                Text(a.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DarColors.text)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 14, color: DarColors.muted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      [?a.ville, offre].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: DarColors.muted),
                    ),
                  ),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: DarColors.muted),
          ]),
        ),
      ),
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
        size: 32,
        color: DarColors.primary,
      ),
    );
    if (url == null) return remplacement;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => remplacement,
      loadingBuilder: (_, enfant, progression) => progression == null ? enfant : Container(color: DarColors.surface2),
    );
  }
}
