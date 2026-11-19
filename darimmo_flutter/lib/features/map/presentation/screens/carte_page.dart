// =====================================================================
// DarImmo - [4.1] Voir les annonces sur une carte
//           [4.2] Voir les biens autour de moi          (maquette B3)
// Tâches du membre B, réalisées par le membre C.
//
// 4.1 : un marqueur (prix) par bien publié ; toucher un marqueur affiche
//       l'aperçu (photo + prix) ; toucher l'aperçu ouvre le détail (3.3).
// 4.2 : « Autour de moi » demande l'autorisation de localisation, centre la
//       carte sur ma position et affiche les biens du rayon choisi (fonction
//       PostGIS annonces_autour en RPC) ; message explicatif si refus.
//
// Composant de carte partagé : core/carte/carte_darimmo.dart (OpenStreetMap).
// =====================================================================
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:darimmo/core/carte/carte_darimmo.dart';
import 'package:darimmo/core/location/localisation.dart';
import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/map/data/models/annonce_carte.dart';
import 'package:darimmo/features/map/data/repositories/carte_repository.dart';
import 'package:darimmo/features/map/presentation/viewmodels/carte_view_model.dart';
import 'package:darimmo/features/map/presentation/widgets/apercu_annonce_carte.dart';
import 'package:darimmo/features/map/presentation/widgets/pin_prix.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeOffre;

/// « 1 bien », « 3 biens », « aucun bien ».
String nombreDeBiens(int n) => switch (n) {
      0 => 'aucun bien',
      1 => '1 bien',
      _ => '$n biens',
    };

/// Rectangle qui contient le cercle de [rayonM] mètres autour de [centre].
LatLngBounds cadreDuRayon(LatLng centre, int rayonM) {
  const metresParDegre = 111320.0;
  final dLat = rayonM / metresParDegre;
  final dLng = rayonM / (metresParDegre * math.cos(centre.latitude * math.pi / 180));
  return LatLngBounds(
    LatLng(centre.latitude - dLat, centre.longitude - dLng),
    LatLng(centre.latitude + dLat, centre.longitude + dLng),
  );
}

class CartePage extends StatefulWidget {
  const CartePage({
    super.key,
    required this.repository,
    required this.localisation,
    required this.onOuvrirAnnonce,
    required this.onQuitter,
    this.afficherTuiles = true,
  });

  final CarteRepository repository;
  final Localisation localisation;

  /// Toucher l'aperçu : ouvre le détail de l'annonce (3.3).
  final void Function(BuildContext context, String idAnnonce) onOuvrirAnnonce;

  /// Retour quand rien n'est en dessous (lien direct vers /carte).
  final void Function(BuildContext context) onQuitter;

  /// false dans les tests : pas de téléchargement de tuiles.
  final bool afficherTuiles;

  @override
  State<CartePage> createState() => _CartePageState();
}

class _CartePageState extends State<CartePage> {
  late final _vm = CarteViewModel(repository: widget.repository, localisation: widget.localisation);
  final _carte = MapController();

  /// La carte a sa taille : on peut la déplacer.
  bool _prete = false;

  /// Les annonces ont été cadrées une première fois (on ne recadre plus tout
  /// seul ensuite : l'utilisateur a peut-être déplacé la carte).
  bool _cadree = false;

  /// Marges pour que les marqueurs ne passent pas sous la barre du haut ni sous l'aperçu.
  static const _marges = EdgeInsets.fromLTRB(40, 190, 40, 210);

  @override
  void initState() {
    super.initState();
    _vm.afficherToutes().then((_) => _cadrerToutes(premiereFois: true));
  }

  @override
  void dispose() {
    _vm.dispose();
    _carte.dispose();
    super.dispose();
  }

  void _surCartePrete() {
    _prete = true;
    _cadrerToutes(premiereFois: true);
  }

