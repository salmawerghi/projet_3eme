// =====================================================================
// DarImmo - Logo officiel des maquettes v3 (design/src/spec.js, logo())
// Une porte en arche (« dar » = maison) dans un carré arrondi + « DarImmo ».
//   clair = false : carré bleu, arche blanche (fond clair : connexion…)
//   clair = true  : carré blanc, arche bleue et porte ocre (sur photo : A1)
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class LogoDarImmo extends StatelessWidget {
  const LogoDarImmo({super.key, this.taille = 44, this.clair = false, this.avecNom = true});

  /// Côté du carré, en pixels logiques.
  final double taille;
  final bool clair;
  final bool avecNom;

  @override
  Widget build(BuildContext context) {
    final icone = Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: clair ? Colors.white : DarColors.primary,
        borderRadius: BorderRadius.circular(taille * 0.3),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(taille * 0.6),
        painter: _Arche(
          arche: clair ? DarColors.primary : Colors.white,
          porte: clair ? DarColors.accent : Colors.white,
        ),
      ),
    );
    if (!avecNom) return Semantics(label: 'DarImmo', child: icone);

    final style = TextStyle(fontSize: taille * 0.55, fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return Semantics(
      label: 'DarImmo',
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icone,
          SizedBox(width: taille * 0.23),
          Text('Dar', style: style.copyWith(color: clair ? Colors.white : DarColors.text)),
          Text('Immo', style: style.copyWith(color: clair ? Colors.white : DarColors.primary)),
        ]),
      ),
    );
  }
}

/// Tracé SVG de la maquette (viewBox 24 x 24) :
///   arche : M4 21 V10.5 a8 8 0 0 1 16 0 V21
///   porte : M9 21 v-6  a3 3 0 0 1 6 0  v6
class _Arche extends CustomPainter {
  const _Arche({required this.arche, required this.porte});
  final Color arche;
  final Color porte;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    Paint trait(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final contour = Path()
      ..moveTo(4, 21)
      ..lineTo(4, 10.5)
      ..arcToPoint(const Offset(20, 10.5), radius: const Radius.circular(8))
      ..lineTo(20, 21);
    final entree = Path()
      ..moveTo(9, 21)
      ..lineTo(9, 15)
      ..arcToPoint(const Offset(15, 15), radius: const Radius.circular(3))
      ..lineTo(15, 21);
    canvas.drawPath(contour, trait(arche));
    canvas.drawPath(entree, trait(porte));
  }

  @override
  bool shouldRepaint(_Arche ancien) => ancien.arche != arche || ancien.porte != porte;
}
