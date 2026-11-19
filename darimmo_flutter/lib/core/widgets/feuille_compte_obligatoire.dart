// =====================================================================
// DarImmo - Feuille « Connectez-vous pour… » (visiteur sans compte)
// Membre C (écrite pour la 7.1, partagée avec la 5.1 favoris)
//
// Explique pourquoi un compte est nécessaire et propose de se connecter ou
// de créer un compte. Rien n'est fait si la feuille est fermée.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

enum _Choix { seConnecter, creerCompte }

Future<void> proposerConnexion(
  BuildContext context, {
  required IconData icone,
  required String titre,
  required String texte,
  required void Function(BuildContext context) onSeConnecter,
  required void Function(BuildContext context) onCreerCompte,
}) async {
  final choix = await showModalBottomSheet<_Choix>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // hauteur selon le contenu (pas la limite de 9/16 d'écran)
    backgroundColor: DarColors.surface,
    builder: (_) => _FeuilleCompteObligatoire(icone: icone, titre: titre, texte: texte),
  );
  if (!context.mounted || choix == null) return;
  switch (choix) {
    case _Choix.seConnecter:
      onSeConnecter(context);
    case _Choix.creerCompte:
      onCreerCompte(context);
  }
}

class _FeuilleCompteObligatoire extends StatelessWidget {
  const _FeuilleCompteObligatoire({required this.icone, required this.titre, required this.texte});
  final IconData icone;
  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: DarColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icone, color: DarColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            texte,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.45, color: DarColors.text2),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.pop(context, _Choix.seConnecter),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _Choix.creerCompte),
            child: const Text('Créer un compte'),
          ),
        ]),
      ),
    );
  }
}
