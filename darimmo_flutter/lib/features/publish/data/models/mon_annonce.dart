// =====================================================================
// DarImmo - [6.3] [6.5] Mes annonces : modèle d'une annonce de l'annonceur
// Membre C
//
// Une ligne de public.annonces appartenant à l'utilisateur connecté,
// avec la première photo (table photos, ordre 0) pour la vignette.
// Les enums (TypeBien, TypeOffre, StatutAnnonce) sont ceux de la 6.1.
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart';

/// Libellé affiché pour chaque statut (maquette v3, STATUTS dans spec.js).
extension LibelleStatut on StatutAnnonce {
  String get libelle => switch (this) {
        StatutAnnonce.brouillon => 'Brouillon',
        StatutAnnonce.enAttente => 'En attente',
        StatutAnnonce.publiee => 'Publiée',
        StatutAnnonce.rejetee => 'Rejetée',
        StatutAnnonce.vendue => 'Vendue',
        StatutAnnonce.louee => 'Louée',
        StatutAnnonce.masquee => 'Masquée',
      };
}

class MonAnnonce {
  const MonAnnonce({
    required this.id,
    required this.titre,
    required this.statut,
    required this.dateCreation,
    required this.dateMaj,
    this.typeBien,
    this.typeOffre,
    this.prix,
    this.surface,
    this.nbPieces,
    this.ville,
    this.adresse,
    this.description,
    this.motif,
    this.photoUrl,
    this.cheminsPhotos = const [],
    this.latitude,
    this.longitude,
  });

  /// [6.4] Position du bien (null si pas encore placé sur la carte).
  final double? latitude;
  final double? longitude;

  final String id;
  final String titre;
  final StatutAnnonce statut;
  final DateTime dateCreation;
  final DateTime dateMaj;

  // Peuvent être vides pour un brouillon (contrainte annonce_complete).
  final TypeBien? typeBien;
  final TypeOffre? typeOffre;
  final double? prix;
  final double? surface;
  final int? nbPieces;
  final String? ville;
  final String? adresse;
  final String? description;

  /// motif_rejet : renseigné par l'admin pour un rejet ou un masquage (6.5).
  final String? motif;

  /// URL de la première photo, null tant que la 6.2 (photos) n'est pas faite.
  final String? photoUrl;

  /// Chemins des photos dans le bucket annonces-photos (« `<id>/<nom>.jpg` »),
  /// à effacer du stockage quand l'annonce est supprimée (6.3).
  final List<String> cheminsPhotos;
  int get nbPhotos => cheminsPhotos.length;

  // ----- Actions possibles depuis « Mes annonces » (6.3), d'après les
  // transitions autorisées par le trigger annonces_statut (02_fonctions.sql).

  /// Modifier : pas pour une annonce vendue / louée / masquée par l'admin.
  bool get peutModifier => versEdition() != null;

  /// Marquer vendue / louée : seulement depuis « publiée ».
  bool get peutMarquerVendue => statut == StatutAnnonce.publiee && typeOffre != null;

  /// Statut final selon l'offre : vente -> vendue, location -> louée.
  StatutAnnonce get statutConclu => typeOffre == TypeOffre.location ? StatutAnnonce.louee : StatutAnnonce.vendue;

  /// Valeurs pour pré-remplir le formulaire de la 6.1, ou null si l'annonce
  /// ne peut pas être modifiée (statut final, ou brouillon incomplet).
  EditionAnnonce? versEdition() {
    const modifiables = {StatutAnnonce.brouillon, StatutAnnonce.enAttente, StatutAnnonce.publiee, StatutAnnonce.rejetee};
    if (!modifiables.contains(statut)) return null;
    if (typeBien == null || typeOffre == null || prix == null || surface == null || ville == null) return null;
    return EditionAnnonce(
      id: id,
      statut: statut,
      valeurs: NouvelleAnnonce(
        titre: titre,
        typeBien: typeBien!,
        typeOffre: typeOffre!,
        prix: prix!,
        surface: surface!,
        nbPieces: nbPieces ?? 0,
        ville: ville!,
        adresse: adresse,
        description: description,
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Colonnes lues dans Supabase (+ photos liées, triées par ordre).
  static const colonnes = 'id, titre, type_bien, type_offre, prix, surface, nb_pieces, '
      'adresse, ville, description, latitude, longitude, statut, motif_rejet, date_creation, date_maj, '
      'photos(url, ordre, chemin_storage)';

  factory MonAnnonce.depuisLigne(Map<String, dynamic> l) {
    final photos = List<Map<String, dynamic>>.from(l['photos'] as List? ?? const [])
      ..sort((a, b) => (a['ordre'] as int).compareTo(b['ordre'] as int));
    return MonAnnonce(
      id: l['id'] as String,
      titre: l['titre'] as String,
      statut: statutDepuisSql(l['statut'] as String),
      dateCreation: DateTime.parse(l['date_creation'] as String).toLocal(),
      dateMaj: DateTime.parse(l['date_maj'] as String).toLocal(),
      typeBien: l['type_bien'] == null ? null : TypeBien.values.byName(l['type_bien'] as String),
      typeOffre: l['type_offre'] == null ? null : TypeOffre.values.byName(l['type_offre'] as String),
      prix: (l['prix'] as num?)?.toDouble(),
      surface: (l['surface'] as num?)?.toDouble(),
      nbPieces: l['nb_pieces'] as int?,
      ville: l['ville'] as String?,
      adresse: l['adresse'] as String?,
      description: l['description'] as String?,
      motif: l['motif_rejet'] as String?,
      photoUrl: photos.isEmpty ? null : photos.first['url'] as String,
      cheminsPhotos: [for (final p in photos) if (p['chemin_storage'] != null) p['chemin_storage'] as String],
      latitude: (l['latitude'] as num?)?.toDouble(),
      longitude: (l['longitude'] as num?)?.toDouble(),
    );
  }
}
