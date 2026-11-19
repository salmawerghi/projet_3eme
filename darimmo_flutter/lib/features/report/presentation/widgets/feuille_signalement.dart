// =====================================================================
// DarImmo - [3.4] Feuille « Signaler cette annonce » (maquette B5)
// Tâche du membre B, réalisée par le membre C.
//
// Choix d'un motif (obligatoire), précision facultative (obligatoire pour
// « Autre motif »), envoi. Renvoie true si le signalement est enregistré
// (ou l'était déjà).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/report/data/repositories/signalement_repository.dart';

const motifsSignalement = [
  'Annonce frauduleuse ou arnaque',
  'Bien déjà vendu ou loué',
  'Prix ou informations trompeurs',
  'Photos inappropriées',
  'Autre motif',
];

/// Texte enregistré : « Catégorie — précision » (500 caractères au plus).
String composerMotif(String categorie, String precision) {
  final p = precision.trim();
  final texte = p.isEmpty ? categorie : '$categorie — $p';
  return texte.length <= 500 ? texte : texte.substring(0, 500);
}

class FeuilleSignalement extends StatefulWidget {
  const FeuilleSignalement({super.key, required this.idAnnonce, required this.repository});

  final String idAnnonce;
  final SignalementRepository repository;

  @override
  State<FeuilleSignalement> createState() => _FeuilleSignalementState();
}

class _FeuilleSignalementState extends State<FeuilleSignalement> {
  final _precision = TextEditingController();
  String? _categorie;
  String? _erreur;
  bool _envoi = false;

  @override
  void dispose() {
    _precision.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final categorie = _categorie;
    if (categorie == null) return setState(() => _erreur = 'Choisissez un motif.');
    if (categorie == 'Autre motif' && _precision.text.trim().length < 5) {
      return setState(() => _erreur = 'Précisez le motif (5 caractères au moins).');
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.repository.signaler(widget.idAnnonce, composerMotif(categorie, _precision.text));
      if (mounted) Navigator.pop(context, true);
    } on SignalementException catch (e) {
      if (!mounted) return;
      if (e.dejaSignale) return Navigator.pop(context, true);
      setState(() {
        _envoi = false;
        _erreur = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          const Text('Signaler cette annonce', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Votre signalement est anonyme pour l’annonceur. Un administrateur l’examine rapidement.',
            style: TextStyle(fontSize: 14, height: 1.4, color: DarColors.text2),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _categorie,
            onChanged: (v) {
              if (!_envoi) setState(() => _categorie = v);
            },
            child: Column(children: [
              for (final m in motifsSignalement)
                RadioListTile<String>(
                  value: m,
                  title: Text(m, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ]),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _precision,
            enabled: !_envoi,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: _categorie == 'Autre motif' ? 'Précisez le motif' : 'Précisez (facultatif)',
              alignLabelWithHint: true,
            ),
          ),
          const Row(children: [
            Icon(Icons.info_outline, size: 15, color: DarColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text('Vous ne pouvez signaler une annonce qu’une seule fois.',
                  style: TextStyle(fontSize: 12, color: DarColors.muted)),
            ),
          ]),
          if (_erreur != null) ...[
            const SizedBox(height: 10),
            Text(_erreur!, style: const TextStyle(color: DarColors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _envoi ? null : _envoyer,
            style: FilledButton.styleFrom(backgroundColor: DarColors.danger),
            icon: _envoi
                ? const SizedBox.square(
                    dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.flag_outlined),
            label: Text(_envoi ? 'Envoi…' : 'Envoyer le signalement'),
          ),
        ]),
      ),
    );
  }
}
