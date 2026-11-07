// =====================================================================
// DarImmo - Barre de navigation du bas (maquettes v3 : tabBar)
// Accueil · Favoris · [Publier] · Messages · Profil
//
// Chaque onglet garde son propre historique (StatefulShellRoute). « Publier »
// n'est pas un onglet : il ouvre le formulaire de publication par-dessus.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class NavigationPrincipale extends StatelessWidget {
  const NavigationPrincipale({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Onglets affichés -> branche du routeur (null = « Publier »).
  static const _branches = [0, 1, null, 2, 3];

  int get _selection => _branches.indexOf(shell.currentIndex);

  void _choisir(BuildContext context, int i) {
    final branche = _branches[i];
    if (branche == null) {
      context.push('/publier');
      return;
    }
    // Retoucher l'onglet actif revient à sa première page.
    shell.goBranch(branche, initialLocation: branche == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selection,
        onDestinationSelected: (i) => _choisir(context, i),
        backgroundColor: DarColors.surface,
        indicatorColor: DarColors.primarySoft,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoris'),
          NavigationDestination(icon: _BoutonPublier(), label: 'Publier'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Bouton rond bleu « + » au centre (maquette).
class _BoutonPublier extends StatelessWidget {
  const _BoutonPublier();
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: DarColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      );
}
