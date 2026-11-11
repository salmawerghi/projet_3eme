// =====================================================================
// DarImmo - [7.2] Échanger en temps réel : écran de discussion (maquette C8)
// Membre C
//
// En-tête : interlocuteur ; bandeau : annonce liée (« Voir ») ;
// messages avec séparateurs de jour et heure d'envoi ; zone de saisie.
// Logique dans DiscussionViewModel, accès Supabase dans ChatRepository.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/chat/data/models/infos_discussion.dart';
import 'package:darimmo/features/chat/data/models/message.dart';
import 'package:darimmo/features/chat/data/repositories/chat_repository.dart';
import 'package:darimmo/features/chat/presentation/viewmodels/discussion_view_model.dart';
import 'package:darimmo/features/chat/presentation/widgets/avatar_darimmo.dart';
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;

class DiscussionPage extends StatelessWidget {
  const DiscussionPage({
    super.key,
    required this.repository,
    required this.idConversation,
    this.titre,
    this.onVoirAnnonce,
    this.horloge,
  });

  final ChatRepository repository;
  final String idConversation;

  /// Nom de l'interlocuteur venant de la liste (affiché avant le chargement ;
  /// inconnu quand on arrive par une notification).
  final String? titre;

  /// Bouton « Voir » du bandeau : ouvre le détail de l'annonce (3.3, membre B).
  final void Function(BuildContext context, String idAnnonce)? onVoirAnnonce;

  /// Heure de référence (fixée dans les tests).
  final DateTime Function()? horloge;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscussionViewModel(repository, idConversation, horloge: horloge)..demarrer(),
      child: _Contenu(page: this),
    );
  }
}

class _Contenu extends StatefulWidget {
  const _Contenu({required this.page});
  final DiscussionPage page;

  @override
  State<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends State<_Contenu> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    // Retour au premier plan : la connexion temps réel a pu être coupée
    // pendant la veille -> on récupère les messages manqués.
    _cycle = AppLifecycleListener(
      onResume: () => context.read<DiscussionViewModel>().charger(silencieux: true),
    );
  }

  @override
  void dispose() {
    _cycle.dispose();
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final vm = context.read<DiscussionViewModel>();
    final texte = _saisie.text;
    if (DiscussionViewModel.texteValide(texte) == null) return;
    _saisie.clear();
    _descendre();
    await vm.envoyer(texte);
  }

  /// La liste est inversée (reverse) : la position 0 est le dernier message.
  void _descendre() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_defilement.hasClients) {
          _defilement.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscussionViewModel>();
    final infos = vm.infos;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          AvatarDarImmo(
            url: infos?.photo,
            initiales: infos?.initiales ?? _initiales(widget.page.titre),
            taille: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(infos?.nom ?? widget.page.titre ?? 'Discussion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: DarColors.border),
        ),
      ),
      body: Column(children: [
        if (infos != null) _BandeauAnnonce(infos: infos, onVoir: widget.page.onVoirAnnonce),
        Expanded(child: _corps(vm)),
        _ZoneSaisie(controleur: _saisie, onEnvoyer: _envoyer),
      ]),
    );
  }

  Widget _corps(DiscussionViewModel vm) {
    if (vm.vide && vm.chargement) return const Center(child: CircularProgressIndicator());
    if (vm.vide && vm.erreur != null) {
      return _Centre(
        icone: Icons.cloud_off_rounded,
        texte: vm.erreur!,
        bouton: FilledButton(onPressed: vm.charger, child: const Text('Réessayer')),
      );
    }
    if (vm.vide) {
      return const _Centre(
        icone: Icons.chat_bubble_outline_rounded,
        texte: 'Aucun message pour l’instant.\nÉcrivez le premier !',
      );
    }
    final elements = vm.elements().reversed.toList();
    return ListView.builder(
      controller: _defilement,
      reverse: true, // s'ouvre toujours sur le dernier message
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      itemCount: elements.length,
      itemBuilder: (_, i) => switch (elements[i]) {
        SeparateurJour(:final texte) => _Separateur(texte),
        BulleMessage(:final message, :final deMoi) => _Bulle(
            message: message,
            deMoi: deMoi,
            onReessayer: () => vm.reessayer(message),
            onAbandonner: () => vm.abandonner(message),
          ),
      },
    );
  }

  static String _initiales(String? nom) {
    final mots = (nom ?? '').trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots[0].substring(0, 1).toUpperCase();
    return (mots[0][0] + mots[1][0]).toUpperCase();
  }
}

/// Annonce liée à la conversation (maquette C8).
class _BandeauAnnonce extends StatelessWidget {
  const _BandeauAnnonce({required this.infos, required this.onVoir});
  final InfosDiscussion infos;
  final void Function(BuildContext context, String idAnnonce)? onVoir;

