// =====================================================================
// DarImmo - [3.3] Consulter le détail d'une annonce (maquette B4)
// Tâche du membre B, réalisée par le membre C.
//
// Critères : galerie de photos défilante ; description, surface, pièces,
// prix, ville ; nom de l'annonceur ; emplacement du bouton Contacter (7.1).
//
// L'annonceur et l'admin voient aussi les annonces non publiées (RLS) :
// on l'indique par un bandeau (utile depuis Mes annonces, la notification
// 8.2, et pour l'admin en 9.2).
//
// [5.1] cœur favori : paramètre boutonFavori (module favorites, fait par C).
// À brancher plus tard par le membre B (emplacements marqués [x.y]) :
// [3.4] « Signaler cette annonce », [3.8] partager.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:darimmo/core/carte/carte_darimmo.dart';
import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/chat/presentation/widgets/avatar_darimmo.dart';
import 'package:darimmo/features/detail/data/models/annonce_detail.dart';
import 'package:darimmo/features/detail/data/repositories/detail_repository.dart';
import 'package:darimmo/features/detail/presentation/viewmodels/detail_view_model.dart';
import 'package:darimmo/features/detail/presentation/widgets/galerie_photos.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show StatutAnnonce, TypeOffre;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;
import 'package:darimmo/features/publish/presentation/widgets/annonce_card.dart' show StatutBadge;

const _moisFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// « Membre depuis novembre 2026 · 8 annonces »
String sousTitreAnnonceur(Annonceur a, int? nbAnnonces) {
  final morceaux = <String>[
    if (a.dateInscription != null)
      'Membre depuis ${_moisFr[a.dateInscription!.toLocal().month - 1]} ${a.dateInscription!.toLocal().year}',
    if (nbAnnonces != null) nbAnnonces <= 1 ? '$nbAnnonces annonce' : '$nbAnnonces annonces',
  ];
  return morceaux.join(' · ');
}

class DetailAnnoncePage extends StatefulWidget {
  const DetailAnnoncePage({
    super.key,
    required this.idAnnonce,
    required this.repository,
    required this.boutonContacter,
    required this.onQuitter,
    this.boutonFavori,
    this.afficherTuilesCarte = true,
  });

  final String idAnnonce;
  final DetailRepository repository;

  /// [7.1] Construit le bouton « Contacter » ; [idAnnonceur] (colonne
  /// annonces.id_annonceur) sert à le désactiver sur ses propres annonces.
  final Widget Function(String? idAnnonceur) boutonContacter;

  /// Retour quand rien n'est en dessous (page ouverte par une notification).
  final void Function(BuildContext context) onQuitter;

  /// [5.1] Cœur à gauche du bouton Contacter (maquette B4).
  final Widget? boutonFavori;

  /// false dans les tests : pas de téléchargement de tuiles.
  final bool afficherTuilesCarte;

  @override
  State<DetailAnnoncePage> createState() => _DetailAnnoncePageState();
}

