// =====================================================================
// DarImmo - Favoris : écran de départ (squelette 1.6)
// Membre B : 5.1 Ajouter / retirer un favori · 5.2 Consulter mes favoris
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class FavorisPage extends StatelessWidget {
  const FavorisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Favoris',
      stories: '5.1 Ajouter / retirer un favori · 5.2 Consulter mes favoris',
      responsable: 'Membre B',
      icone: Icons.favorite_border,
      description: 'Table public.favoris (RLS : chacun les siens) déjà prête.',
      avecAppBar: false,
    );
  }
}
