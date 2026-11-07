// =====================================================================
// DarImmo - Carte des annonces : écran de départ (squelette 1.6)
// Membre B : 4.1 Voir les annonces sur une carte · 4.2 Voir les biens autour de moi
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class CartePage extends StatelessWidget {
  const CartePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Carte des annonces',
      stories: '4.1 Voir les annonces sur une carte · 4.2 Voir les biens autour de moi',
      responsable: 'Membre B',
      icone: Icons.map_outlined,
      description: 'Composant de carte partagé : core/carte/carte_darimmo.dart (OpenStreetMap). Position : core/location/localisation.dart. Fonction SQL annonces_autour(lat, lng, rayon) déjà prête.',
    );
  }
}
