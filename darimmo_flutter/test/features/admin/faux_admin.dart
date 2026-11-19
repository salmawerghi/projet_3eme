// Faux dépôts (en mémoire) pour les tests de la 9.1 / 9.2.
import 'dart:async';

import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';
import 'package:darimmo/features/auth/data/repositories/compte_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

final dateModeration = DateTime(2026, 11, 19, 12);

class FauxCompte implements CompteRepository {
  FauxCompte({this.admin = false, this.bloque = false});
  bool admin;
  bool bloque;
  int lectures = 0;

  @override
  Future<InfosCompte> lire() async {
    lectures++;
    return InfosCompte(estAdmin: admin, estBloque: bloque);
  }
}

AnnonceAModerer annonceAModerer(String id, {String? titre, int heures = 3, String? nom = 'Sami Vendeur'}) =>
    AnnonceAModerer(
      id: id,
      titre: titre ?? 'Annonce $id',
      typeBien: TypeBien.appartement,
      typeOffre: TypeOffre.vente,
      prix: 345000,
      ville: 'La Marsa',
      nomAnnonceur: nom,
      envoyeeLe: dateModeration.subtract(Duration(hours: heures)),
    );

class FausseModeration implements ModerationRepository {
  FausseModeration([List<AnnonceAModerer>? annonces])
      : annonces = annonces ??
            [
              annonceAModerer('m1', titre: 'Appartement s+2', heures: 30),
              annonceAModerer('m2', titre: 'Villa Hammamet', heures: 3, nom: 'Ines Gharbi'),
            ];

  final List<AnnonceAModerer> annonces;
  final validees = <String>[];
  final rejets = <String, String>{};

  /// Prochaine erreur (une seule fois).
  ModerationException? erreur;

  /// Si non nul, valider / rejeter attendent ce Completer.
  Completer<void>? attente;

  void _verifier() {
    final e = erreur;
    if (e != null) {
      erreur = null;
      throw e;
    }
  }

  @override
  Future<List<AnnonceAModerer>> enAttente() async {
    _verifier();
    return [...annonces];
  }

  @override
  Future<void> valider(String idAnnonce) async {
    await attente?.future;
    _verifier();
    annonces.removeWhere((a) => a.id == idAnnonce);
    validees.add(idAnnonce);
  }

  @override
  Future<void> rejeter(String idAnnonce, String motif) async {
    await attente?.future;
    _verifier();
    annonces.removeWhere((a) => a.id == idAnnonce);
    rejets[idAnnonce] = motif;
  }
}
