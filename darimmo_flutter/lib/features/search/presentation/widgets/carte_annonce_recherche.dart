// =====================================================================
// DarImmo - [3.1] Carte d'une annonce dans la liste de l'accueil (maquette B1)
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Critère 3.1 : photo, titre, prix, ville et surface.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';

/// « il y a 2 h », « hier », « il y a 3 j », puis la date.
String formaterAnciennete(DateTime date, DateTime maintenant) {
  final d = maintenant.difference(date.toLocal());
  if (d.inMinutes < 1) return 'à l’instant';
  if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
  if (d.inHours < 24) return 'il y a ${d.inHours} h';
  if (d.inDays == 1) return 'hier';
  if (d.inDays < 7) return 'il y a ${d.inDays} j';
  final l = date.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

/// « 950 DT/mois » ou « 385 000 DT ».
String formaterPrixAnnonce(AnnonceRecherche a) =>
    '${formaterPrix(a.prix)} ${a.typeOffre == TypeOffre.location ? 'DT/mois' : 'DT'}';

class CarteAnnonceRecherche extends StatelessWidget {
  const CarteAnnonceRecherche({super.key, required this.annonce, required this.onTap, required this.maintenant});

  final AnnonceRecherche annonce;
  final VoidCallback onTap;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final offre = a.typeOffre == TypeOffre.vente ? 'VENTE' : 'LOCATION';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DarColors.surface,
        border: Border.all(color: DarColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x0F0B1220), blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 188,
              child: Stack(fit: StackFit.expand, children: [
                _Photo(url: a.photoCouverture, type: a.typeBien),
                Positioned(top: 12, left: 12, child: _Pastille(texte: offre)),
                if (a.photos.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _Pastille(texte: '1/${a.photos.length}', icone: Icons.photo_outlined, sombre: true),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('${a.typeBien.libelle.toUpperCase()} · $offre',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800, color: DarColors.accent, letterSpacing: 0.8)),
                  ),
                  Text(formaterAnciennete(a.dateCreation, maintenant),
                      style: const TextStyle(fontSize: 12, color: DarColors.muted)),
                ]),
                const SizedBox(height: 6),
                Text(a.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DarColors.text)),
                if (a.ville != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 14, color: DarColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(a.ville!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: DarColors.muted, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ],
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: DarColors.border)),
                Row(children: [
                  Expanded(
                    child: Text(formaterPrixAnnonce(a),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: DarColors.primary)),
                  ),
                  if (a.surface != null) _Caracteristique(icone: Icons.square_foot, texte: '${formaterPrix(a.surface!)} m²'),
                  if (a.libelleTaille case final taille?) ...[
                    const SizedBox(width: 12),
                    _Caracteristique(icone: Icons.bed_outlined, texte: taille),
                  ],
                ]),
              ]),
            ),
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
        size: 48,
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

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte, this.icone, this.sombre = false});
  final String texte;
  final IconData? icone;
  final bool sombre;

  @override
  Widget build(BuildContext context) {
    final couleur = sombre ? Colors.white : DarColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sombre ? const Color(0xA60B1220) : DarColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 13, color: couleur), const SizedBox(width: 4)],
        Text(texte, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: couleur, letterSpacing: 0.5)),
      ]),
    );
  }
}

class _Caracteristique extends StatelessWidget {
  const _Caracteristique({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 16, color: DarColors.text2),
        const SizedBox(width: 4),
        Text(texte, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DarColors.text2)),
      ]);
}
