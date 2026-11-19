// =====================================================================
// DarImmo - [4.1] Marqueur d'une annonce sur la carte (maquette B3)
// Tâche du membre B, réalisée par le membre C.
//
// Pastille avec le prix court : blanche pour une vente, ocre pour une
// location, bleue quand elle est choisie (aperçu affiché).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class PinPrix extends StatelessWidget {
  const PinPrix({
    super.key,
    required this.libelle,
    required this.onTap,
    this.choisi = false,
    this.location = false,
    this.description,
  });

  final String libelle;
  final VoidCallback onTap;
  final bool choisi;
  final bool location;

  /// Texte lu par le lecteur d'écran (titre + prix complet).
  final String? description;

  @override
  Widget build(BuildContext context) {
    final fond = choisi ? DarColors.primary : (location ? DarColors.accent : DarColors.surface);
    final texte = choisi || location ? Colors.white : DarColors.text;
    return Semantics(
      button: true,
      selected: choisi,
      label: description,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: choisi ? 1.12 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: choisi || location ? Colors.white : DarColors.border, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x330B1220), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Text(
              libelle,
              maxLines: 1,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: texte),
            ),
          ),
        ),
      ),
    );
  }
}

/// Point bleu « Ma position » avec un halo (maquette B3).
class PointMaPosition extends StatelessWidget {
  const PointMaPosition({super.key});

  static const bleu = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ma position',
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bleu.withValues(alpha: 0.18)),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bleu,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x330B1220), blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
      ),
    );
  }
}
