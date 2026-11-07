// =====================================================================
// DarImmo - [7.3] Écran « Messages » : mes conversations (maquette C7)
// Membre C
//
// Critères d'acceptation :
//   - nom, photo, annonce et dernier message
//   - tri du plus récent au plus ancien (date_dernier_message)
//   - indicateur de message non lu (pastille + ligne en gras sur fond bleu clair)
// La liste se met à jour toute seule à l'arrivée d'un message (Realtime).
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/darimmo_theme.dart';
import '../conversations_view_model.dart';
import '../data/conversations_repository.dart';
import '../models/resume_conversation.dart';

/// Ouvre la discussion ; la liste est rechargée au retour (non-lus remis à zéro).
typedef OuvrirConversation = Future<void> Function(BuildContext context, ResumeConversation conversation);

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({
    super.key,
    required this.repository,
    required this.onOuvrir,
    this.actions = const [],
    this.floatingActionButton,
    this.maintenant,
  });

  final ConversationsRepository repository;
  final OuvrirConversation onOuvrir;

  /// Boutons de la barre du haut (Mes annonces, déconnexion…), fournis par l'app.
  final List<Widget> actions;
  final Widget? floatingActionButton;

  /// Heure de référence pour « Hier », « Lun. »… (fixée dans les tests).
  final DateTime Function()? maintenant;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversationsViewModel(repository)..demarrer(),
      child: _Contenu(page: this),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.page});
  final ConversationsPage page;

  Future<void> _ouvrir(BuildContext context, ResumeConversation c) async {
    final vm = context.read<ConversationsViewModel>();
    await page.onOuvrir(context, c);
    await vm.charger(silencieux: true); // messages lus pendant la discussion
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConversationsViewModel>();
    final maintenant = (page.maintenant ?? DateTime.now)();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(vm.resume,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vm.totalNonLus > 0 ? DarColors.primary : DarColors.muted,
              )),
        ]),
        actions: page.actions,
      ),
      floatingActionButton: page.floatingActionButton,
      body: Column(children: [
        if (vm.total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              onChanged: vm.chercher,
              decoration: const InputDecoration(
                hintText: 'Rechercher une personne ou un bien',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        Expanded(child: RefreshIndicator(onRefresh: vm.charger, child: _liste(context, vm, maintenant))),
      ]),
    );
  }

  Widget _liste(BuildContext context, ConversationsViewModel vm, DateTime maintenant) {
    if (vm.jamaisCharge && vm.chargement) return const Center(child: CircularProgressIndicator());
    if (vm.jamaisCharge && vm.erreur != null) {
      return _Message(
        icone: Icons.wifi_off_rounded,
        titre: 'Impossible de charger vos messages',
        texte: vm.erreur!,
        bouton: OutlinedButton(onPressed: vm.charger, child: const Text('Réessayer')),
      );
    }
    if (vm.total == 0) {
      return const _Message(
        icone: Icons.forum_outlined,
        titre: 'Aucune conversation',
        texte: 'Contactez un annonceur depuis une annonce : vos échanges apparaîtront ici.',
      );
    }
    final liste = vm.conversations;
    if (liste.isEmpty) {
      return const _Message(icone: Icons.search_off, titre: 'Aucun résultat', texte: 'Essayez un autre nom ou un autre bien.');
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96), // place pour le bouton flottant
      itemCount: liste.length,
      itemBuilder: (context, i) => LigneConversation(
        key: ValueKey(liste[i].id),
        conversation: liste[i],
        heure: formaterDateConversation(liste[i].dateDernierMessage, maintenant),
        onTap: () => _ouvrir(context, liste[i]),
      ),
    );
  }
}

/// Une conversation de la liste (convRow de la maquette C7).
class LigneConversation extends StatelessWidget {
  const LigneConversation({super.key, required this.conversation, required this.heure, required this.onTap});
  final ResumeConversation conversation;
  final String heure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final nonLu = c.aDesNonLus;
    return Material(
      color: nonLu ? DarColors.primarySoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DarColors.border))),
          child: Row(children: [
            _Avatar(url: c.photoInterlocuteur, initiales: c.initiales),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(c.nomAffiche,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
                  ),
                  const SizedBox(width: 8),
                  Text(heure,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: nonLu ? FontWeight.w800 : FontWeight.w500,
                        color: nonLu ? DarColors.primary : DarColors.muted,
                      )),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _MiniatureAnnonce(url: c.photoAnnonce),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(c.titreAnnonce ?? 'Annonce supprimée',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: c.annonceSupprimee ? FontStyle.italic : FontStyle.normal,
                          color: DarColors.muted,
                        )),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: Text(c.dernierMessage ?? 'Pas encore de message',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: nonLu ? FontWeight.w700 : FontWeight.w500,
                          fontStyle: c.dernierMessage == null ? FontStyle.italic : FontStyle.normal,
                          color: nonLu ? DarColors.text : DarColors.text2,
                        )),
                  ),
                  if (nonLu) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: '${c.nonLus} non lu${c.nonLus > 1 ? 's' : ''}',
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: DarColors.primary, borderRadius: BorderRadius.circular(11)),
                        child: Text(c.nonLus > 99 ? '99+' : '${c.nonLus}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initiales});
  final String? url;
  final String initiales;

  @override
  Widget build(BuildContext context) {
    final lettres = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Text(initiales, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DarColors.primary)),
    );
    return ClipOval(
      child: SizedBox(
        width: 54,
        height: 54,
        child: url == null
            ? lettres
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => lettres),
      ),
    );
  }
}

class _MiniatureAnnonce extends StatelessWidget {
  const _MiniatureAnnonce({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const icone = Icon(Icons.home_outlined, size: 13, color: DarColors.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 18,
        height: 18,
        color: DarColors.primarySoft,
        child: url == null ? icone : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => icone),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.titre, required this.texte, this.bouton});
  final IconData icone;
  final String titre;
  final String texte;
  final Widget? bouton;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 24),
      children: [
        Icon(icone, size: 56, color: DarColors.muted),
        const SizedBox(height: 16),
        Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.45, color: DarColors.text2)),
        if (bouton != null) ...[const SizedBox(height: 20), bouton!],
      ],
    );
  }
}
