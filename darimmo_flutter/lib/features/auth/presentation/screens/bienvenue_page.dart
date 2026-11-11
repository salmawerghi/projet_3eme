// =====================================================================
// DarImmo - Écran de bienvenue (maquette A1) - membre A
//
// Premier écran quand personne n'est connecté : créer un compte (2.1),
// se connecter (2.2), ou continuer en visiteur (3.1 « En tant que
// visiteur, je veux voir la liste des annonces »).
// =====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class BienvenuePage extends StatelessWidget {
  const BienvenuePage({
    super.key,
    required this.onCreerCompte,
    required this.onSeConnecter,
    required this.onContinuerSansCompte,
  });

  final void Function(BuildContext context) onCreerCompte;
  final void Function(BuildContext context) onSeConnecter;
  final void Function(BuildContext context) onContinuerSansCompte;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // icônes de la barre d'état en blanc
      child: Scaffold(
        backgroundColor: DarColors.text,
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/bienvenue.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 1],
                colors: [Color(0x330B1220), Color(0x000B1220), Color(0xE60B1220)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, contraintes) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const _Logo(),
                        const Spacer(),
                        const SizedBox(height: 24),
                        const _Pastille(),
                        const SizedBox(height: 14),
                        const Text(
                          'Trouvez le bien qui vous ressemble, partout en Tunisie.',
                          style: TextStyle(
                              fontSize: 32, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Achetez, louez ou publiez votre bien en quelques minutes. '
                          'Échangez directement avec les propriétaires.',
                          style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => onCreerCompte(context),
                          child: const Text('Créer un compte'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => onSeConnecter(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Text('J’ai déjà un compte'),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton(
                            onPressed: () => onContinuerSansCompte(context),
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            child: const Text('Continuer sans compte',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white),
      ),
      const SizedBox(width: 10),
      const Text('DarImmo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
    ]);
  }
}

/// La maquette affiche « 2 400 BIENS VÉRIFIÉS » : on ne met pas de chiffre
/// inventé, mais ce qui est vrai (chaque annonce est validée par un admin).
class _Pastille extends StatelessWidget {
  const _Pastille();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_user_outlined, size: 15, color: Colors.white),
        SizedBox(width: 6),
        Text('ANNONCES VÉRIFIÉES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white)),
      ]),
    );
  }
}
