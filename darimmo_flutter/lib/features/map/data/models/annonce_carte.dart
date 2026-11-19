// =====================================================================
// DarImmo - [4.1] [4.2] Une annonce publiée, telle qu'affichée sur la carte
// Tâche du membre B, réalisée par le membre C.
//
// Seulement ce que demandent le marqueur (prix) et l'aperçu (photo, titre,
// prix, ville) : critère 4.1 « Toucher un marqueur affiche photo et prix ».
// =====================================================================
import 'package:latlong2/latlong.dart';

import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;

class AnnonceCarte {
  const AnnonceCarte({
    required this.id,
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.position,
    this.ville,
    this.photoCouverture,
  });

  final String id;
  final String titre;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final LatLng position;
  final String? ville;

  /// 1re photo dans l'ordre choisi par l'annonceur (null : aucune photo).
  final String? photoCouverture;

  /// Colonnes lues : les mêmes pour la table (4.1) et pour la fonction annonces_autour (4.2).
  static const colonnes = 'id, titre, type_bien, type_offre, prix, ville, latitude, longitude, photos(url, ordre)';

  /// null si la ligne n'a pas de position (annonce publiée avant la 6.4) : pas de marqueur possible.
  static AnnonceCarte? depuisLigne(Map<String, dynamic> l) {
    final lat = (l['latitude'] as num?)?.toDouble();
    final lng = (l['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final photos = [
      for (final p in (l['photos'] as List? ?? const []))
        if ((p as Map)['url'] != null) Map<String, dynamic>.from(p),
    ]..sort((a, b) => ((a['ordre'] as num?) ?? 0).compareTo((b['ordre'] as num?) ?? 0));

    return AnnonceCarte(
      id: l['id'] as String,
      titre: l['titre'] as String,
      typeBien: TypeBien.values.byName(l['type_bien'] as String),
      typeOffre: TypeOffre.values.byName(l['type_offre'] as String),
      prix: (l['prix'] as num).toDouble(),
      ville: l['ville'] as String?,
      position: LatLng(lat, lng),
      photoCouverture: photos.isEmpty ? null : photos.first['url'] as String,
    );
  }
}

/// Prix court du marqueur (maquette B3) : « 1,25 M », « 385 k », « 950 DT/m ».
String libellePrixCourt(AnnonceCarte a) {
  if (a.typeOffre == TypeOffre.location) return '${formaterPrix(a.prix.roundToDouble())} DT/m';
  if (a.prix >= 1000000) {
    final millions = (a.prix / 1000000).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '${millions.replaceAll('.', ',')} M';
  }
  if (a.prix >= 1000) return '${(a.prix / 1000).round()} k';
  return formaterPrix(a.prix.roundToDouble());
}

/// Prix complet de l'aperçu : « 950 DT/mois » ou « 385 000 DT ».
String libellePrixComplet(AnnonceCarte a) =>
    '${formaterPrix(a.prix)} ${a.typeOffre == TypeOffre.location ? 'DT/mois' : 'DT'}';
