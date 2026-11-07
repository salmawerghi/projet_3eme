// =====================================================================
// DarImmo - [6.2] ViewModel de l'écran « Photos » (Provider)
// Membre C
//
// La liste des tuiles (dans l'ordre de l'écran) est la référence. Chaque
// photo est envoyée dès qu'elle est choisie ; les opérations serveur
// (envoi, suppression, renumérotation) passent dans une FILE et s'exécutent
// une par une : deux envois ne peuvent pas prendre le même numéro d'ordre.
// Après chaque changement, l'ordre en base est réaligné sur l'écran.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'choisir_photos.dart';
import 'data/photos_repository.dart';
import 'models/photo_annonce.dart';

class PhotosViewModel extends ChangeNotifier {
  PhotosViewModel(this._repository, this.idAnnonce, this._choisir);
  final PhotosRepository _repository;
  final String idAnnonce;
  final ChoisirPhotos _choisir;

  final List<TuilePhoto> tuiles = [];
  bool chargement = false;

  /// Erreur hors envoi (chargement, suppression, changement d'ordre).
  String? erreur;

  /// File des opérations serveur.
  Future<void> _file = Future.value();

  // ----- État pour l'écran
  int get nombre => tuiles.length;
  bool get peutAjouter => nombre < photosMax;
  bool get envoisEnCours => tuiles.any((t) => t.etat == EtatPhoto.envoi);
  bool get aDesEchecs => tuiles.any((t) => t.etat == EtatPhoto.echec);

  /// On peut passer à la suite quand tout est envoyé (ou retiré).
  bool get pret => !envoisEnCours && !aDesEchecs;

  /// Attend la fin des opérations en cours (avant de quitter l'écran).
  Future<void> get termine => _file;

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();
    try {
      final photos = await _repository.lister(idAnnonce);
      tuiles
        ..clear()
        ..addAll(photos.map(TuilePhoto.enregistree));
    } on PhotosException catch (e) {
      erreur = e.message;
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  /// Ouvre la galerie ; les photos choisies apparaissent tout de suite (aperçu)
  /// puis partent une par une.
  Future<void> ajouter() async {
    if (!peutAjouter) return;
    final choisies = await _choisir(photosMax - nombre);
    for (final p in choisies.take(photosMax - nombre)) {
      final t = TuilePhoto.locale(p);
      tuiles.add(t);
      _envoyer(t);
    }
    notifyListeners();
  }

  /// Nouvelle tentative après un échec.
  void reessayer(TuilePhoto t) {
    if (t.etat != EtatPhoto.echec) return;
    t
      ..etat = EtatPhoto.envoi
      ..erreur = null;
    notifyListeners();
    _envoyer(t);
  }

  /// Retire une photo de l'écran (et du serveur si elle était envoyée).
  void retirer(TuilePhoto t) {
    final position = tuiles.indexOf(t);
    if (position < 0) return;
    tuiles.removeAt(position);
    t.retiree = true; // un envoi en cours la supprimera à la fin
    erreur = null;
    notifyListeners();
    final enregistree = t.enregistree;
    if (enregistree != null && t.etat == EtatPhoto.envoyee) {
      _enFile(() async {
        try {
          await _repository.supprimer(enregistree);
        } on PhotosException {
          // Échec : la photo est toujours en ligne, on la remet à sa place.
          t.retiree = false;
          tuiles.insert(position.clamp(0, tuiles.length), t);
          rethrow;
        }
        t.enregistree = null;
        await _realignerOrdre();
      });
    }
  }

  /// Glisser-déposer : met la photo [de] à la place [vers].
  void deplacer(int de, int vers) {
    if (de == vers || de < 0 || vers < 0 || de >= nombre || vers >= nombre) return;
    tuiles.insert(vers, tuiles.removeAt(de));
    erreur = null;
    notifyListeners();
    _enFile(_realignerOrdre);
  }

  // ------------------------------------------------------------------
  void _envoyer(TuilePhoto t) {
    _enFile(() async {
      if (t.retiree) return; // retirée avant son tour
      try {
        final enregistree = await _repository.envoyer(idAnnonce, t.choisie!, _ordreLibre());
        t.enregistree = enregistree;
        if (t.retiree) {
          // Retirée pendant l'envoi : on annule côté serveur.
          await _repository.supprimer(enregistree);
          t.enregistree = null;
          return;
        }
        t.etat = EtatPhoto.envoyee;
      } on PhotosException catch (e) {
        t
          ..etat = EtatPhoto.echec
          ..erreur = e.message;
        return;
      } finally {
        notifyListeners();
      }
      await _realignerOrdre(); // une erreur ici s'affiche dans [erreur]
    });
  }

  /// Plus petit numéro d'ordre (0..9) pas encore pris en base.
  int _ordreLibre() {
    final pris = {for (final t in tuiles) if (t.enregistree != null) t.enregistree!.ordre};
    var o = 0;
    while (pris.contains(o)) {
      o++;
    }
    return o;
  }

  /// Renumérote en base 0, 1, 2… dans l'ordre de l'écran, si nécessaire.
  Future<void> _realignerOrdre() async {
    final envoyees = [for (final t in tuiles) if (t.enregistree != null && !t.retiree) t];
    final dejaBon = envoyees.indexed.every((e) => e.$2.enregistree!.ordre == e.$1);
    if (dejaBon) return;
    await _repository.ordonner([for (final t in envoyees) t.enregistree!]);
    for (final (i, t) in envoyees.indexed) {
      t.enregistree = t.enregistree!.avecOrdre(i);
    }
  }

  void _enFile(Future<void> Function() action) {
    _file = _file.then((_) async {
      try {
        await action();
      } on PhotosException catch (e) {
        erreur = e.message;
      } finally {
        notifyListeners();
      }
    });
  }

  // La file peut finir après la fermeture de l'écran : pas de notification
  // sur un ViewModel détruit.
  bool _detruit = false;

  @override
  void notifyListeners() {
    if (!_detruit) super.notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
