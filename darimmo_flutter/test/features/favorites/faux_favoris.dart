// Faux FavorisRepository (en mémoire) pour les tests de la 5.1 / 5.2.
// Comme la vraie base : un favori dont l'annonce n'est plus visible (vendue,
// masquée) reste dans ids() mais n'apparaît pas dans liste().
import 'dart:async';

import 'package:darimmo/features/favorites/data/repositories/favoris_repository.dart';
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';

import '../search/fausse_recherche.dart' show annonceTest;

class FauxFavoris implements FavorisRepository {
  FauxFavoris({List<AnnonceRecherche>? catalogue, List<String> favoris = const []})
      : catalogue = {for (final a in catalogue ?? [annonceTest(1, titre: 'Appartement S+2 lumineux')]) a.id: a},
        _favoris = [...favoris];

  /// Annonces visibles (publiées).
  final Map<String, AnnonceRecherche> catalogue;

  /// Mes favoris, du plus ancien au plus récent.
  final List<String> _favoris;
  List<String> get favoris => List.unmodifiable(_favoris);

  int lectures = 0;
  int lecturesIds = 0;

  /// Le prochain appel (quel qu'il soit) échoue.
  bool echec = false;

  /// Si non nul, ajouter / retirer attendent ce Completer.
  Completer<void>? attente;

  void _verifier() {
    if (echec) {
      echec = false;
      throw const FavorisException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<Set<String>> ids() async {
    lecturesIds++;
    _verifier();
    return {..._favoris};
  }

  @override
  Future<void> ajouter(String idAnnonce) async {
    await attente?.future;
    _verifier();
    if (!_favoris.contains(idAnnonce)) _favoris.add(idAnnonce);
  }

  @override
  Future<void> retirer(String idAnnonce) async {
    await attente?.future;
    _verifier();
    _favoris.remove(idAnnonce);
  }

  @override
  Future<List<AnnonceRecherche>> liste() async {
    lectures++;
    _verifier();
    return [for (final id in _favoris.reversed) ?catalogue[id]];
  }
}
