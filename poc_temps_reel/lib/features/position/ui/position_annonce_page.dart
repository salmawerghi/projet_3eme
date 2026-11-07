// =====================================================================
// DarImmo - [6.4] Écran « Emplacement » (maquette C3, étape 3 de la publication)
// Membre C
//
// Critères d'acceptation :
//   - marqueur déplaçable (composant de carte partagé, lib/core/carte/)
//   - position actuelle ou recherche d'adresse
//   - latitude et longitude enregistrées ; la position PostGIS est calculée
//     par le trigger annonces_position (02_fonctions.sql)
// =====================================================================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/carte/carte_darimmo.dart';
import '../../../core/darimmo_theme.dart';
import '../data/geocodage.dart';
import '../data/localisation.dart';
import '../position_view_model.dart';

/// Ferme l'écran avec `true` quand le bouton principal a réussi, `null` sur « Retour ».
class PositionAnnoncePage extends StatelessWidget {
  const PositionAnnoncePage({
    super.key,
    required this.geocodage,
    required this.localisation,
    required this.libelleBouton,
    required this.onValider,
    this.positionInitiale,
    this.rechercheInitiale,
    this.iconeBouton = Icons.send_rounded,
    this.afficherTuiles = true,
  });

  final Geocodage geocodage;
  final Localisation localisation;
  final LatLng? positionInitiale;
  final String? rechercheInitiale;
  final String libelleBouton;
  final IconData iconeBouton;

  /// Enregistre la position (et envoie en validation). null = réussi, sinon message d'erreur.
  final Future<String?> Function(LatLng position) onValider;

  /// false dans les tests (pas de tuiles téléchargées).
  final bool afficherTuiles;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PositionViewModel(geocodage, localisation,
          initiale: positionInitiale, rechercheInitiale: rechercheInitiale),
      child: _Contenu(
        libelleBouton: libelleBouton,
        iconeBouton: iconeBouton,
        onValider: onValider,
        afficherTuiles: afficherTuiles,
      ),
    );
  }
}

class _Contenu extends StatefulWidget {
  const _Contenu({required this.libelleBouton, required this.iconeBouton, required this.onValider, required this.afficherTuiles});
  final String libelleBouton;
  final IconData iconeBouton;
  final Future<String?> Function(LatLng position) onValider;
  final bool afficherTuiles;

  @override
  State<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends State<_Contenu> {
  final _carte = MapController();
  final _recherche = TextEditingController();
  bool _cartePrete = false;
  bool _glisser = false; // marqueur en cours de déplacement : la carte ne bouge pas
  bool _validation = false;
  String? _erreurValidation;
  late final PositionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<PositionViewModel>()
      ..onCentrer = _centrer
      ..initialiser();
  }

  @override
  void dispose() {
    _vm.onCentrer = null;
    _carte.dispose();
    _recherche.dispose();
    super.dispose();
  }

  void _centrer(LatLng p) {
    if (!_cartePrete || !mounted) return;
    _carte.move(p, _carte.camera.zoom < 15 ? 16 : _carte.camera.zoom);
  }

  // ----- Glisser le marqueur
  // Le geste « déplacer la carte » de flutter_map gagne toujours l'arbitrage
  // des gestes contre un GestureDetector posé sur le marqueur. On écoute donc
  // le doigt directement (Listener, hors arbitrage) et, dès qu'il touche le
  // marqueur, on interdit à la carte de bouger (InteractiveFlag.none, relu
  // par flutter_map à chaque mouvement).
  DateTime? _finToucherMarqueur;

  void _toucherMarqueur(PointerDownEvent _) => setState(() => _glisser = true);

  void _deplacerMarqueur(PointerMoveEvent e) {
    final p = _vm.position;
    if (p == null || !_glisser) return;
    final camera = _carte.camera;
    _vm.placer(camera.screenOffsetToLatLng(camera.latLngToScreenOffset(p) + e.delta));
  }

  void _lacherMarqueur(PointerEvent _) {
    _finToucherMarqueur = DateTime.now();
    setState(() => _glisser = false);
  }

  /// Toucher la carte place le marqueur, sauf si ce « toucher » était en
  /// réalité un appui sur le marqueur (la carte le reçoit aussi, en retard).
  void _toucherCarte(LatLng point) {
    final fin = _finToucherMarqueur;
    if (_glisser || (fin != null && DateTime.now().difference(fin) < const Duration(milliseconds: 600))) return;
    FocusScope.of(context).unfocus();
    _vm
      ..fermerResultats()
      ..placer(point);
  }

