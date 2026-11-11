// =====================================================================
// DarImmo - [3.2] Feuille de filtres (maquette B2)
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Critères 3.2 : prix min / max, ville, type de bien, vente ou location,
// nombre de pièces minimum, bouton Réinitialiser.
// Le bouton du bas annonce le nombre de résultats avant d'appliquer.
// =====================================================================
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;
import 'package:darimmo/features/publish/presentation/validators.dart' show lireNombre;
import 'package:darimmo/features/search/data/models/filtre_recherche.dart';

/// Ouvre la feuille ; renvoie les nouveaux filtres, ou null si on la ferme sans valider.
Future<FiltreRecherche?> ouvrirFeuilleFiltres(
  BuildContext context, {
  required FiltreRecherche initial,
  required Future<int> Function(FiltreRecherche) compter,
  required Future<List<String>> Function() villes,
}) {
  return showModalBottomSheet<FiltreRecherche>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: DarColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => FeuilleFiltres(initial: initial, compter: compter, villes: villes),
  );
}

/// Échelle du curseur : les loyers (450 à 4 000 DT/mois) et les prix de vente
/// (dizaines de milliers à millions de DT) n'ont pas du tout la même échelle.
({double max, int pas}) echellePrix(TypeOffre? offre) =>
    offre == TypeOffre.location ? (max: 10000, pas: 50) : (max: 3000000, pas: 10000);

/// Libellés « S+n » des puces de pièces minimum (S+4 + = 4 et plus).
const sPlusProposes = [1, 2, 3, 4];

class FeuilleFiltres extends StatefulWidget {
  const FeuilleFiltres({
    super.key,
    required this.initial,
    required this.compter,
    required this.villes,
    this.delaiComptage = const Duration(milliseconds: 350),
  });

  final FiltreRecherche initial;
  final Future<int> Function(FiltreRecherche) compter;
  final Future<List<String>> Function() villes;

  /// Attente après la dernière modification avant de recompter (évite une requête par mouvement).
  final Duration delaiComptage;

  @override
  State<FeuilleFiltres> createState() => _FeuilleFiltresState();
}

class _FeuilleFiltresState extends State<FeuilleFiltres> {
  TypeOffre? _offre;
  TypeBien? _type;
  double? _prixMin;
  double? _prixMax;
  int? _sPlus;
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _ville = TextEditingController();
  final _focusVille = FocusNode();
  List<String> _villes = const [];

