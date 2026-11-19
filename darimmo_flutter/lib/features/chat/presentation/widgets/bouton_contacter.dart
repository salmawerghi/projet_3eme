// =====================================================================
// DarImmo - [7.1] Contacter l'annonceur depuis une annonce - membre C
//
// Bouton réutilisable, placé par le membre B dans son écran de détail (3.3).
// Le routeur le construit (core/router/app_router.dart) : B n'a qu'à
// appeler boutonContacter(annonce.idAnnonceur) là où il veut le bouton.
//
// Critères d'acceptation :
//   - ouvre une conversation liée à l'annonce, ou reprend l'existante
//     (fonction SQL public.ouvrir_conversation) ;
//   - compte obligatoire : un visiteur se voit proposer de se connecter ;
//   - impossible de se contacter soi-même : bouton désactivé sur ses
//     propres annonces (et la fonction SQL refuse de toute façon).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/widgets/feuille_compte_obligatoire.dart';
import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';

class BoutonContacter extends StatefulWidget {
  const BoutonContacter({
    super.key,
    required this.idAnnonce,
    required this.repository,
    required this.estConnecte,
    required this.onOuvrirConversation,
    required this.onSeConnecter,
    required this.onCreerCompte,
    this.estMonAnnonce = false,
  });

  final String idAnnonce;
  final ConversationsRepository repository;
  final bool estConnecte;

  /// Vrai si l'utilisateur connecté est l'annonceur.
  final bool estMonAnnonce;

  final void Function(BuildContext context, String idConversation) onOuvrirConversation;
  final void Function(BuildContext context) onSeConnecter;
  final void Function(BuildContext context) onCreerCompte;

  @override
  State<BoutonContacter> createState() => _BoutonContacterState();
}

class _BoutonContacterState extends State<BoutonContacter> {
  bool _enCours = false;

  Future<void> _contacter() async {
    if (_enCours) return;
    if (!widget.estConnecte) return _proposerConnexion();
    setState(() => _enCours = true);
    ContactException? erreur;
    try {
      final id = await widget.repository.ouvrirAvecAnnonceur(widget.idAnnonce);
      if (mounted) widget.onOuvrirConversation(context, id);
    } on ContactException catch (e) {
      erreur = e;
    } finally {
      if (mounted) setState(() => _enCours = false); // avant la feuille ou le message
    }
    if (erreur == null || !mounted) return;
    if (erreur.connexionRequise) {
      await _proposerConnexion();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(erreur.message)));
    }
  }

  Future<void> _proposerConnexion() => proposerConnexion(
        context,
        icone: Icons.chat_bubble_outline,
        titre: 'Connectez-vous pour contacter l’annonceur',
        texte: 'Un compte gratuit vous permet d’échanger avec les propriétaires et de retrouver vos conversations.',
        onSeConnecter: widget.onSeConnecter,
        onCreerCompte: widget.onCreerCompte,
      );

  @override
  Widget build(BuildContext context) {
    if (widget.estMonAnnonce) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.person_outline),
        label: const Text('C’est votre annonce'),
      );
    }
    return FilledButton.icon(
      onPressed: _enCours ? null : _contacter,
      icon: _enCours
          ? const SizedBox.square(
              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          : const Icon(Icons.chat_bubble_outline),
      label: Text(_enCours ? 'Ouverture…' : 'Contacter'),
    );
  }
}
