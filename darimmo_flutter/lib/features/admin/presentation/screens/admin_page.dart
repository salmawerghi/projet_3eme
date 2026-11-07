// =====================================================================
// DarImmo - Administration : écran de départ (squelette 1.6)
// Membre A : 9.1 Rôle admin · 9.2 Valider / rejeter · 9.3 Bloquer · 9.4 Signalements
// Remplacer le contenu de build() par le vrai écran ; la route existe déjà
// dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/bientot_disponible.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BientotDisponible(
      titre: 'Administration',
      stories: '9.1 Rôle admin · 9.2 Valider / rejeter · 9.3 Bloquer · 9.4 Signalements',
      responsable: 'Membre A',
      icone: Icons.shield_outlined,
      description: 'Fonctions SQL is_admin() et est_bloque() déjà prêtes ; le trigger annonces_statut autorise l\'admin à publier, rejeter (motif obligatoire) ou masquer.',
    );
  }
}