class _DetailAnnoncePageState extends State<DetailAnnoncePage> {
  late final _vm = DetailViewModel(repository: widget.repository, idAnnonce: widget.idAnnonce)..charger();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _retour() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      widget.onQuitter(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final a = _vm.annonce;
        if (a != null) return _contenu(a);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Annonce'),
            leading: IconButton(tooltip: 'Retour', icon: const Icon(Icons.arrow_back), onPressed: _retour),
          ),
          body: _vm.erreur == null ? const Center(child: CircularProgressIndicator()) : _erreur(),
        );
      },
    );
  }

  Widget _erreur() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_vm.introuvable ? Icons.search_off : Icons.wifi_off, size: 48, color: DarColors.muted),
            const SizedBox(height: 14),
            Text(_vm.erreur!,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: DarColors.text2, height: 1.4)),
            const SizedBox(height: 20),
            if (!_vm.introuvable)
              FilledButton.icon(onPressed: _vm.charger, icon: const Icon(Icons.refresh), label: const Text('Réessayer'))
            else
              OutlinedButton(onPressed: _retour, child: const Text('Retour')),
          ]),
        ),
      );

  Widget _contenu(AnnonceDetail a) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // icônes blanches sur la photo
      child: Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          GaleriePhotos(photos: a.photos, type: a.typeBien, onRetour: _retour),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!a.estPubliee) ...[
                _BandeauStatut(statut: a.statut),
                const SizedBox(height: 16),
              ],
              _EnTete(annonce: a),
              const SizedBox(height: 16),
              _Caracteristiques(annonce: a),
              if ((a.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                const _Titre('Description'),
                const SizedBox(height: 8),
                _Description(texte: a.description!.trim()),
              ],
              const SizedBox(height: 20),
              _CarteAnnonceur(annonce: a),
              if (a.aUnePosition) ...[
                const SizedBox(height: 20),
                const _Titre('Emplacement'),
                const SizedBox(height: 10),
                _MiniCarte(
                  position: LatLng(a.latitude!, a.longitude!),
                  afficherTuiles: widget.afficherTuilesCarte,
                ),
              ],
              // [3.4] membre B : lien « Signaler cette annonce » ici (maquette B4).
            ]),
          ),
        ]),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: DarColors.surface,
            border: Border(top: BorderSide(color: DarColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(children: [
                if (widget.boutonFavori case final favori?) ...[favori, const SizedBox(width: 12)],
                Expanded(child: widget.boutonContacter(a.idAnnonceur)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) =>
      Text(texte, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DarColors.text));
}

class _BandeauStatut extends StatelessWidget {
  const _BandeauStatut({required this.statut});
  final StatutAnnonce statut;

  String get _explication => switch (statut) {
        StatutAnnonce.brouillon => 'Brouillon : cette annonce n’a pas encore été envoyée pour validation.',
        StatutAnnonce.enAttente => 'En attente de validation : seuls vous et l’administrateur la voyez.',
        StatutAnnonce.rejetee => 'Annonce rejetée : elle n’est pas visible par les autres utilisateurs.',
        StatutAnnonce.vendue => 'Ce bien est vendu : l’annonce n’apparaît plus dans les recherches.',
        StatutAnnonce.louee => 'Ce bien est loué : l’annonce n’apparaît plus dans les recherches.',
        StatutAnnonce.masquee => 'Annonce masquée par l’administrateur.',
        StatutAnnonce.publiee => '',
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatutBadge(statut: statut),
          const SizedBox(height: 8),
          Text(_explication, style: const TextStyle(fontSize: 13.5, height: 1.4, color: DarColors.text2)),
        ]),
      );
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte, required this.couleur, required this.fond, this.icone});
  final String texte;
  final Color couleur;
  final Color fond;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icone != null) ...[Icon(icone, size: 13, color: couleur), const SizedBox(width: 4)],
          Text(texte,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: couleur, letterSpacing: 0.6)),
        ]),
      );
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.annonce});
  final AnnonceDetail annonce;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final location = a.typeOffre == TypeOffre.location;
    final m2 = a.prixAuM2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, children: [
        _Pastille(
          texte: '${a.typeBien.libelle.toUpperCase()} · ${location ? 'LOCATION' : 'VENTE'}',
          couleur: DarColors.accent,
          fond: const Color(0xFFF7E9DF),
        ),
        // Publiée = validée par l'administrateur (9.2).
        if (a.estPubliee)
          const _Pastille(
              texte: 'VÉRIFIÉE', couleur: DarColors.success, fond: DarColors.successSoft, icone: Icons.verified_outlined),
      ]),
      const SizedBox(height: 10),
      Text(a.titre,
          style: const TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w800, color: DarColors.text)),
      if (a.lieu != null) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 16, color: DarColors.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(a.lieu!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DarColors.muted)),
          ),
        ]),
      ],
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: formaterPrix(a.prix),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: DarColors.primary)),
            TextSpan(
                text: location ? ' DT/mois' : ' DT',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DarColors.primary)),
          ])),
        ),
        if (m2 != null)
          Text('≈ ${formaterPrix(m2.roundToDouble())} DT/m²',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
      ]),
    ]);
  }
}