  Future<void> _valider() async {
    final p = _vm.position;
    if (p == null) return;
    setState(() {
      _validation = true;
      _erreurValidation = null;
    });
    final erreur = await widget.onValider(p);
    if (!mounted) return;
    if (erreur == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _validation = false;
        _erreurValidation = erreur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PositionViewModel>();
    final p = vm.position;

    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Emplacement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Étape 3 sur 3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ----- Carte (prend toute la hauteur disponible)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(children: [
                Positioned.fill(
                  child: CarteDarImmo(
                    controller: _carte,
                    centre: p ?? positionParDefaut,
                    zoom: p == null ? 11 : 16,
                    afficherTuiles: widget.afficherTuiles,
                    gestes: _glisser ? InteractiveFlag.none : gestesParDefaut,
                    onPrete: () => _cartePrete = true,
                    onTap: _toucherCarte,
                    marqueurs: [
                      if (p != null)
                        Marker(
                          point: p,
                          width: 64,
                          height: 64,
                          alignment: Alignment.topCenter, // la pointe du marqueur est sur la position
                          child: Semantics(
                            label: 'Marqueur du bien, à faire glisser',
                            child: Listener(
                              key: const Key('marqueur'),
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _toucherMarqueur,
                              onPointerMove: _deplacerMarqueur,
                              onPointerUp: _lacherMarqueur,
                              onPointerCancel: _lacherMarqueur,
                              child: PinDarImmo(taille: 56, souleve: _glisser),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Recherche d'adresse + résultats
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _ChampRecherche(controller: _recherche, enCours: vm.rechercheEnCours, onRechercher: vm.rechercher),
                    if (vm.resultats.isNotEmpty) _Resultats(resultats: vm.resultats, onChoix: (r) {
                      FocusScope.of(context).unfocus();
                      vm.choisirResultat(r);
                    }),
                  ]),
                ),
                if (p != null && vm.resultats.isEmpty)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 72,
                    child: Center(child: _Bulle('Déplacez le marqueur ou touchez la carte')),
                  ),
                // Utiliser ma position
                Positioned(
                  left: 12,
                  bottom: 22,
                  child: Material(
                    color: DarColors.surface,
                    elevation: 3,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: vm.localisationEnCours ? null : vm.utiliserMaPosition,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          vm.localisationEnCours
                              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 16, color: DarColors.primary),
                          const SizedBox(width: 6),
                          const Text('Utiliser ma position',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DarColors.primary)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _Coordonnees(position: p, approximative: vm.approximative),
          for (final e in [vm.erreur, _erreurValidation])
            if (e != null) ...[const SizedBox(height: 10), _Erreur(e)],
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: DarColors.surface,
            border: Border(top: BorderSide(color: DarColors.border)),
          ),
          child: Row(children: [
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: _validation ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: (p == null || _validation) ? null : _valider,
                icon: _validation
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Icon(widget.iconeBouton),
                label: Text(widget.libelleBouton, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ChampRecherche extends StatelessWidget {
  const _ChampRecherche({required this.controller, required this.enCours, required this.onRechercher});
  final TextEditingController controller;
  final bool enCours;
  final Future<void> Function(String) onRechercher;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DarColors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onRechercher,
        decoration: InputDecoration(
          hintText: 'Rechercher une adresse, un quartier…',
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.search, color: DarColors.primary),
          suffixIcon: enCours
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  tooltip: 'Rechercher',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () => onRechercher(controller.text),
                ),
        ),
      ),
    );
  }
}

class _Resultats extends StatelessWidget {
  const _Resultats({required this.resultats, required this.onChoix});
  final List<ResultatAdresse> resultats;
  final void Function(ResultatAdresse) onChoix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: DarColors.surface,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final r in resultats)
            ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, color: DarColors.primary),
              title: Text(r.libelle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              onTap: () => onChoix(r),
            ),
        ]),
      ),
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: DarColors.text.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(10)),
          child: Text(texte, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );
}

/// « Lat. 36,8421 · Long. 10,2752 » (maquette C3).
class _Coordonnees extends StatelessWidget {
  const _Coordonnees({required this.position, required this.approximative});
  final LatLng? position;
  final bool approximative;

  static String _f(double v) => v.toStringAsFixed(4).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final p = position;
    final (texte, icone, couleur) = switch ((p, approximative)) {
      (null, _) => ('Aucune position : cherchez l’adresse ou touchez la carte', Icons.info_outline, DarColors.muted),
      (final p?, true) => (
          'Lat. ${_f(p.latitude)} · Long. ${_f(p.longitude)}\nPosition approximative (adresse saisie) : ajustez le marqueur',
          Icons.warning_amber_rounded,
          DarColors.warning
        ),
      (final p?, false) => ('Lat. ${_f(p.latitude)} · Long. ${_f(p.longitude)}', Icons.check_rounded, DarColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.my_location, size: 16, color: DarColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texte, style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w700, color: DarColors.text2)),
        ),
        Icon(icone, size: 18, color: couleur),
      ]),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: DarColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, size: 18, color: DarColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: DarColors.danger)),
          ),
        ]),
      );
}