  void _cadrerToutes({bool premiereFois = false}) {
    if (!mounted || !_prete || (premiereFois && _cadree)) return;
    final points = [for (final a in _vm.annonces) a.position];
    if (points.isEmpty) return;
    _cadree = true;
    if (points.length == 1) {
      _carte.move(points.first, 14);
    } else {
      _carte.fitCamera(CameraFit.coordinates(coordinates: points, padding: _marges, maxZoom: 15));
    }
  }

  void _cadrerRayon() {
    final centre = _vm.maPosition;
    if (!mounted || !_prete || centre == null) return;
    _cadree = true;
    _carte.fitCamera(CameraFit.bounds(bounds: cadreDuRayon(centre, _vm.rayonKm * 1000), padding: _marges));
  }

  Future<void> _autourDeMoi() async {
    if (await _vm.activerAutourDeMoi()) _cadrerRayon();
  }

  Future<void> _basculerAutourDeMoi() async {
    if (_vm.mode == ModeCarte.autour) {
      await _vm.afficherToutes();
      _cadrerToutes();
    } else {
      await _autourDeMoi();
    }
  }

  void _changerRayon(int km) {
    _vm.changerRayon(km);
    _cadrerRayon(); // tout de suite : le cercle change de taille avant même la réponse
  }

  void _retour() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      widget.onQuitter(context);
    }
  }

  List<Marker> _marqueurs() {
    final choisie = _vm.selection;
    // L'annonce choisie en dernier : dessinée au-dessus des autres.
    final ordre = [..._vm.annonces.where((a) => a.id != choisie?.id), ?choisie];
    return [
      if (_vm.mode == ModeCarte.autour && _vm.maPosition != null)
        Marker(point: _vm.maPosition!, width: 54, height: 54, child: const PointMaPosition()),
      for (final a in ordre)
        Marker(
          key: ValueKey('pin-${a.id}'),
          point: a.position,
          width: 130,
          height: 40,
          child: Center(
            child: PinPrix(
              libelle: libellePrixCourt(a),
              choisi: a.id == choisie?.id,
              location: a.typeOffre == TypeOffre.location,
              description: '${a.titre}, ${libellePrixComplet(a)}',
              onTap: () => _vm.selectionner(a.id),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarColors.surface2,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final autour = _vm.mode == ModeCarte.autour;
          final selection = _vm.selection;
          return Stack(children: [
            Positioned.fill(
              child: CarteDarImmo(
                controller: _carte,
                zoom: 7, // toute la Tunisie le temps du chargement
                afficherTuiles: widget.afficherTuiles,
                onPrete: _surCartePrete,
                onTap: (_) => _vm.selectionner(null),
                couches: [
                  if (autour && _vm.maPosition != null)
                    CircleLayer(circles: [
                      CircleMarker(
                        point: _vm.maPosition!,
                        radius: _vm.rayonKm * 1000.0,
                        useRadiusInMeter: true,
                        color: DarColors.primary.withValues(alpha: 0.10),
                        borderColor: DarColors.primary.withValues(alpha: 0.45),
                        borderStrokeWidth: 2,
                      ),
                    ]),
                ],
                marqueurs: _marqueurs(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    _BoutonRond(icone: Icons.arrow_back, aide: 'Retour', onTap: _retour),
                    const SizedBox(width: 10),
                    Expanded(child: _Resume(vm: _vm)),
                  ]),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      FilterChip(
                        key: const Key('puce-autour'),
                        selected: autour,
                        showCheckmark: false,
                        avatar: _vm.localisationEnCours
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.my_location, size: 18, color: autour ? Colors.white : DarColors.primary),
                        label: const Text('Autour de moi'),
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: autour ? Colors.white : DarColors.text),
                        selectedColor: DarColors.primary,
                        backgroundColor: DarColors.surface,
                        side: BorderSide(color: autour ? DarColors.primary : DarColors.border),
                        onSelected: _vm.localisationEnCours ? null : (_) => _basculerAutourDeMoi(),
                      ),
                      if (autour)
                        for (final km in CarteViewModel.rayonsKm) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('$km km'),
                            selected: _vm.rayonKm == km,
                            showCheckmark: false,
                            selectedColor: DarColors.primarySoft,
                            backgroundColor: DarColors.surface,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _vm.rayonKm == km ? DarColors.primary : DarColors.text2,
                            ),
                            side: BorderSide(color: _vm.rayonKm == km ? DarColors.primary : DarColors.border),
                            onSelected: (_) => _changerRayon(km),
                          ),
                        ],
                    ]),
                  ),
                  if (_vm.messageLocalisation case final message?)
                    _Bandeau(
                      icone: Icons.location_off_outlined,
                      message: message,
                      action: 'Réessayer',
                      onAction: _autourDeMoi,
                      onFermer: _vm.fermerMessageLocalisation,
                    )
                  else if (_vm.erreur case final erreur?)
                    _Bandeau(icone: Icons.wifi_off, message: erreur, action: 'Réessayer', onAction: _vm.reessayer)
                  else if (autour && !_vm.chargement && _vm.annonces.isEmpty)
                    _Bandeau(
                      icone: Icons.search_off,
                      message: _vm.rayonKm < CarteViewModel.rayonsKm.last
                          ? 'Aucun bien publié dans un rayon de ${_vm.rayonKm} km. Choisissez un rayon plus grand.'
                          : 'Aucun bien publié dans un rayon de ${_vm.rayonKm} km.',
                    ),
                ]),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _BoutonRond(
                      icone: Icons.my_location,
                      aide: 'Me localiser',
                      couleur: DarColors.primary,
                      onTap: _vm.localisationEnCours ? null : _autourDeMoi,
                    ),
                    if (selection != null) ...[
                      const SizedBox(height: 12),
                      ApercuAnnonceCarte(
                        annonce: selection,
                        onOuvrir: () => widget.onOuvrirAnnonce(context, selection.id),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Carte blanche flottante : « Toutes les annonces · 15 biens sur la carte ».
class _Resume extends StatelessWidget {
  const _Resume({required this.vm});
  final CarteViewModel vm;

  @override
  Widget build(BuildContext context) {
    final autour = vm.mode == ModeCarte.autour;
    final n = vm.annonces.length;
    final detail = vm.chargement
        ? 'Chargement…'
        : autour
            ? 'Rayon ${vm.rayonKm} km · ${nombreDeBiens(n)}'
            : n == 0
                ? 'Aucune annonce à afficher'
                : '${nombreDeBiens(n)} sur la carte';
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x220B1220), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(children: [
        Icon(autour ? Icons.my_location : Icons.map_outlined, size: 19, color: DarColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(autour ? 'Autour de moi' : 'Toutes les annonces',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DarColors.text)),
            Text(detail, key: const Key('resume-carte'), style: const TextStyle(fontSize: 12, color: DarColors.muted)),
          ]),
        ),
        if (vm.chargement) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({required this.icone, required this.aide, required this.onTap, this.couleur = DarColors.text});
  final IconData icone;
  final String aide;
  final VoidCallback? onTap;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DarColors.surface,
      elevation: 3,
      shadowColor: const Color(0x440B1220),
      borderRadius: BorderRadius.circular(16),
      child: IconButton(
        tooltip: aide,
        onPressed: onTap,
        icon: Icon(icone, color: couleur),
        constraints: const BoxConstraints.tightFor(width: 52, height: 52),
      ),
    );
  }
}

/// Message sous les puces : refus de localisation, erreur réseau, rayon vide.
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.message, this.action, this.onAction, this.onFermer});
  final IconData icone;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onFermer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: DarColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarColors.border),
        boxShadow: const [BoxShadow(color: Color(0x1A0B1220), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(icone, size: 20, color: DarColors.warning),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: DarColors.text2))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        if (onFermer != null)
          IconButton(tooltip: 'Fermer', onPressed: onFermer, icon: const Icon(Icons.close, size: 18, color: DarColors.muted)),
      ]),
    );
  }
}