class _Caracteristiques extends StatelessWidget {
  const _Caracteristiques({required this.annonce});
  final AnnonceDetail annonce;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final surface = a.surface;
    final tuiles = <Widget>[
      if (surface != null && surface > 0)
        _Tuile(icone: Icons.open_in_full, valeur: '${formaterPrix(surface)} m²', libelle: 'Surface'),
      if (a.libelleTaille != null) _Tuile(icone: Icons.bed_outlined, valeur: a.libelleTaille!, libelle: 'Pièces'),
      _Tuile(icone: PhotoAnnonce.iconeType(a.typeBien), valeur: a.typeBien.libelle, libelle: 'Type'),
      _Tuile(
        icone: Icons.sell_outlined,
        valeur: a.typeOffre == TypeOffre.location ? 'Location' : 'Vente',
        libelle: 'Offre',
      ),
    ];
    return Row(children: [
      for (var i = 0; i < tuiles.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: tuiles[i]),
      ],
    ]);
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({required this.icone, required this.valeur, required this.libelle});
  final IconData icone;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: DarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarColors.border),
        ),
        child: Column(children: [
          Icon(icone, size: 20, color: DarColors.primary),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(libelle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DarColors.muted)),
        ]),
      );
}

/// Description repliée sur 4 lignes, « Lire la suite » si elle est plus longue.
class _Description extends StatefulWidget {
  const _Description({required this.texte});
  final String texte;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  static const _style = TextStyle(fontSize: 15, height: 1.5, color: DarColors.text2);
  static const _lignes = 4;
  bool _ouverte = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, contraintes) {
      final mesure = TextPainter(
        text: TextSpan(text: widget.texte, style: _style),
        maxLines: _lignes,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: contraintes.maxWidth);
      final tropLong = mesure.didExceedMaxLines;
      mesure.dispose();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.texte,
            style: _style,
            maxLines: _ouverte ? null : _lignes,
            overflow: _ouverte ? TextOverflow.visible : TextOverflow.ellipsis),
        if (tropLong)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
            onPressed: () => setState(() => _ouverte = !_ouverte),
            child: Text(_ouverte ? 'Réduire' : 'Lire la suite',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
      ]);
    });
  }
}

class _CarteAnnonceur extends StatelessWidget {
  const _CarteAnnonceur({required this.annonce});
  final AnnonceDetail annonce;

  @override
  Widget build(BuildContext context) {
    final p = annonce.annonceur;
    final sousTitre = sousTitreAnnonceur(p, annonce.nbAnnoncesAnnonceur);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarColors.border),
      ),
      child: Row(children: [
        AvatarDarImmo(url: p.photoUrl, initiales: p.initiales, taille: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Annonceur',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DarColors.muted, letterSpacing: 0.4)),
            Text(p.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            if (sousTitre.isNotEmpty)
              Text(sousTitre, style: const TextStyle(fontSize: 12, color: DarColors.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _MiniCarte extends StatelessWidget {
  const _MiniCarte({required this.position, required this.afficherTuiles});
  final LatLng position;
  final bool afficherTuiles;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 170,
          child: CarteDarImmo(
            key: const Key('mini-carte'),
            centre: position,
            zoom: 15,
            gestes: InteractiveFlag.none, // aperçu : la page défile, pas la carte
            afficherTuiles: afficherTuiles,
            marqueurs: [
              Marker(
                point: position,
                width: 46,
                height: 46,
                alignment: Alignment.topCenter,
                child: const PinDarImmo(taille: 46),
              ),
            ],
          ),
        ),
      );
}
