// =====================================================================
// DarImmo - [9.4] Annonce signalée et ses signalements (maquette A8)
// Tâche du membre A, réalisée par le membre C.
//
// La base renvoie une ligne par signalement ; on les regroupe par annonce
// (« 3 SIGNALEMENTS ») pour traiter l'annonce en une seule décision.
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart'
    show StatutAnnonce, TypeBien, TypeOffre, statutDepuisSql;
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart' show formaterPrix;

class SignalementRecu {
  const SignalementRecu({required this.id, required this.motif, required this.date, this.nomAuteur});

  final int id;

  /// « Catégorie — précision » (3.4) ou texte libre (anciens signalements).
  final String motif;
  final DateTime date;
  final String? nomAuteur;

  String get categorie => motif.split(' — ').first;

  /// Précision écrite par l'utilisateur (null s'il n'en a pas donné).
  String? get precision {
    final i = motif.indexOf(' — ');
    return i < 0 ? null : motif.substring(i + 3);
  }
}

class AnnonceSignalee {
  const AnnonceSignalee({
    required this.idAnnonce,
    required this.titre,
    required this.statut,
    required this.typeBien,
    required this.typeOffre,
    required this.prix,
    required this.signalements,
    this.ville,
    this.nomAnnonceur,
    this.photoCouverture,
  });

  final String idAnnonce;
  final String titre;
  final StatutAnnonce statut;
  final TypeBien typeBien;
  final TypeOffre typeOffre;
  final double prix;
  final String? ville;
  final String? nomAnnonceur;
  final String? photoCouverture;

  /// Du plus ancien au plus récent.
  final List<SignalementRecu> signalements;

  List<int> get ids => [for (final s in signalements) s.id];

  String get resume => [
        if ((ville ?? '').trim().isNotEmpty) ville!.trim(),
        '${formaterPrix(prix)} ${typeOffre == TypeOffre.location ? 'DT/mois' : 'DT'}',
      ].join(' · ');

  static const colonnes = 'id, motif, date, auteur:profiles!signalements_id_user_fkey(nom), '
      'annonce:annonces(id, titre, statut, type_bien, type_offre, prix, ville, photos(url, ordre), '
      'annonceur:profiles!annonces_id_annonceur_fkey(nom))';

  /// Regroupe les lignes (triées par date) par annonce ; l'annonce signalée
  /// le plus tôt vient en premier. Une ligne sans annonce (supprimée) est ignorée.
  static List<AnnonceSignalee> regrouper(List<Map<String, dynamic>> lignes) {
    final parAnnonce = <String, AnnonceSignalee>{};
    for (final l in lignes) {
      final a = l['annonce'] as Map<String, dynamic>?;
      if (a == null) continue;
      final s = SignalementRecu(
        id: (l['id'] as num).toInt(),
        motif: l['motif'] as String,
        date: DateTime.parse(l['date'] as String),
        nomAuteur: (l['auteur'] as Map?)?['nom'] as String?,
      );
      final existante = parAnnonce[a['id']];
      if (existante != null) {
        existante.signalements.add(s);
        continue;
      }
      final photos = [
        for (final p in (a['photos'] as List? ?? const []))
          if ((p as Map)['url'] != null) Map<String, dynamic>.from(p),
      ]..sort((x, y) => ((x['ordre'] as num?) ?? 0).compareTo((y['ordre'] as num?) ?? 0));
      parAnnonce[a['id'] as String] = AnnonceSignalee(
        idAnnonce: a['id'] as String,
        titre: a['titre'] as String,
        statut: statutDepuisSql(a['statut'] as String),
        typeBien: TypeBien.values.byName(a['type_bien'] as String),
        typeOffre: TypeOffre.values.byName(a['type_offre'] as String),
        prix: (a['prix'] as num).toDouble(),
        ville: a['ville'] as String?,
        nomAnnonceur: (a['annonceur'] as Map?)?['nom'] as String?,
        photoCouverture: photos.isEmpty ? null : photos.first['url'] as String,
        signalements: [s],
      );
    }
    return parAnnonce.values.toList();
  }
}
