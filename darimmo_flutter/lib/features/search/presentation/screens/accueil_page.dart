import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// 1. MODÈLE
// ============================================================
class AnnonceRecherche {
  final String id;
  final String titre;
  final String? description;
  final String typeBien;
  final String typeOffre;
  final num prix;
  final num? surface;
  final int? nbPieces;
  final String? adresse;
  final String? ville;
  final double? latitude;
  final double? longitude;
  final String statut;
  final String idAnnonceur;
  final DateTime dateCreation;
  final List<String> photos;

  const AnnonceRecherche({
    required this.id,
    required this.titre,
    this.description,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    this.surface,
    this.nbPieces,
    this.adresse,
    this.ville,
    this.latitude,
    this.longitude,
    required this.statut,
    required this.idAnnonceur,
    required this.dateCreation,
    this.photos = const [],
  });

  String? get photoCouverture => photos.isEmpty ? null : photos.first;

  factory AnnonceRecherche.fromMap(Map<String, dynamic> m) {
    final rawPhotos = (m['photos'] as List?) ?? const [];
    final sorted = rawPhotos
        .cast<Map<String, dynamic>>()
        .where((p) => p['url'] != null)
        .toList()
      ..sort((a, b) =>
          (a['ordre'] as int? ?? 0).compareTo(b['ordre'] as int? ?? 0));

    return AnnonceRecherche(
      id: m['id'].toString(),
      titre: m['titre'] as String,
      description: m['description'] as String?,
      typeBien: m['type_bien'] as String,
      typeOffre: m['type_offre'] as String,
      prix: m['prix'] as num,
      surface: m['surface'] as num?,
      nbPieces: m['nb_pieces'] as int?,
      adresse: m['adresse'] as String?,
      ville: m['ville'] as String?,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      statut: m['statut'] as String,
      idAnnonceur: m['id_annonceur'].toString(),
      dateCreation: DateTime.parse(m['date_creation'] as String),
      photos: sorted.map((p) => p['url'] as String).toList(),
    );
  }
}

// ============================================================
// 2. FILTRE
// ============================================================
class FiltreRecherche {
  final String? typeOffre;
  final String? typeBien;
  final double? prixMin;
  final double? prixMax;
  final String? ville;
  final int? nbPiecesMin;

  const FiltreRecherche({
    this.typeOffre,
    this.typeBien,
    this.prixMin,
    this.prixMax,
    this.ville,
    this.nbPiecesMin,
  });

  static const vide = FiltreRecherche();

  bool get estVide =>
      typeOffre == null &&
      typeBien == null &&
      prixMin == null &&
      prixMax == null &&
      (ville == null || ville!.isEmpty) &&
      nbPiecesMin == null;

  FiltreRecherche copyWith({
    String? Function()? typeOffre,
    String? Function()? typeBien,
    double? Function()? prixMin,
    double? Function()? prixMax,
    String? Function()? ville,
    int? Function()? nbPiecesMin,
  }) {
    return FiltreRecherche(
      typeOffre: typeOffre != null ? typeOffre() : this.typeOffre,
      typeBien: typeBien != null ? typeBien() : this.typeBien,
      prixMin: prixMin != null ? prixMin() : this.prixMin,
      prixMax: prixMax != null ? prixMax() : this.prixMax,
      ville: ville != null ? ville() : this.ville,
      nbPiecesMin: nbPiecesMin != null ? nbPiecesMin() : this.nbPiecesMin,
    );
  }
}

// ============================================================
// 3. REPOSITORY (requêtes Supabase)
// ============================================================
class RechercheRepository {
  RechercheRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;
  static const pageSize = 10;

