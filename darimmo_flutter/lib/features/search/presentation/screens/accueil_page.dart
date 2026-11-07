// =====================================================================
// DarImmo - Accueil : écran de départ (squelette 1.6)
// Membre B : 3.1 Voir la liste des annonces · 3.2 Filtrer les annonces
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Accueil',
      stories: '3.1 Voir la liste des annonces · 3.2 Filtrer les annonces',
      responsable: 'Membre B',
      icone: Icons.search,
      description: 'Liste paginée des annonces publiées (maquettes B1-B2). Toucher une annonce : context.push(\'/annonces/<id>\') ouvre le détail (3.3).',
      avecAppBar: false,
    );
  }
}
