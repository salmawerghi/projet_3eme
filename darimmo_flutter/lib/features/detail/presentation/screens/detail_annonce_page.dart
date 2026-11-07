// =====================================================================
// DarImmo - Détail de l'annonce : écran de départ (squelette 1.6)
// Membre B : 3.3 Consulter le détail d'une annonce · 3.4 Signaler
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class DetailAnnoncePage extends StatelessWidget {
  const DetailAnnoncePage({super.key, required this.idAnnonce});
  final String idAnnonce;

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Détail de l’annonce',
      stories: '3.3 Consulter le détail d’une annonce · 3.4 Signaler',
      // Pour le développement : identifiant reçu par la route /annonces/:id
      enfant: Text('id = $idAnnonce', textAlign: TextAlign.center),
      responsable: 'Membre B',
      icone: Icons.article_outlined,
      description: 'Galerie de photos, prix, caractéristiques, carte. Le bouton « Contacter » (7.1, membre C) appellera la fonction SQL ouvrir_conversation puis context.push(\'/messages/<id>\').',
    );
  }
}
