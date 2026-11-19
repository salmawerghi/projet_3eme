// =====================================================================
// DarImmo - [3.4] Lien « Signaler cette annonce » du détail (maquette B4)
// Tâche du membre B, réalisée par le membre C.
//
//   - visiteur : invité à se connecter ;
//   - sa propre annonce : pas de lien ;
//   - déjà signalée : « Vous avez signalé cette annonce » (un seul
//     signalement par utilisateur et par annonce) ;
//   - après l'envoi : confirmation affichée.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/feuille_compte_obligatoire.dart';
import 'package:darimmo/features/report/data/repositories/signalement_repository.dart';
import 'package:darimmo/features/report/presentation/widgets/feuille_signalement.dart';

class LienSignaler extends StatefulWidget {
  const LienSignaler({
    super.key,
    required this.idAnnonce,
    required this.repository,
    required this.estConnecte,
    required this.estMonAnnonce,
    required this.onSeConnecter,
    required this.onCreerCompte,
  });

  final String idAnnonce;
  final SignalementRepository repository;
  final bool estConnecte;
  final bool estMonAnnonce;
  final void Function(BuildContext context) onSeConnecter;
  final void Function(BuildContext context) onCreerCompte;

  @override
  State<LienSignaler> createState() => _LienSignalerState();
}

class _LienSignalerState extends State<LienSignaler> {
  bool _dejaSignale = false;

  @override
  void initState() {
    super.initState();
    if (widget.estConnecte && !widget.estMonAnnonce) {
      widget.repository.dejaSignale(widget.idAnnonce).then((oui) {
        if (mounted && oui) setState(() => _dejaSignale = true);
      });
    }
  }

  Future<void> _signaler() async {
    if (!widget.estConnecte) {
      return proposerConnexion(
        context,
        icone: Icons.flag_outlined,
        titre: 'Connectez-vous pour signaler cette annonce',
        texte: 'Un compte permet d’éviter les signalements abusifs. Votre nom n’est pas montré à l’annonceur.',
        onSeConnecter: widget.onSeConnecter,
        onCreerCompte: widget.onCreerCompte,
      );
    }
    final envoye = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: DarColors.surface,
      builder: (_) => FeuilleSignalement(idAnnonce: widget.idAnnonce, repository: widget.repository),
    );
    if (envoye != true || !mounted) return;
    setState(() => _dejaSignale = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Merci ! Votre signalement a été envoyé. Un administrateur va l’examiner.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estMonAnnonce) return const SizedBox.shrink();
    if (_dejaSignale) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 16, color: DarColors.success),
          SizedBox(width: 6),
          Flexible(
            child: Text('Vous avez signalé cette annonce',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DarColors.muted)),
          ),
        ]),
      );
    }
    return Center(
      child: TextButton.icon(
        onPressed: _signaler,
        style: TextButton.styleFrom(foregroundColor: DarColors.muted),
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Signaler cette annonce', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
