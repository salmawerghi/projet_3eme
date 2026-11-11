// =====================================================================
// DarImmo - Bandeau d'erreur des maquettes v3 (banner('danger', …))
// Fond rouge pâle, icône d'alerte, texte rouge. Utilisé en haut des
// formulaires (connexion, inscription…) pour une erreur générale.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class BandeauErreur extends StatelessWidget {
  const BandeauErreur({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true, // lu par le lecteur d'écran dès qu'il apparaît
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: DarColors.dangerSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: DarColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: DarColors.danger, fontSize: 13, height: 1.45, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
