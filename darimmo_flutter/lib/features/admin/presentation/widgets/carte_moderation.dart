// =====================================================================
// DarImmo - [9.2] Carte d'une annonce à modérer (maquette A7)
// Tâche du membre A, réalisée par le membre C.
//
// Photo, titre, ville · prix, annonceur · ancienneté ; boutons Rejeter /
// Valider. « Rejeter » ouvre le motif (obligatoire, motifs rapides) puis
// « Annuler » / « Confirmer le rejet ».
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/moderation_view_model.dart';
import 'package:darimmo/features/chat/presentation/widgets/avatar_darimmo.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien;
import 'package:darimmo/features/search/presentation/widgets/carte_annonce_recherche.dart' show formaterAnciennete;

class CarteModeration extends StatefulWidget {
  const CarteModeration({
    super.key,
    required this.annonce,
    required this.maintenant,
    required this.enCours,
    required this.onOuvrir,
    required this.onValider,
    required this.onRejeter,
  });

  final AnnonceAModerer annonce;
  final DateTime maintenant;
  final bool enCours;
  final VoidCallback onOuvrir;
  final VoidCallback onValider;

  /// Renvoie true si le rejet est fait (la carte disparaît alors de la liste).
  final Future<bool> Function(String motif) onRejeter;

  @override
  State<CarteModeration> createState() => _CarteModerationState();
}

class _CarteModerationState extends State<CarteModeration> {
  final _form = GlobalKey<FormState>();
  final _motif = TextEditingController();
  bool _rejet = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _confirmerRejet() async {
    if (!_form.currentState!.validate()) return;
    final fait = await widget.onRejeter(_motif.text);
    if (fait && mounted) setState(() => _rejet = false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.annonce;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rejet ? DarColors.primary : DarColors.border, width: _rejet ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: widget.onOuvrir,
          borderRadius: BorderRadius.circular(14),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 72, height: 72, child: _Photo(url: a.photoCouverture, type: a.typeBien)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
                const SizedBox(height: 3),
                Text(a.resume,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DarColors.text2)),
                const SizedBox(height: 5),
                Row(children: [
                  AvatarDarImmo(url: null, initiales: a.initiales, taille: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${a.nomAnnonceur ?? 'Annonceur'} · ${formaterAnciennete(a.envoyeeLe, widget.maintenant)}'
                      '${a.nbPhotos == 0 ? ' · sans photo' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: DarColors.muted),
                    ),
                  ),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: DarColors.muted),
          ]),
        ),
        if (_rejet) ...[
          const SizedBox(height: 12),
          Form(
            key: _form,
            child: TextFormField(
              key: Key('motif-${a.id}'),
              controller: _motif,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              validator: validerMotif,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet (visible par l’annonceur)',
                alignLabelWithHint: true,
              ),
            ),
          ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in motifsRapides)
              ActionChip(
                label: Text(m.split(RegExp('[ :.]')).take(2).join(' ')),
                onPressed: () {
                  _motif.text = m;
                  _form.currentState?.validate();
                },
              ),
          ]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _rejet
                ? OutlinedButton(
                    onPressed: widget.enCours ? null : () => setState(() => _rejet = false),
                    child: const Text('Annuler'),
                  )
                : FilledButton.tonalIcon(
                    onPressed: widget.enCours ? null : () => setState(() => _rejet = true),
                    style: FilledButton.styleFrom(
                      backgroundColor: DarColors.dangerSoft,
                      foregroundColor: DarColors.danger,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _rejet
                ? FilledButton.icon(
                    onPressed: widget.enCours ? null : _confirmerRejet,
                    style: FilledButton.styleFrom(backgroundColor: DarColors.danger),
                    icon: const Icon(Icons.close),
                    label: const Text('Confirmer le rejet'),
                  )
                : FilledButton.icon(
                    onPressed: widget.enCours ? null : widget.onValider,
                    style: FilledButton.styleFrom(backgroundColor: DarColors.success),
                    icon: widget.enCours
                        ? const SizedBox.square(
                            dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: const Text('Valider'),
                  ),
          ),
        ]),
      ]),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.type});
  final String? url;
  final TypeBien type;

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        switch (type) {
          TypeBien.villa => Icons.home_outlined,
          TypeBien.terrain => Icons.landscape_outlined,
          TypeBien.local => Icons.storefront_outlined,
          TypeBien.appartement => Icons.apartment_outlined,
        },
        size: 28,
        color: DarColors.primary,
      ),
    );
    if (url == null) return remplacement;
    return Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => remplacement);
  }
}
