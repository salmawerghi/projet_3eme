// =====================================================================
// DarImmo - Écran provisoire d'un module pas encore développé (tâche 1.6)
//
// Chaque route du squelette existe déjà : le responsable remplace
// simplement ce widget par son vrai écran dans core/router/app_router.dart.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class BientotDisponible extends StatelessWidget {
  const BientotDisponible({
    super.key,
    required this.titre,
    required this.stories,
    required this.responsable,
    required this.icone,
    this.description,
    this.enfant,
    this.avecAppBar = true,
  });

  final String titre;

  /// Ex : « 3.1 Voir la liste des annonces · 3.2 Filtrer ».
  final String stories;

  /// Ex : « Membre B ».
  final String responsable;
  final IconData icone;
  final String? description;

  /// Contenu facultatif sous le message (ex : un aperçu de la carte).
  final Widget? enfant;

  /// false pour les onglets qui ont déjà leur barre de navigation en bas.
  final bool avecAppBar;

  @override
  Widget build(BuildContext context) {
    final corps = ListView(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: DarColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icone, size: 38, color: DarColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Bientôt disponible', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DarColors.primary)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stories, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DarColors.text)),
            const SizedBox(height: 4),
            Text('Responsable : $responsable', style: const TextStyle(fontSize: 13, color: DarColors.text2)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!, style: const TextStyle(fontSize: 13, height: 1.45, color: DarColors.text2)),
            ],
          ]),
        ),
        if (enfant != null) ...[const SizedBox(height: 18), enfant!],
      ],
    );
    return avecAppBar ? Scaffold(appBar: AppBar(title: Text(titre)), body: corps) : corps;
  }
}