  int? _nbResultats;
  Timer? _attente;
  int _numeroComptage = 0;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _offre = f.typeOffre;
    _type = f.typeBien;
    _prixMin = f.prixMin;
    _prixMax = f.prixMax;
    _sPlus = f.sPlusMin;
    _min.text = _prixMin == null ? '' : formaterPrix(_prixMin!);
    _max.text = _prixMax == null ? '' : formaterPrix(_prixMax!);
    _ville.text = f.ville ?? '';
    _ville.addListener(_villeChangee);
    widget.villes().then((v) {
      if (mounted) setState(() => _villes = v);
    });
    _compter();
  }

  @override
  void dispose() {
    _attente?.cancel();
    _min.dispose();
    _max.dispose();
    _ville.dispose();
    _focusVille.dispose();
    super.dispose();
  }

  bool get _minIllisible => _min.text.trim().isNotEmpty && lireNombre(_min.text) == null;
  bool get _maxIllisible => _max.text.trim().isNotEmpty && lireNombre(_max.text) == null;

  String? get _erreurPrix {
    if (_minIllisible || _maxIllisible) return 'Entrez un nombre (ex : 150 000)';
    if (_prixMin != null && _prixMax != null && _prixMin! > _prixMax!) {
      return 'Le prix minimum dépasse le prix maximum';
    }
    return null;
  }

  FiltreRecherche get _filtre => widget.initial.copie(
        typeOffre: () => _offre,
        typeBien: () => _type,
        prixMin: () => _prixMin,
        prixMax: () => _prixMax,
        ville: () => _ville.text,
        sPlusMin: () => _sPlus,
      );

  void _villeChangee() {
    if (mounted) setState(() {}); // croix « effacer » du champ
    _planifierComptage();
  }

  void _planifierComptage() {
    _attente?.cancel();
    _attente = Timer(widget.delaiComptage, _compter);
  }

  Future<void> _compter() async {
    if (_erreurPrix != null) return;
    final numero = ++_numeroComptage;
    try {
      final n = await widget.compter(_filtre);
      if (mounted && numero == _numeroComptage) setState(() => _nbResultats = n);
    } catch (_) {
      if (mounted && numero == _numeroComptage) setState(() => _nbResultats = null);
    }
  }

  void _changer(VoidCallback modification) {
    setState(modification);
    _planifierComptage();
  }

  void _choisirOffre(TypeOffre? o) => _changer(() {
        _offre = o;
        // Changement d'échelle (DT/mois <-> DT) : l'ancienne fourchette n'a plus de sens.
        _prixMin = _prixMax = null;
        _min.clear();
        _max.clear();
      });

  void _glisserPrix(RangeValues v) {
    final e = echellePrix(_offre);
    setState(() {
      _prixMin = v.start <= 0 ? null : v.start.roundToDouble();
      _prixMax = v.end >= e.max ? null : v.end.roundToDouble();
      _min.text = _prixMin == null ? '' : formaterPrix(_prixMin!);
      _max.text = _prixMax == null ? '' : formaterPrix(_prixMax!);
    });
  }

  void _reinitialiser() {
    _ville.clear();
    _min.clear();
    _max.clear();
    _changer(() {
      _offre = null;
      _type = null;
      _prixMin = _prixMax = null;
      _sPlus = null;
    });
  }

  String get _libelleBouton => switch (_nbResultats) {
        null => 'Afficher les annonces',
        0 => 'Aucun bien trouvé',
        1 => 'Afficher 1 annonce',
        final n => 'Afficher $n annonces',
      };

  @override
  Widget build(BuildContext context) {
    final e = echellePrix(_offre);
    final debut = (_prixMin ?? 0).clamp(0, e.max).toDouble();
    final fin = (_prixMax ?? e.max).clamp(debut, e.max).toDouble();
    final unite = _offre == TypeOffre.location ? 'DT/mois' : 'DT';
    final resumePrix = _prixMin == null && _prixMax == null
        ? 'Tous les prix'
        : '${_prixMin == null ? '0' : formaterPrix(_prixMin!)} – ${_prixMax == null ? 'sans limite' : formaterPrix(_prixMax!)}';

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(children: [
              const Expanded(
                child: Text('Filtres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DarColors.text)),
              ),
              TextButton(
                onPressed: _reinitialiser,
                child: const Text('Réinitialiser', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<_Offre>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _Offre.tous, label: Text('Tous')),
                    ButtonSegment(value: _Offre.vente, label: Text('Acheter')),
                    ButtonSegment(value: _Offre.location, label: Text('Louer')),
                  ],
                  selected: {_Offre.depuis(_offre)},
                  onSelectionChanged: (s) => _choisirOffre(s.first.offre),
                ),
                const _Titre('Type de bien'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in TypeBien.values)
                    ChoiceChip(
                      avatar: Icon(_iconeType(t), size: 16),
                      label: Text(t.libelle),
                      selected: _type == t,
                      onSelected: (choisi) => _changer(() {
                        _type = choisi ? t : null;
                        if (_type == TypeBien.terrain) _sPlus = null; // un terrain n'a pas de pièces
                      }),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 22, bottom: 4),
                  child: Row(children: [
                    Expanded(child: Text('Prix ($unite)', style: _Titre.style)),
                    Text(resumePrix,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DarColors.primary)),
                  ]),
                ),
                RangeSlider(
                  values: RangeValues(debut, fin),
                  min: 0,
                  max: e.max,
                  divisions: (e.max / e.pas).round(),
                  onChanged: _glisserPrix,
                  onChangeEnd: (_) => _planifierComptage(),
                ),
                Row(children: [
                  Expanded(child: _champPrix(_min, 'Min', (v) => _prixMin = v)),
                  const SizedBox(width: 10),
                  Expanded(child: _champPrix(_max, 'Max', (v) => _prixMax = v)),
                ]),
                if (_erreurPrix case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(message,
                        style: const TextStyle(color: DarColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                const _Titre('Ville'),
                _champVille(),
                if (_type != TypeBien.terrain) ...[
                  const _Titre('Nombre de pièces minimum'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ChoiceChip(label: const Text('Tous'), selected: _sPlus == null, onSelected: (_) => _changer(() => _sPlus = null)),
                    for (final n in sPlusProposes)
                      ChoiceChip(
                        label: Text(n == sPlusProposes.last ? 'S+$n +' : 'S+$n'),
                        selected: _sPlus == n,
                        onSelected: (choisi) => _changer(() => _sPlus = choisi ? n : null),
                      ),
                  ]),
                ],
              ]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: _erreurPrix == null ? () => Navigator.pop(context, _filtre) : null,
                child: Text(_libelleBouton),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _champPrix(TextEditingController c, String libelle, void Function(double?) enregistrer) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: libelle, labelText: libelle, isDense: true),
        onChanged: (texte) => _changer(() => enregistrer(lireNombre(texte))),
      );

  Widget _champVille() => RawAutocomplete<String>(
        textEditingController: _ville,
        focusNode: _focusVille,
        optionsBuilder: (saisie) {
          final t = saisie.text.trim().toLowerCase();
          if (t.isEmpty) return _villes;
          return _villes.where((v) => v.toLowerCase().contains(t) && v.toLowerCase() != t);
        },
        fieldViewBuilder: (context, controleur, focus, valider) => TextField(
          controller: controleur,
          focusNode: focus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Toutes les villes',
            prefixIcon: const Icon(Icons.place_outlined),
            suffixIcon: controleur.text.isEmpty
                ? null
                : IconButton(tooltip: 'Effacer la ville', icon: const Icon(Icons.close), onPressed: controleur.clear),
          ),
          onSubmitted: (_) => valider(),
        ),
        optionsViewBuilder: (context, choisir, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 350),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final v in options)
                    ListTile(dense: true, leading: const Icon(Icons.place_outlined, size: 18), title: Text(v), onTap: () => choisir(v)),
                ],
              ),
            ),
          ),
        ),
      );

  static IconData _iconeType(TypeBien t) => switch (t) {
        TypeBien.appartement => Icons.apartment_outlined,
        TypeBien.villa => Icons.home_outlined,
        TypeBien.terrain => Icons.landscape_outlined,
        TypeBien.local => Icons.storefront_outlined,
      };
}

/// Le sélecteur a besoin d'une valeur pour « Tous » (pas de null dans un Set de segments).
enum _Offre {
  tous(null),
  vente(TypeOffre.vente),
  location(TypeOffre.location);

  const _Offre(this.offre);
  final TypeOffre? offre;

  static _Offre depuis(TypeOffre? o) => values.firstWhere((v) => v.offre == o);
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  static const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DarColors.text);

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 22, bottom: 10), child: Text(texte, style: style));
}
