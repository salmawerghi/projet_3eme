// Faux PhotosRepository (en mémoire) partagé par les tests de la 6.1 et de la 6.2.
// Simule les règles de la base : 10 photos max (ordre 0..9) et ordre unique par annonce.
import 'dart:async';
import 'dart:convert';

import 'package:darimmo/features/publish/data/repositories/photos_repository.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';

/// PNG 1×1 valide (l'aperçu Image.memory doit pouvoir le décoder).
final pngMinuscule = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

PhotoChoisie photo(String nom) => PhotoChoisie(octets: pngMinuscule, nom: nom);

/// Faux sélecteur de galerie : renvoie [photos] (dans la limite demandée) et note le maximum demandé.
class FausseGalerie {
  FausseGalerie([this.photos = const []]);
  List<PhotoChoisie> photos;
  final maximumsDemandes = <int>[];

  Future<List<PhotoChoisie>> choisir(int maximum) async {
    maximumsDemandes.add(maximum);
    return photos;
  }
}

class FauxPhotosRepository implements PhotosRepository {
  FauxPhotosRepository([List<PhotoEnregistree> initiales = const []]) : enBase = [...initiales];

  final List<PhotoEnregistree> enBase;
  final envoyees = <String>[]; // noms des fichiers envoyés
  final supprimees = <String>[]; // id des photos supprimées
  int appelsOrdonner = 0;

  /// Nombre de prochains envois qui échouent (connexion perdue).
  int echecsAVenir = 0;
  bool echecSuppression = false;
  int _compteur = 0;

  List<int> get ordres => [for (final p in enBase) p.ordre];

  @override
  Future<List<PhotoEnregistree>> lister(String idAnnonce) async =>
      [...enBase.where((p) => p.idAnnonce == idAnnonce)]..sort((a, b) => a.ordre.compareTo(b.ordre));

  @override
  Future<PhotoEnregistree> envoyer(String idAnnonce, PhotoChoisie photo, int ordre) async {
    await Future<void>.delayed(Duration.zero);
    if (echecsAVenir > 0) {
      echecsAVenir--;
      throw const PhotosException('L’envoi de la photo a échoué. Vérifiez votre connexion puis réessayez.');
    }
    if (ordre < 0 || ordre >= photosMax) throw const PhotosException('ordre hors limites (CHECK)');
    if (enBase.any((p) => p.idAnnonce == idAnnonce && p.ordre == ordre)) {
      throw PhotosException('doublon d’ordre $ordre (contrainte unique)');
    }
    final n = _compteur++;
    final p = PhotoEnregistree(
        id: 'photo-$n', idAnnonce: idAnnonce, chemin: '$idAnnonce/$n.jpg', url: 'https://x/$n.jpg', ordre: ordre);
    enBase.add(p);
    envoyees.add(photo.nom);
    return p;
  }

  @override
  Future<void> supprimer(PhotoEnregistree photo) async {
    await Future<void>.delayed(Duration.zero);
    if (echecSuppression) throw const PhotosException('Connexion impossible. Vérifiez Internet et réessayez.');
    enBase.removeWhere((p) => p.id == photo.id);
    supprimees.add(photo.id);
  }

  @override
  Future<void> ordonner(List<PhotoEnregistree> photos) async {
    appelsOrdonner++;
    for (final (i, p) in photos.indexed) {
      final k = enBase.indexWhere((x) => x.id == p.id);
      enBase[k] = enBase[k].avecOrdre(i);
    }
  }
}

PhotoEnregistree enregistree(String id, int ordre, {String annonce = 'a1'}) =>
    PhotoEnregistree(id: id, idAnnonce: annonce, chemin: '$annonce/$id.jpg', url: 'https://x/$id.jpg', ordre: ordre);