  Future<List<AnnonceRecherche>> fetchPage({
    required int page,
    FiltreRecherche filter = FiltreRecherche.vide,
  }) async {
    var query = _db
        .from('annonces')
        .select('*, photos(url, ordre)')
        .eq('statut', 'publiee');

    if (filter.typeOffre != null) {
      query = query.eq('type_offre', filter.typeOffre!);
    }
    if (filter.typeBien != null) {
      query = query.eq('type_bien', filter.typeBien!);
    }
    if (filter.prixMin != null) query = query.gte('prix', filter.prixMin!);
    if (filter.prixMax != null) query = query.lte('prix', filter.prixMax!);
    if (filter.nbPiecesMin != null) {
      query = query.gte('nb_pieces', filter.nbPiecesMin!);
    }
    if (filter.ville != null && filter.ville!.trim().isNotEmpty) {
      query = query.ilike('ville', '%${filter.ville!.trim()}%');
    }

    final from = page * pageSize;
    final data = await query
        .order('date_creation', ascending: false)
        .range(from, from + pageSize - 1);

    return (data as List)
        .map((e) => AnnonceRecherche.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> count(FiltreRecherche filter) async {
    var query = _db.from('annonces').select('id').eq('statut', 'publiee');

    if (filter.typeOffre != null) {
      query = query.eq('type_offre', filter.typeOffre!);
    }
    if (filter.typeBien != null) {
      query = query.eq('type_bien', filter.typeBien!);
    }
    if (filter.prixMin != null) query = query.gte('prix', filter.prixMin!);
    if (filter.prixMax != null) query = query.lte('prix', filter.prixMax!);
    if (filter.nbPiecesMin != null) {
      query = query.gte('nb_pieces', filter.nbPiecesMin!);
    }
    if (filter.ville != null && filter.ville!.trim().isNotEmpty) {
      query = query.ilike('ville', '%${filter.ville!.trim()}%');
    }

    final res = await query.count(CountOption.exact);
    return res.count;
  }
}

// ============================================================
// 4. CARTE D'ANNONCE
// ============================================================
class _AnnonceCard extends StatelessWidget {
  const _AnnonceCard({required this.annonce, required this.onTap});

  final AnnonceRecherche annonce;
  final VoidCallback onTap;

  String get _prix {
    final s = annonce.prix.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf DT${annonce.typeOffre == 'location' ? ' / mois' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: annonce.photoCouverture == null
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.home_work_outlined, size: 48),
                        )
                      : Image.network(
                          annonce.photoCouverture!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: annonce.typeOffre == 'vente'
                          ? Colors.orange
                          : Colors.teal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      annonce.typeOffre.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${annonce.typeBien.toUpperCase()} · ${annonce.typeOffre.toUpperCase()}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.orange.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    annonce.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (annonce.ville != null)
                    Row(children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(annonce.ville!, style: theme.textTheme.bodySmall),
                    ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _prix,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                      Row(children: [
                        if (annonce.surface != null)
                          Text('${annonce.surface!.round()} m²  '),
                        if (annonce.nbPieces != null)
                          Text('S+${annonce.nbPieces}'),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. FEUILLE DE FILTRES (B2)
// ============================================================
Future<FiltreRecherche?> showFiltresSheet(
  BuildContext context, {
  required FiltreRecherche initial,
  required RechercheRepository repo,
}) {
  return showModalBottomSheet<FiltreRecherche>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FiltresSheet(initial: initial, repo: repo),
  );
}

class _FiltresSheet extends StatefulWidget {
  const _FiltresSheet({required this.initial, required this.repo});
  final FiltreRecherche initial;
  final RechercheRepository repo;

  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  static const _prixMaxSlider = 3000000.0;
  static const _types = {
    'appartement': 'Appartement',
    'villa': 'Villa',
    'terrain': 'Terrain',
    'local': 'Local',
  };

  late String _offre;
  String? _typeBien;
  late RangeValues _prix;
  late final TextEditingController _ville;
  int? _pieces;
  int? _nbResultats;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _offre = f.typeOffre ?? 'vente';
    _typeBien = f.typeBien;
    _prix = RangeValues(f.prixMin ?? 0, f.prixMax ?? _prixMaxSlider);
    _ville = TextEditingController(text: f.ville ?? '');
    _pieces = f.nbPiecesMin;
    _rafraichirCompteur();
  }

  @override
  void dispose() {
    _ville.dispose();
    super.dispose();
  }

  FiltreRecherche get _filtre => FiltreRecherche(
        typeOffre: _offre,
        typeBien: _typeBien,
        prixMin: _prix.start > 0 ? _prix.start : null,
        prixMax: _prix.end < _prixMaxSlider ? _prix.end : null,
        ville: _ville.text.trim().isEmpty ? null : _ville.text.trim(),
        nbPiecesMin: _pieces,
      );

  Future<void> _rafraichirCompteur() async {
    try {
      final n = await widget.repo.count(_filtre);
      if (mounted) setState(() => _nbResultats = n);
    } catch (_) {}
  }

  void _maj(VoidCallback fn) {
    setState(fn);
    _rafraichirCompteur();
  }

  void _reinitialiser() {
    _ville.clear();
    _maj(() {
      _offre = 'vente';
      _typeBien = null;
      _prix = const RangeValues(0, _prixMaxSlider);
      _pieces = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                    onPressed: _reinitialiser,
                    child: const Text('Réinitialiser')),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'vente', label: Text('Acheter')),
                ButtonSegment(value: 'location', label: Text('Louer')),
              ],
              selected: {_offre},
              onSelectionChanged: (s) => _maj(() => _offre = s.first),
            ),
            const SizedBox(height: 20),
            const Text('Type de bien',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: _types.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _typeBien == e.key,
                        onSelected: (sel) =>
                            _maj(() => _typeBien = sel ? e.key : null),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Prix : ${_prix.start.round()} DT – '
              '${_prix.end >= _prixMaxSlider ? "illimité" : "${_prix.end.round()} DT"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RangeSlider(
              values: _prix,
              min: 0,
              max: _prixMaxSlider,
              divisions: 60,
              onChanged: (v) => setState(() => _prix = v),
              onChangeEnd: (_) => _rafraichirCompteur(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ville,
              decoration: const InputDecoration(
                labelText: 'Ville',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _rafraichirCompteur(),
            ),
            const SizedBox(height: 20),
            const Text('Pièces minimum',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _pieces == null,
                  onSelected: (_) => _maj(() => _pieces = null),
                ),
                for (final n in [1, 2, 3, 4])
                  ChoiceChip(
                    label: Text('S+$n${n == 4 ? "+" : ""}'),
                    selected: _pieces == n,
                    onSelected: (_) => _maj(() => _pieces = n),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _filtre),
                child: Text(_nbResultats == null
                    ? 'Afficher les annonces'
                    : 'Afficher $_nbResultats annonces'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. ÉCRAN D'ACCUEIL (B1)
// ============================================================
class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final _repo = RechercheRepository();
  final _scroll = ScrollController();

  final List<AnnonceRecherche> _annonces = [];
  FiltreRecherche _filtre = FiltreRecherche.vide;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  Object? _erreur;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) _charger();
    });
    _charger();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final batch = await _repo.fetchPage(page: _page, filter: _filtre);
      if (!mounted) return;
      setState(() {
        _annonces.addAll(batch);
        _hasMore = batch.length == RechercheRepository.pageSize;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recharger([FiltreRecherche? nouveau]) async {
    setState(() {
      if (nouveau != null) _filtre = nouveau;
      _annonces.clear();
      _page = 0;
      _hasMore = true;
    });
    await _charger();
  }

  Future<void> _ouvrirFiltres() async {
    final res = await showFiltresSheet(context, initial: _filtre, repo: _repo);
    if (res != null) _recharger(res);
  }

  Widget _chipsRapides() {
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onTap()),
        );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('Tous', _filtre.estVide,
              () => _recharger(FiltreRecherche.vide)),
          chip('Vente', _filtre.typeOffre == 'vente',
              () => _recharger(_filtre.copyWith(typeOffre: () => 'vente'))),
          chip('Location', _filtre.typeOffre == 'location',
              () => _recharger(_filtre.copyWith(typeOffre: () => 'location'))),
          chip(
              'Appartement',
              _filtre.typeBien == 'appartement',
              () => _recharger(
                  _filtre.copyWith(typeBien: () => 'appartement'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Trouvez votre chez-vous',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Villa, quartier, ville…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => _recharger(_filtre.copyWith(
                        ville: () => v.trim().isEmpty ? null : v.trim())),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _ouvrirFiltres, icon: const Icon(Icons.tune)),
              ]),
            ),
            const SizedBox(height: 8),
            _chipsRapides(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Annonces récentes',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(child: _corps()),
          ],
        ),
      ),
    );
  }

  Widget _corps() {
    if (_annonces.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_annonces.isEmpty && _erreur != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Impossible de charger les annonces.'),
          TextButton(
              onPressed: () => _recharger(), child: const Text('Réessayer')),
        ]),
      );
    }
    if (_annonces.isEmpty) {
      return const Center(
          child: Text('Aucune annonce ne correspond à vos critères.'));
    }
    return RefreshIndicator(
      onRefresh: () => _recharger(),
      child: ListView.builder(
        controller: _scroll,
        itemCount: _annonces.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _annonces.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final a = _annonces[i];
          return _AnnonceCard(
            annonce: a,
            onTap: () => context.push('/annonces/${a.id}'),
          );
        },
      ),
    );
  }
}