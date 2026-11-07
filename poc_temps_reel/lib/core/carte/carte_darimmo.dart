// =====================================================================
// DarImmo - Composant de carte réutilisable (OpenStreetMap + flutter_map)
// Écrit par le membre C pour la 6.4, en attendant la tâche 1.8 (membre B) :
// B peut le reprendre pour 4.1 / 4.2 (carte des annonces).
//
// Fournisseur : OpenStreetMap, gratuit, sans clé API (choix d'équipe 1.8).
// Règles d'usage des tuiles OSM respectées : identifiant de l'application
// (userAgentPackageName) et mention « © OpenStreetMap contributors ».
// =====================================================================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../darimmo_theme.dart';

/// Centre par défaut : Tunis.
const positionParDefaut = LatLng(36.8065, 10.1815);

/// Gestes autorisés par défaut : tout sauf la rotation (déroutante sur une carte immobilière).
const gestesParDefaut = InteractiveFlag.all & ~InteractiveFlag.rotate;

class CarteDarImmo extends StatelessWidget {
  const CarteDarImmo({
    super.key,
    this.controller,
    this.centre = positionParDefaut,
    this.zoom = 13,
    this.marqueurs = const [],
    this.onTap,
    this.onPrete,
    this.gestes = gestesParDefaut,
    this.afficherTuiles = true,
  });

  final MapController? controller;
  final LatLng centre;
  final double zoom;
  final List<Marker> marqueurs;

  /// Toucher sur la carte (ex : placer le marqueur à cet endroit).
  final void Function(LatLng point)? onTap;

  /// La carte est affichée : on peut appeler controller.move(...).
  final VoidCallback? onPrete;

  /// Combinaison d'[InteractiveFlag] (ex : InteractiveFlag.none pendant un glisser de marqueur).
  final int gestes;

  /// false dans les tests : pas de téléchargement de tuiles.
  final bool afficherTuiles;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: zoom,
        minZoom: 5,
        maxZoom: 19,
        backgroundColor: DarColors.surface2,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
        onMapReady: onPrete,
        interactionOptions: InteractionOptions(flags: gestes),
      ),
      children: [
        if (afficherTuiles)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.darimmo.poc_temps_reel',
            maxNativeZoom: 19,
          ),
        MarkerLayer(markers: marqueurs),
        // Bouton « i » repliable : prend peu de place sur une petite carte.
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// Grand marqueur DarImmo (maquette C3) : la pointe est sur la position.
/// À utiliser avec `Marker(alignment: Alignment.topCenter, width: 52, height: 52)`.
class PinDarImmo extends StatelessWidget {
  const PinDarImmo({super.key, this.taille = 52, this.souleve = false});
  final double taille;

  /// Pendant un glisser : marqueur un peu plus grand.
  final bool souleve;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: souleve ? 1.2 : 1,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 120),
      child: Icon(
        Icons.location_on,
        size: taille,
        color: DarColors.primary,
        shadows: const [Shadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
    );
  }
}
