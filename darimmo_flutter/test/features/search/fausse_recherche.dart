// Faux RechercheRepository (en mémoire) pour les tests de la 3.1 / 3.2.
// Applique les filtres comme la vraie requête Supabase ; peut bloquer les
// réponses (pour tester le chargement et les réponses en retard) ou échouer.
import 'dart:async';

import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/data/models/filtre_recherche.dart';
import 'package:darimmo/features/search/data/repositories/recherche_repository.dart';

final dateRef = DateTime(2026, 11, 11, 12);

/// Annonce de test : la n° [i] est créée [i] heures avant [dateRef].
AnnonceRecherche annonceTest(
  int i, {
  String? titre,
  TypeBien type = TypeBien.appartement,
  TypeOffre offre = TypeOffre.vente,
  double prix = 200000,
  double? surface = 100,
  int? pieces = 3,
  String? ville = 'Tunis',
  List<String> photos = const [],
}) =>
    AnnonceRecherche(
      id: 'a$i',
      titre: titre ?? 'Annonce $i',
      typeBien: type,
      typeOffre: offre,
      prix: prix,
      surface: surface,
      nbPieces: pieces,
      ville: ville,
      dateCreation: dateRef.subtract(Duration(hours: i)),
      photos: photos,
    );

bool correspond(AnnonceRecherche a, FiltreRecherche f) {
  bool contient(String? champ, String mot) => (champ ?? '').toLowerCase().contains(mot.toLowerCase());
  return (f.typeOffre == null || a.typeOffre == f.typeOffre) &&
      (f.typeBien == null || a.typeBien == f.typeBien) &&
      (f.prixMin == null || a.prix >= f.prixMin!) &&
      (f.prixMax == null || a.prix <= f.prixMax!) &&
      (f.nbPiecesMin == null || (a.nbPieces ?? 0) >= f.nbPiecesMin!) &&
      (f.ville == null || contient(a.ville, f.ville!)) &&
      (f.texte == null || contient(a.titre, f.texte!) || contient(a.ville, f.texte!));
}

class FausseRecherche implements RechercheRepository {
  FausseRecherche([List<AnnonceRecherche> annonces = const []]) : annonces = [...annonces];

  final List<AnnonceRecherche> annonces;

  /// Toutes les pages demandées : (filtre, numéro de page).
  final demandes = <(FiltreRecherche, int)>[];
  final comptages = <FiltreRecherche>[];

  /// Si vrai, chaque réponse attend qu'on appelle liberer().
  bool bloquer = false;
  final _enAttente = <Completer<void>>[];

  /// Pages qui échouent (une seule fois chacune).
  final echecs = <int>{};

  int get nbEnAttente => _enAttente.length;

  /// Débloque la plus ancienne requête en attente.
  void liberer() => _enAttente.removeAt(0).complete();

  @override
  Future<List<AnnonceRecherche>> page(FiltreRecherche filtre, int page) async {
    demandes.add((filtre, page));
    if (bloquer) {
      final c = Completer<void>();
      _enAttente.add(c);
      await c.future;
    }
    if (echecs.remove(page)) throw const RechercheException('Connexion impossible. Vérifiez Internet et réessayez.');
    final tri = annonces.where((a) => correspond(a, filtre)).toList()
      ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return tri.skip(page * RechercheRepository.taillePage).take(RechercheRepository.taillePage).toList();
  }

  @override
  Future<int> compter(FiltreRecherche filtre) async {
    comptages.add(filtre);
    return annonces.where((a) => correspond(a, filtre)).length;
  }

  @override
  Future<List<String>> villes() async => {for (final a in annonces) a.ville}.whereType<String>().toList()..sort();
}