  @override
  Widget build(BuildContext context) {
    final id = infos.idAnnonce;
    const icone = Icon(Icons.home_outlined, color: DarColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: DarColors.surface,
        border: Border(bottom: BorderSide(color: DarColors.border)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 46,
            height: 46,
            color: DarColors.primarySoft,
            child: infos.photoAnnonce == null
                ? icone
                : Image.network(infos.photoAnnonce!, fit: BoxFit.cover, errorBuilder: (_, _, _) => icone),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(id == null ? 'Annonce supprimée' : infos.titreAnnonce,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: id == null ? DarColors.muted : DarColors.text)),
            if (infos.prix != null)
              Text('${formaterPrix(infos.prix!)} ${infos.location ? 'DT/mois' : 'DT'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DarColors.primary)),
          ]),
        ),
        if (id != null && onVoir != null)
          FilledButton.tonal(
            onPressed: () => onVoir!(context, id),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Voir'),
          ),
      ]),
    );
  }
}

/// « AUJOURD’HUI », « HIER », « MERCREDI 4 NOVEMBRE ».
class _Separateur extends StatelessWidget {
  const _Separateur(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(8)),
          child: Text(texte.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DarColors.muted)),
        ),
      );
}

class _Bulle extends StatelessWidget {
  const _Bulle({required this.message, required this.deMoi, required this.onReessayer, required this.onAbandonner});
  final Message message;
  final bool deMoi;
  final VoidCallback onReessayer;
  final VoidCallback onAbandonner;

  @override
  Widget build(BuildContext context) {
    final echec = message.etat == EtatEnvoi.echec;
    final couleurTexte = deMoi ? Colors.white : DarColors.text;
    final couleurHeure = deMoi ? Colors.white70 : DarColors.muted;
    const r = Radius.circular(20);
    const pointe = Radius.circular(6);

    final bulle = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
      constraints: const BoxConstraints(maxWidth: 290),
      decoration: BoxDecoration(
        color: deMoi ? (echec ? DarColors.danger : DarColors.primary) : DarColors.surface,
        border: deMoi ? null : Border.all(color: DarColors.border),
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: deMoi ? r : pointe,
          bottomRight: deMoi ? pointe : r,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Text(message.contenu, style: TextStyle(fontSize: 15, height: 1.35, color: couleurTexte)),
        const SizedBox(height: 2),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(formaterHeure(message.dateEnvoi), style: TextStyle(fontSize: 11, color: couleurHeure)),
          if (deMoi && message.etat == EtatEnvoi.enCours) ...[
            const SizedBox(width: 4),
            Icon(Icons.schedule_rounded, size: 13, color: couleurHeure, semanticLabel: 'Envoi en cours'),
          ],
          if (echec) ...[
            const SizedBox(width: 4),
            Icon(Icons.error_outline_rounded, size: 13, color: couleurHeure, semanticLabel: 'Non envoyé'),
          ],
        ]),
      ]),
    );

    return Align(
      alignment: deMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        bulle,
        if (echec)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Non envoyé',
                style: TextStyle(fontSize: 12, color: DarColors.danger, fontWeight: FontWeight.w700)),
            TextButton(onPressed: onReessayer, child: const Text('Réessayer')),
            TextButton(
              onPressed: onAbandonner,
              style: TextButton.styleFrom(foregroundColor: DarColors.muted),
              child: const Text('Supprimer'),
            ),
          ]),
      ]),
    );
  }
}

class _ZoneSaisie extends StatelessWidget {
  const _ZoneSaisie({required this.controleur, required this.onEnvoyer});
  final TextEditingController controleur;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final arrondi = BorderRadius.circular(22);
    return Container(
      decoration: const BoxDecoration(
        color: DarColors.surface,
        border: Border(top: BorderSide(color: DarColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: controleur,
                minLines: 1,
                maxLines: 5,
                maxLength: longueurMaxMessage,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                // Compteur seulement près de la limite de la base (2000).
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    currentLength > longueurMaxMessage - 200 ? Text('$currentLength / $maxLength') : null,
                decoration: InputDecoration(
                  hintText: 'Votre message…',
                  filled: true,
                  fillColor: DarColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(borderRadius: arrondi, borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: arrondi, borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: arrondi,
                    borderSide: const BorderSide(color: DarColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Bouton actif seulement s'il y a du texte.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controleur,
              builder: (_, valeur, _) {
                final actif = DiscussionViewModel.texteValide(valeur.text) != null;
                return IconButton.filled(
                  onPressed: actif ? onEnvoyer : null,
                  tooltip: 'Envoyer',
                  style: IconButton.styleFrom(
                    backgroundColor: DarColors.primary,
                    disabledBackgroundColor: DarColors.surface2,
                    fixedSize: const Size(46, 46),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre({required this.icone, required this.texte, this.bouton});
  final IconData icone;
  final String texte;
  final Widget? bouton;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icone, size: 40, color: DarColors.muted),
            const SizedBox(height: 12),
            Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: DarColors.text2)),
            if (bouton != null) ...[const SizedBox(height: 14), bouton!],
          ]),
        ),
      );
}
