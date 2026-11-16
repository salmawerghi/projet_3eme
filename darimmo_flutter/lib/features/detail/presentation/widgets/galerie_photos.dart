// =====================================================================
// DarImmo - [3.3] Galerie de photos défilante (haut de la maquette B4)
// Tâche du membre B, réalisée par le membre C.
//
// Glisser à gauche / à droite pour changer de photo ; toucher une photo
// l'ouvre en plein écran (zoom à deux doigts).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien;

/// Photo réseau avec remplacement (pas de photo, chargement, erreur).
class PhotoAnnonce extends StatelessWidget {
  const PhotoAnnonce({super.key, required this.url, required this.type, this.fit = BoxFit.cover});
  final String? url;
  final TypeBien type;
  final BoxFit fit;

  static IconData iconeType(TypeBien type) => switch (type) {
        TypeBien.villa => Icons.home_outlined,
        TypeBien.terrain => Icons.landscape_outlined,
        TypeBien.local => Icons.storefront_outlined,
        TypeBien.appartement => Icons.apartment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(iconeType(type), size: 56, color: DarColors.primary),
    );
    if (url == null) return remplacement;
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, _, _) => remplacement,
      loadingBuilder: (_, enfant, progression) => progression == null ? enfant : Container(color: DarColors.surface2),
    );
  }
}

class GaleriePhotos extends StatefulWidget {
  const GaleriePhotos({super.key, required this.photos, required this.type, required this.onRetour, this.hauteur = 340});

  final List<String> photos;
  final TypeBien type;
  final VoidCallback onRetour;
  final double hauteur;

  @override
  State<GaleriePhotos> createState() => _GaleriePhotosState();
}

class _GaleriePhotosState extends State<GaleriePhotos> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _pleinEcran() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _PhotosPleinEcran(photos: widget.photos, depart: _index, type: widget.type),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final n = photos.length;
    return SizedBox(
      height: widget.hauteur,
      child: Stack(fit: StackFit.expand, children: [
        if (n == 0)
          PhotoAnnonce(url: null, type: widget.type)
        else
          PageView.builder(
            key: const Key('galerie'),
            controller: _pages,
            itemCount: n,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: _pleinEcran,
              child: PhotoAnnonce(url: photos[i], type: widget.type),
            ),
          ),
        // Dégradé haut et bas : boutons et compteur lisibles sur une photo claire.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x800B1220), Color(0x000B1220), Color(0x000B1220), Color(0x990B1220)],
                stops: [0, 0.3, 0.65, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(children: [
                _BoutonRond(icone: Icons.arrow_back, infobulle: 'Retour', onTap: widget.onRetour),
                const Spacer(),
                // [3.8] Partager et [5.1] cœur (membre B) : à placer ici.
              ]),
            ),
          ),
        ),
        if (n > 0)
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Row(children: [
              if (n > 1) _Points(nombre: n, actif: _index),
              const Spacer(),
              _Pastille(texte: '${_index + 1}/$n ${n > 1 ? 'PHOTOS' : 'PHOTO'}'),
            ]),
          ),
      ]),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({required this.icone, required this.infobulle, required this.onTap});
  final IconData icone;
  final String infobulle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: DarColors.surface,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x330B1220),
        child: IconButton(
          tooltip: infobulle,
          onPressed: onTap,
          icon: Icon(icone, color: DarColors.text, size: 22),
        ),
      );
}

/// Points de la galerie (au plus 7, sinon ils déborderaient).
class _Points extends StatelessWidget {
  const _Points({required this.nombre, required this.actif});
  final int nombre;
  final int actif;

  @override
  Widget build(BuildContext context) {
    const max = 7;
    final debut = (actif - max ~/ 2).clamp(0, nombre > max ? nombre - max : 0);
    final fin = nombre > max ? debut + max : nombre;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = debut; i < fin; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 6),
          width: i == actif ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == actif ? Colors.white : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    ]);
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0x990B1220), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.photo_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(texte,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
        ]),
      );
}

class _PhotosPleinEcran extends StatefulWidget {
  const _PhotosPleinEcran({required this.photos, required this.depart, required this.type});
  final List<String> photos;
  final int depart;
  final TypeBien type;

  @override
  State<_PhotosPleinEcran> createState() => _PhotosPleinEcranState();
}

class _PhotosPleinEcranState extends State<_PhotosPleinEcran> {
  late final _pages = PageController(initialPage: widget.depart);
  late int _index = widget.depart;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${_index + 1} / ${widget.photos.length}'),
        ),
        body: PageView.builder(
          controller: _pages,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(child: PhotoAnnonce(url: widget.photos[i], type: widget.type, fit: BoxFit.contain)),
          ),
        ),
      );
}
