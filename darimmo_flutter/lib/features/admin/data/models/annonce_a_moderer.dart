// =====================================================================
// DarImmo - [9.2] Une annonce en attente de validation (maquette A7)
// Tâche du membre A, réalisée par le membre C.
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;

class AnnonceAModerer {
  const AnnonceAModerer({
    required this.id,
    required this.titre,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.envoyeeLe,
    this.ville,
    this.nomAnnonceur,
    this.photoCouverture,
    this.nbPhotos = 0,
  });

  final String id;
  final String titre;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final String? ville;
  final String? nomAnnonceur;
  final String? photoCouverture;
  final int nbPhotos;

  /// Dernière modification = envoi (ou renvoi) pour validation.
  final DateTime envoyeeLe;

  static const colonnes = 'id, titre, type_bien, type_offre, prix, ville, date_maj, '
      'annonceur:profiles!annonces_id_annonceur_fkey(nom), photos(url, ordre)';

  /// « SV » pour « Sami Vendeur » (avatar).
  String get initiales {
    final mots = (nomAnnonceur ?? '').trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).take(2);
    final lettres = mots.map((m) => m[0].toUpperCase()).join();
    return lettres.isEmpty ? '?' : lettres;
  }

  /// « La Marsa · 345 000 DT » ou « Tunis · 950 DT/mois ».
  String get resume => [
        if ((ville ?? '').trim().isNotEmpty) ville!.trim(),
        '${formaterPrix(prix)} ${typeOffre == TypeOffre.location ? 'DT/mois' : 'DT'}',
      ].join(' · ');

  factory AnnonceAModerer.depuisLigne(Map<String, dynamic> l) {
    final photos = [
      for (final p in (l['photos'] as List? ?? const []))
        if ((p as Map)['url'] != null) Map<String, dynamic>.from(p),
    ]..sort((a, b) => ((a['ordre'] as num?) ?? 0).compareTo((b['ordre'] as num?) ?? 0));
    final annonceur = l['annonceur'] as Map?;
    return AnnonceAModerer(
      id: l['id'] as String,
      titre: l['titre'] as String,
      typeBien: TypeBien.values.byName(l['type_bien'] as String),
      typeOffre: TypeOffre.values.byName(l['type_offre'] as String),
      prix: (l['prix'] as num).toDouble(),
      ville: l['ville'] as String?,
      nomAnnonceur: annonceur?['nom'] as String?,
      envoyeeLe: DateTime.parse(l['date_maj'] as String),
      photoCouverture: photos.isEmpty ? null : photos.first['url'] as String,
      nbPhotos: photos.length,
    );
  }
}
