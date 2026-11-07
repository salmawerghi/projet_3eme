// =====================================================================
// DarImmo - [6.1] Publier une annonce : modèle de données
// Membre C
//
// Correspond à la table public.annonces (supabase/01_schema.sql).
// Les valeurs des enums Dart sont les mêmes que celles des enums SQL
// (type_bien, type_offre, statut_annonce).
// =====================================================================

/// Enum SQL type_bien.
enum TypeBien {
  appartement('Appartement'),
  villa('Villa'),
  terrain('Terrain'),
  local('Local');

  const TypeBien(this.libelle);
  final String libelle;

  /// Un terrain n'a pas de pièces (nb_pieces = 0).
  bool get aDesPieces => this != TypeBien.terrain;
}

/// Enum SQL type_offre.
enum TypeOffre {
  vente('Vendre'),
  location('Louer');

  const TypeOffre(this.libelle);
  final String libelle;
}

/// Enum SQL statut_annonce.
enum StatutAnnonce { brouillon, enAttente, publiee, rejetee, vendue, louee, masquee }

StatutAnnonce statutDepuisSql(String valeur) => switch (valeur) {
      'brouillon' => StatutAnnonce.brouillon,
      'en_attente' => StatutAnnonce.enAttente,
      'publiee' => StatutAnnonce.publiee,
      'rejetee' => StatutAnnonce.rejetee,
      'vendue' => StatutAnnonce.vendue,
      'louee' => StatutAnnonce.louee,
      'masquee' => StatutAnnonce.masquee,
      _ => throw ArgumentError('Statut inconnu : $valeur'),
    };

/// Libellé « S+n » utilisé en Tunisie : S+3 = 3 chambres + 1 salon = 4 pièces.
String libellePieces(int nbPieces) => nbPieces <= 1 ? 'S+0 (studio)' : 'S+${nbPieces - 1}';

/// Données saisies dans le formulaire, avant l'envoi.
/// id, statut, id_annonceur et dates sont fixés par la base.
class NouvelleAnnonce {
  const NouvelleAnnonce({
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.surface,
    required this.nbPieces,
    required this.ville,
    this.adresse,
    this.description,
  });

  final String titre;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final double surface;
  final int nbPieces;
  final String ville;
  final String? adresse;
  final String? description;

  /// Ligne à insérer dans public.annonces.
  /// statut = en_attente : l'annonce attend la validation d'un administrateur
  /// (le trigger annonces_statut l'impose de toute façon).
  Map<String, dynamic> versLigne(String idAnnonceur) => {
        'titre': titre.trim(),
        'type_bien': typeBien.name,
        'type_offre': typeOffre.name,
        'prix': prix,
        'surface': surface,
        'nb_pieces': typeBien.aDesPieces ? nbPieces : 0,
        'ville': ville.trim(),
        'adresse': _vide(adresse),
        'description': _vide(description),
        'statut': 'en_attente',
        'id_annonceur': idAnnonceur,
      };

  static String? _vide(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

/// Annonce telle que renvoyée par la base après l'insertion.
class Annonce {
  const Annonce({
    required this.id,
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.ville,
    required this.statut,
    required this.dateCreation,
  });

  final String id;
  final String titre;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final String ville;
  final StatutAnnonce statut;
  final DateTime dateCreation;

  factory Annonce.depuisLigne(Map<String, dynamic> l) => Annonce(
        id: l['id'] as String,
        titre: l['titre'] as String,
        typeBien: TypeBien.values.byName(l['type_bien'] as String),
        typeOffre: TypeOffre.values.byName(l['type_offre'] as String),
        prix: (l['prix'] as num).toDouble(),
        ville: l['ville'] as String,
        statut: statutDepuisSql(l['statut'] as String),
        dateCreation: DateTime.parse(l['date_creation'] as String).toLocal(),
      );
}
