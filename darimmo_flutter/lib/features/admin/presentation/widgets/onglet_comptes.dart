// =====================================================================
// DarImmo - [9.3] Onglet « Comptes » de l'écran Modération
// Tâche du membre A, réalisée par le membre C.
//
// Critères : recherche d'un utilisateur ; champ profiles.bloque ; un compte
// bloqué ne peut plus se connecter ni publier.
// Bloquer demande une confirmation ; débloquer est immédiat.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/admin/data/models/compte_admin.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/comptes_view_model.dart';
import 'package:darimmo/features/chat/presentation/widgets/avatar_darimmo.dart';

class OngletComptes extends StatelessWidget {
  const OngletComptes({super.key, required this.vm});
  final ComptesViewModel vm;

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _basculer(BuildContext context, CompteAdmin c) async {
    if (!c.bloque) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Bloquer ${c.libelle} ?'),
          content: const Text(
            'Ce compte ne pourra plus se connecter, publier d’annonce ni envoyer de message. '
            'Vous pourrez le débloquer à tout moment.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: DarColors.danger),
              child: const Text('Bloquer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final erreur = await vm.basculerBlocage(c);
    if (!context.mounted) return;
    _message(context, erreur ?? (c.bloque ? '${c.libelle} est débloqué.' : '${c.libelle} est bloqué.'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            key: const Key('recherche-comptes'),
            onChanged: vm.chercher,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou email',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(children: [
            Expanded(
              child: Text(vm.modeBloques ? 'Comptes bloqués' : 'Résultats',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DarColors.muted)),
            ),
            if (vm.chargement) const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
        Expanded(child: _liste(context)),
      ]),
    );
  }

  Widget _liste(BuildContext context) {
    if (vm.erreur != null) {
      return _Vide(
        icone: Icons.wifi_off,
        texte: vm.erreur!,
        bouton: TextButton(onPressed: vm.charger, child: const Text('Réessayer')),
      );
    }
    if (vm.comptes.isEmpty && !vm.chargement) {
      return _Vide(
        icone: vm.modeBloques ? Icons.verified_user_outlined : Icons.person_search_outlined,
        texte: vm.modeBloques
            ? 'Aucun compte bloqué. Cherchez un utilisateur pour le bloquer.'
            : 'Aucun compte ne correspond à « ${vm.recherche.trim()} ».',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: vm.comptes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = vm.comptes[i];
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: DarColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.bloque ? DarColors.danger : DarColors.border),
          ),
          child: Row(children: [
            AvatarDarImmo(url: c.photoUrl, initiales: c.initiales, taille: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(c.libelle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
                  ),
                  if (c.estAdmin) const _Pastille(texte: 'ADMIN', fond: DarColors.primarySoft, couleur: DarColors.primary),
                  if (c.bloque) const _Pastille(texte: 'BLOQUÉ', fond: DarColors.dangerSoft, couleur: DarColors.danger),
                ]),
                if (c.email != null)
                  Text(c.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: DarColors.muted)),
              ]),
            ),
            if (!c.estAdmin)
              TextButton(
                key: Key('blocage-${c.id}'),
                onPressed: vm.enCours(c.id) ? null : () => _basculer(context, c),
                style: TextButton.styleFrom(foregroundColor: c.bloque ? DarColors.success : DarColors.danger),
                child: Text(c.bloque ? 'Débloquer' : 'Bloquer'),
              ),
          ]),
        );
      },
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte, required this.fond, required this.couleur});
  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(6)),
        child: Text(texte, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: couleur)),
      );
}

class _Vide extends StatelessWidget {
  const _Vide({required this.icone, required this.texte, this.bouton});
  final IconData icone;
  final String texte;
  final Widget? bouton;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icone, size: 44, color: DarColors.muted),
            const SizedBox(height: 12),
            Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: DarColors.text2, height: 1.4)),
            if (bouton != null) ...[const SizedBox(height: 8), bouton!],
          ]),
        ),
      );
}
