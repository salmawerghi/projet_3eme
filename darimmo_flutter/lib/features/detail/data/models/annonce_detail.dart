// =====================================================================
// DarImmo - [3.3] Une annonce complète, pour l'écran de détail (maquette B4)
// Tâche du membre B, réalisée par le membre C.
//
// Correspond à une ligne de public.annonces + ses photos (public.photos)
// + le profil public de l'annonceur (public.profiles, lisible par tous).
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart'
    show StatutAnnonce, TypeBien, TypeOffre, libellePieces, statutDepuisSql;

/// Ce que l'écran montre de l'annonceur (pas son email ni son téléphone).
class Annonceur {
  const Annonceur({required this.nom, this.photoUrl, this.dateInscription});

  final String nom;
  final String? photoUrl;
  final DateTime? dateInscription;

  /// « SV » pour « Sami Vendeur » (avatar sans photo).
  String get initiales {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    final lettres = mots.length == 1 ? mots.first.substring(0, 1) : mots.first.substring(0, 1) + mots[1].substring(0, 1);
    return lettres.toUpperCase();
  }

  factory Annonceur.depuisLigne(Map<String, dynamic>? l) {
    final nom = (l?['nom'] as String?)?.trim();
    final date = l?['date_inscription'] as String?;
    return Annonceur(
      nom: (nom == null || nom.isEmpty) ? 'Annonceur DarImmo' : nom,
      photoUrl: l?['photo_url'] as String?,
      dateInscription: date == null ? null : DateTime.parse(date),
    );
  }
}

class AnnonceDetail {
  const AnnonceDetail({
    required this.id,
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.statut,
    required this.idAnnonceur,
    required this.annonceur,
    required this.dateCreation,
    this.description,
    this.surface,
    this.nbPieces,
    this.adresse,
    this.ville,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.nbAnnoncesAnnonceur,
  });

  final String id;
  final String titre;
  final String? description;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final double? surface;

  /// Nombre TOTAL de pièces (convention du formulaire 6.1) : un S+2 a 3 pièces.
  final int? nbPieces;
  final String? adresse;
  final String? ville;
  final double? latitude;
  final double? longitude;
  final StatutAnnonce statut;
  final String idAnnonceur;
  final Annonceur annonceur;
  final DateTime dateCreation;

  /// URL des photos, dans l'ordre choisi par l'annonceur.
  final List<String> photos;

  /// Annonces publiées par le même annonceur (null = pas pu être compté).
  final int? nbAnnoncesAnnonceur;

  /// Colonnes lues (testées sur la vraie base avec la clé publique).
  /// « annonceur: » renomme le profil joint par la clé étrangère id_annonceur.
  static const colonnes = 'id, titre, description, type_bien, type_offre, prix, surface, nb_pieces, '
      'adresse, ville, latitude, longitude, statut, id_annonceur, date_creation, photos(url, ordre), '
      'annonceur:profiles!annonces_id_annonceur_fkey(nom, photo_url, date_inscription)';

  bool get estPubliee => statut == StatutAnnonce.publiee;
  bool get aUnePosition => latitude != null && longitude != null;

  /// « Rue de Marseille, Tunis » (les morceaux vides sont ignorés).
  String? get lieu {
    final morceaux = [adresse, ville].map((m) => m?.trim() ?? '').where((m) => m.isNotEmpty).toList();
    return morceaux.isEmpty ? null : morceaux.join(', ');
  }

  /// « S+2 » pour un logement, « 3 pièces » pour un local, rien pour un terrain.
  String? get libelleTaille {
    final n = nbPieces;
    if (n == null || !typeBien.aDesPieces || n == 0) return null;
    if (typeBien == TypeBien.local) return n == 1 ? '1 pièce' : '$n pièces';
    return libellePieces(n);
  }

  /// Prix au m² : seulement pour une vente avec une surface connue.
  double? get prixAuM2 {
    final s = surface;
    if (typeOffre != TypeOffre.vente || s == null || s <= 0) return null;
    return prix / s;
  }

  AnnonceDetail avecNbAnnonces(int? n) => AnnonceDetail(
        id: id,
        titre: titre,
        description: description,
        typeBien: typeBien,
        typeOffre: typeOffre,
        prix: prix,
        surface: surface,
        nbPieces: nbPieces,
        adresse: adresse,
        ville: ville,
        latitude: latitude,
        longitude: longitude,
        statut: statut,
        idAnnonceur: idAnnonceur,
        annonceur: annonceur,
        dateCreation: dateCreation,
        photos: photos,
        nbAnnoncesAnnonceur: n,
      );

  factory AnnonceDetail.depuisLigne(Map<String, dynamic> l) {
    final photos = [
      for (final p in (l['photos'] as List? ?? const []))
        if ((p as Map)['url'] != null) Map<String, dynamic>.from(p),
    ]..sort((a, b) => ((a['ordre'] as num?) ?? 0).compareTo((b['ordre'] as num?) ?? 0));
    final annonceur = l['annonceur'];

    return AnnonceDetail(
      id: l['id'] as String,
      titre: l['titre'] as String,
      description: l['description'] as String?,
      typeBien: TypeBien.values.byName(l['type_bien'] as String),
      typeOffre: TypeOffre.values.byName(l['type_offre'] as String),
      prix: (l['prix'] as num).toDouble(),
      surface: (l['surface'] as num?)?.toDouble(),
      nbPieces: (l['nb_pieces'] as num?)?.toInt(),
      adresse: l['adresse'] as String?,
      ville: l['ville'] as String?,
      latitude: (l['latitude'] as num?)?.toDouble(),
      longitude: (l['longitude'] as num?)?.toDouble(),
      statut: statutDepuisSql(l['statut'] as String),
      idAnnonceur: l['id_annonceur'] as String,
      annonceur: Annonceur.depuisLigne(annonceur is Map ? Map<String, dynamic>.from(annonceur) : null),
      dateCreation: DateTime.parse(l['date_creation'] as String),
      photos: [for (final p in photos) p['url'] as String],
    );
  }
}
