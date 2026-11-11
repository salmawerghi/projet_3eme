// =====================================================================
// DarImmo - [3.1] Une annonce publiée, telle qu'affichée dans la liste
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Correspond à une ligne de public.annonces + ses photos (public.photos).
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre, libellePieces;

class AnnonceRecherche {
  const AnnonceRecherche({
    required this.id,
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.dateCreation,
    this.surface,
    this.nbPieces,
    this.ville,
    this.photos = const [],
  });

  final String id;
  final String titre;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final double? surface;

  /// Nombre TOTAL de pièces (convention du formulaire 6.1) : un S+2 a 3 pièces.
  final int? nbPieces;
  final String? ville;
  final DateTime dateCreation;

  /// URL des photos, dans l'ordre choisi par l'annonceur (la 1re = couverture).
  final List<String> photos;

  /// Colonnes lues par la liste (pas de select('*') : moins de données à charger).
  static const colonnes = 'id, titre, type_bien, type_offre, prix, surface, nb_pieces, ville, date_creation, photos(url, ordre)';

  String? get photoCouverture => photos.isEmpty ? null : photos.first;

  /// « S+2 » pour un logement, « 3 pièces » pour un local, rien pour un terrain.
  String? get libelleTaille {
    final n = nbPieces;
    if (n == null || !typeBien.aDesPieces || n == 0) return null;
    if (typeBien == TypeBien.local) return n == 1 ? '1 pièce' : '$n pièces';
    return libellePieces(n);
  }

  factory AnnonceRecherche.depuisLigne(Map<String, dynamic> l) {
    final photos = [
      for (final p in (l['photos'] as List? ?? const []))
        if ((p as Map)['url'] != null) Map<String, dynamic>.from(p),
    ]..sort((a, b) => ((a['ordre'] as num?) ?? 0).compareTo((b['ordre'] as num?) ?? 0));

    return AnnonceRecherche(
      id: l['id'] as String,
      titre: l['titre'] as String,
      typeBien: TypeBien.values.byName(l['type_bien'] as String),
      typeOffre: TypeOffre.values.byName(l['type_offre'] as String),
      prix: (l['prix'] as num).toDouble(),
      surface: (l['surface'] as num?)?.toDouble(),
      nbPieces: (l['nb_pieces'] as num?)?.toInt(),
      ville: l['ville'] as String?,
      dateCreation: DateTime.parse(l['date_creation'] as String),
      photos: [for (final p in photos) p['url'] as String],
    );
  }
}
