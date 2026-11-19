// Faux dépôts (en mémoire) pour les tests de la 9.1 / 9.2.
import 'dart:async';

import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';
import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/admin/data/models/compte_admin.dart';
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

/// Signalements : 2 sur l'annonce s1 (dont un avec précision), 1 sur s2.
List<AnnonceSignalee> signalementsTest() => [
      AnnonceSignalee(
        idAnnonce: 's1',
        titre: 'Studio meublé étudiant',
        statut: StatutAnnonce.publiee,
        typeBien: TypeBien.appartement,
        typeOffre: TypeOffre.location,
        prix: 450,
        ville: 'Sfax',
        nomAnnonceur: 'Sami Vendeur',
        signalements: [
          SignalementRecu(id: 2, motif: 'Photos ne correspondant pas au bien', date: dateModeration.subtract(const Duration(days: 3)), nomAuteur: 'Lina Acheteuse'),
          SignalementRecu(
            id: 5,
            motif: 'Annonce frauduleuse ou arnaque — Le vendeur demande un acompte avant toute visite.',
            date: dateModeration.subtract(const Duration(hours: 2)),
            nomAuteur: 'Karim Jaziri',
          ),
        ],
      ),
      AnnonceSignalee(
        idAnnonce: 's2',
        titre: 'Local commercial Gabès',
        statut: StatutAnnonce.publiee,
        typeBien: TypeBien.local,
        typeOffre: TypeOffre.location,
        prix: 1200,
        ville: 'Gabès',
        signalements: [
          SignalementRecu(id: 7, motif: 'Bien déjà vendu ou loué', date: dateModeration.subtract(const Duration(hours: 1))),
        ],
      ),
    ];

/// Comptes : un admin, deux utilisateurs dont un déjà bloqué, un compte sans nom.
List<CompteAdmin> comptesTest() => [
      const CompteAdmin(id: 'adm', nom: 'Admin DarImmo', email: 'admin@darimmo.test', estAdmin: true, bloque: false),
      const CompteAdmin(id: 'lina', nom: 'Lina Acheteuse', email: 'acheteur@darimmo.test', estAdmin: false, bloque: false),
      const CompteAdmin(id: 'sami', nom: 'Sami Vendeur', email: 'vendeur@darimmo.test', estAdmin: false, bloque: true),
      const CompteAdmin(id: 'ali', nom: '', email: 'ali.test@gmail.com', estAdmin: false, bloque: false),
    ];

class FausseModeration implements ModerationRepository {
  FausseModeration([List<AnnonceAModerer>? annonces, List<AnnonceSignalee>? signales, List<CompteAdmin>? comptes])
      : signales = signales ?? signalementsTest(),
        comptesEnBase = comptes ?? comptesTest(),
        annonces = annonces ??
            [
              annonceAModerer('m1', titre: 'Appartement s+2', heures: 30),
              annonceAModerer('m2', titre: 'Villa Hammamet', heures: 3, nom: 'Ines Gharbi'),
            ];

  final List<AnnonceAModerer> annonces;
  final List<AnnonceSignalee> signales;
  final List<CompteAdmin> comptesEnBase;

  /// Recherches reçues (null ou '' = comptes bloqués).
  final recherches = <String?>[];
  final masquees = <String>[];
  final traites = <int>[];
  final classes = <int>[];
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

  @override
  Future<List<AnnonceSignalee>> signalements() async {
    _verifier();
    return [...signales];
  }

  @override
  Future<void> masquer(String idAnnonce, List<int> idsSignalements) async {
    await attente?.future;
    _verifier();
    signales.removeWhere((a) => a.idAnnonce == idAnnonce);
    masquees.add(idAnnonce);
    traites.addAll(idsSignalements);
  }

  @override
  Future<void> classer(List<int> idsSignalements) async {
    await attente?.future;
    _verifier();
    signales.removeWhere((a) => a.ids.any(idsSignalements.contains));
    classes.addAll(idsSignalements);
  }

  @override
  Future<List<CompteAdmin>> comptes(String? recherche) async {
    recherches.add(recherche);
    _verifier();
    final q = (recherche ?? '').trim().toLowerCase();
    return [
      for (final c in comptesEnBase)
        if (q.isEmpty ? c.bloque : (c.nom.toLowerCase().contains(q) || (c.email ?? '').toLowerCase().contains(q))) c,
    ];
  }

  @override
  Future<void> bloquer(String idCompte, {required bool bloque}) async {
    await attente?.future;
    _verifier();
    final i = comptesEnBase.indexWhere((c) => c.id == idCompte);
    comptesEnBase[i] = comptesEnBase[i].avecBlocage(bloque);
  }
}
