// =====================================================================
// DarImmo - [5.1] Bouton cœur (maquettes B1, B4, B6)
// Tâche du membre B, réalisée par le membre C.
//
// Critères : cœur sur la liste et sur le détail ; un visiteur est invité à
// se connecter. Rond blanc ; cœur rouge plein quand l'annonce est en favori.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/feuille_compte_obligatoire.dart';
import 'package:darimmo/features/favorites/presentation/viewmodels/etat_favoris.dart';

class BoutonFavori extends StatelessWidget {
  const BoutonFavori({
    super.key,
    required this.idAnnonce,
    required this.etat,
    required this.onSeConnecter,
    required this.onCreerCompte,
    this.taille = 38,
    this.bordure = false,
  });

  final String idAnnonce;
  final EtatFavoris etat;
  final void Function(BuildContext context) onSeConnecter;
  final void Function(BuildContext context) onCreerCompte;

  /// Diamètre : 38 sur la photo de la liste, 54 dans la barre du détail.
  final double taille;

  /// Contour gris (sur fond blanc) au lieu d'une ombre (sur photo).
  final bool bordure;

  Future<void> _toucher(BuildContext context) async {
    if (!etat.estConnecte) {
      return proposerConnexion(
        context,
        icone: Icons.favorite_border,
        titre: 'Connectez-vous pour enregistrer vos favoris',
        texte: 'Un compte gratuit vous permet de garder vos biens préférés et de les retrouver plus tard.',
        onSeConnecter: onSeConnecter,
        onCreerCompte: onCreerCompte,
      );
    }
    final erreur = await etat.basculer(idAnnonce);
    if (erreur != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(erreur)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: etat,
      builder: (context, _) {
        final favori = etat.estFavori(idAnnonce);
        return Material(
          color: DarColors.surface,
          shape: CircleBorder(side: bordure ? const BorderSide(color: DarColors.border) : BorderSide.none),
          elevation: bordure ? 0 : 2,
          shadowColor: const Color(0x440B1220),
          child: IconButton(
            key: Key('favori-$idAnnonce'),
            tooltip: favori ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: () => _toucher(context),
            constraints: BoxConstraints.tightFor(width: taille, height: taille),
            padding: EdgeInsets.zero,
            icon: Icon(
              favori ? Icons.favorite : Icons.favorite_border,
              size: taille * 0.47,
              color: favori ? DarColors.danger : DarColors.text,
            ),
          ),
        );
      },
    );
  }
}
