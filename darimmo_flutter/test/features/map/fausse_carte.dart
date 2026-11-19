// Faux CarteRepository (en mémoire) pour les tests de la 4.1 / 4.2.
// « autour » filtre vraiment par distance (comme la fonction PostGIS) ;
// les réponses peuvent être bloquées (réponses en retard) ou échouer.
import 'dart:async';

import 'package:latlong2/latlong.dart';

import 'package:darimmo/features/map/data/models/annonce_carte.dart';
import 'package:darimmo/features/map/data/repositories/carte_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

// Hammamet = position renvoyée par FausseLocalisation (test/features/publish/faux_position.dart).
const centreHammamet = LatLng(36.4513, 10.7357);

AnnonceCarte annonceCarte(
  String id,
  LatLng position, {
  String? titre,
  TypeOffre offre = TypeOffre.vente,
  double prix = 385000,
  String? ville = 'Hammamet',
  String? photo,
}) =>
    AnnonceCarte(
      id: id,
      titre: titre ?? 'Annonce $id',
      typeBien: TypeBien.appartement,
      typeOffre: offre,
      prix: prix,
      position: position,
      ville: ville,
      photoCouverture: photo,
    );

/// 3 biens à Hammamet (≈ 0,5 km, 1,5 km, 4 km du centre) et 1 à Tunis (≈ 60 km).
List<AnnonceCarte> annoncesTest() => [
      annonceCarte('h1', const LatLng(36.4558, 10.7357), titre: 'Studio plage', offre: TypeOffre.location, prix: 950),
      annonceCarte('h2', const LatLng(36.4648, 10.7357), titre: 'Villa jardin', prix: 1250000),
      annonceCarte('h3', const LatLng(36.4873, 10.7357), titre: 'Appartement S+2', prix: 385000),
      annonceCarte('t1', const LatLng(36.8008, 10.1815), titre: 'Duplex Tunis', prix: 540000, ville: 'Tunis'),
    ];

class FausseCarte implements CarteRepository {
  FausseCarte([List<AnnonceCarte>? annonces]) : annonces = annonces ?? annoncesTest();

  final List<AnnonceCarte> annonces;

  /// Appels à autour() : (centre, rayon en mètres).
  final appelsAutour = <(LatLng, int)>[];
  int appelsToutes = 0;

  /// Le prochain appel échoue (une seule fois).
  bool echec = false;

  /// Si vrai, chaque réponse attend qu'on appelle liberer().
  bool bloquer = false;
  final _enAttente = <Completer<void>>[];
  int get nbEnAttente => _enAttente.length;

  /// Débloque la plus ancienne requête en attente.
  void liberer() => _enAttente.removeAt(0).complete();

  Future<void> _attendre() async {
    if (bloquer) {
      final c = Completer<void>();
      _enAttente.add(c);
      await c.future;
    }
    if (echec) {
      echec = false;
      throw const CarteException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<List<AnnonceCarte>> toutes() async {
    appelsToutes++;
    await _attendre();
    return [...annonces];
  }

  @override
  Future<List<AnnonceCarte>> autour(LatLng centre, int rayonM) async {
    appelsAutour.add((centre, rayonM));
    await _attendre();
    const distance = Distance();
    return annonces.where((a) => distance(centre, a.position) <= rayonM).toList()
      ..sort((a, b) => distance(centre, a.position).compareTo(distance(centre, b.position)));
  }
}
