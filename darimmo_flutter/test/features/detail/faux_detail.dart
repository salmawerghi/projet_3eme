// Faux DetailRepository (en mémoire) pour les tests de la 3.3 : aucun accès réseau.
import 'package:darimmo/features/detail/data/models/annonce_detail.dart';
import 'package:darimmo/features/detail/data/repositories/detail_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

AnnonceDetail annonceDetailTest(
  String id, {
  String titre = 'Appartement S+2 lumineux',
  String? description = 'Proche du centre, 2e étage avec ascenseur.',
  TypeBien type = TypeBien.appartement,
  TypeOffre offre = TypeOffre.location,
  double prix = 950,
  double? surface = 95,
  int? pieces = 3,
  String? adresse = 'Rue de Marseille',
  String? ville = 'Tunis',
  double? latitude = 36.8008,
  double? longitude = 10.1815,
  StatutAnnonce statut = StatutAnnonce.publiee,
  String idAnnonceur = 'vendeur-1',
  String nomAnnonceur = 'Sami Vendeur',
  List<String> photos = const ['https://exemple.test/1.jpg', 'https://exemple.test/2.jpg', 'https://exemple.test/3.jpg'],
  int? nbAnnonces = 8,
}) =>
    AnnonceDetail(
      id: id,
      titre: titre,
      description: description,
      typeBien: type,
      typeOffre: offre,
      prix: prix,
      surface: surface,
      nbPieces: pieces,
      adresse: adresse,
      ville: ville,
      latitude: latitude,
      longitude: longitude,
      statut: statut,
      idAnnonceur: idAnnonceur,
      annonceur: Annonceur(nom: nomAnnonceur, dateInscription: DateTime(2026, 3, 10)),
      dateCreation: DateTime(2026, 11, 4),
      photos: photos,
      nbAnnoncesAnnonceur: nbAnnonces,
    );

class FauxDetail implements DetailRepository {
  FauxDetail({Map<String, AnnonceDetail>? annonces}) : annonces = annonces ?? {};

  /// Annonces connues ; un id absent renvoie une annonce par défaut (sauf si [inconnuesIntrouvables]).
  final Map<String, AnnonceDetail> annonces;
  bool inconnuesIntrouvables = false;

  /// Erreurs à lever aux prochains appels (une par appel, puis succès).
  final List<DetailException> erreurs = [];
  int appels = 0;

  @override
  Future<AnnonceDetail> charger(String idAnnonce) async {
    appels++;
    if (erreurs.isNotEmpty) throw erreurs.removeAt(0);
    final a = annonces[idAnnonce];
    if (a != null) return a;
    if (inconnuesIntrouvables) {
      throw const DetailException(DetailException.messageIntrouvable, introuvable: true);
    }
    return annonceDetailTest(idAnnonce);
  }
}
