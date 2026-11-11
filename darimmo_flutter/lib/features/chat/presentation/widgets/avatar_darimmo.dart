// =====================================================================
// DarImmo - Avatar rond : photo de profil, ou initiales si pas de photo
// Membre C (messagerie 7.2 / 7.3) ; réutilisable par A pour le profil.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class AvatarDarImmo extends StatelessWidget {
  const AvatarDarImmo({super.key, required this.url, required this.initiales, this.taille = 54});
  final String? url;
  final String initiales;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final lettres = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Text(initiales,
          style: TextStyle(fontSize: taille * 0.32, fontWeight: FontWeight.w800, color: DarColors.primary)),
    );
    return ClipOval(
      child: SizedBox(
        width: taille,
        height: taille,
        child: url == null ? lettres : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => lettres),
      ),
    );
  }
}
