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

import 'package:darimmo/core/theme/darimmo_theme.dart';
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

  Future<void> _proposerConnexion() async {
    final choix = await showModalBottomSheet<_Choix>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // hauteur selon le contenu (pas la limite de 9/16 d'écran)
      backgroundColor: DarColors.surface,
      builder: (_) => const _FeuilleCompteObligatoire(),
    );
    if (!mounted || choix == null) return;
    switch (choix) {
      case _Choix.seConnecter:
        widget.onSeConnecter(context);
      case _Choix.creerCompte:
        widget.onCreerCompte(context);
    }
  }

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

enum _Choix { seConnecter, creerCompte }

/// Visiteur sans compte : on explique pourquoi un compte est nécessaire.
class _FeuilleCompteObligatoire extends StatelessWidget {
  const _FeuilleCompteObligatoire();

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
            child: const Icon(Icons.chat_bubble_outline, color: DarColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Connectez-vous pour contacter l’annonceur',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Un compte gratuit vous permet d’échanger avec les propriétaires et de retrouver vos conversations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: DarColors.text2),
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
