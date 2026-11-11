// =====================================================================
// DarImmo - Détail de l'annonce : écran de départ (squelette 1.6)
// Membre B : 3.3 Consulter le détail d'une annonce · 3.4 Signaler
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
//
// [7.1] Bouton « Contacter » (membre C) : déjà prêt. Le placer où l'on veut
// (en général dans la barre du bas) avec :
//     boutonContacter(annonce.idAnnonceur)
// Il gère tout seul la conversation, le visiteur sans compte et le cas
// « c'est mon annonce » (idAnnonceur = utilisateur connecté).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class DetailAnnoncePage extends StatelessWidget {
  const DetailAnnoncePage({super.key, required this.idAnnonce, required this.boutonContacter});
  final String idAnnonce;

  /// [7.1] Construit le bouton « Contacter » ; [idAnnonceur] (colonne
  /// annonces.id_annonceur) sert à le désactiver sur ses propres annonces.
  final Widget Function(String? idAnnonceur) boutonContacter;

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Détail de l’annonce',
      stories: '3.3 Consulter le détail d’une annonce · 3.4 Signaler',
      enfant: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Pour le développement : identifiant reçu par la route /annonces/:id
        Text('id = $idAnnonce', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // En attendant la 3.3, l'annonceur n'est pas connu ici : la fonction
        // SQL refusera quand même « se contacter soi-même ».
        boutonContacter(null),
      ]),
      responsable: 'Membre B',
      icone: Icons.article_outlined,
      description: 'Galerie de photos, prix, caractéristiques, carte. Le bouton « Contacter » (7.1, membre C) '
          'est déjà prêt : boutonContacter(annonce.idAnnonceur).',
    );
  }
}
