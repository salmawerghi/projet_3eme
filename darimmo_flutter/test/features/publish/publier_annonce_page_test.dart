// Tests de l'écran [6.1] et du parcours complet (photos [6.2], emplacement [6.4])
// avec de faux repositories / services.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/repositories/annonce_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/presentation/screens/publier_annonce_page.dart';

import 'faux_photos_repository.dart';
import 'faux_position.dart';

/// Faux repository qui imite le trigger annonces_statut.
class FauxRepository implements AnnonceRepository {
  FauxRepository({this.erreur});
  final String? erreur;
  final brouillons = <NouvelleAnnonce>[];
  final modifiees = <(EditionAnnonce, NouvelleAnnonce)>[];
  final validees = <String>[];
  final positions = <String, LatLng>{};
  final _valeurs = <String, NouvelleAnnonce>{};
  final _statuts = <String, StatutAnnonce>{};

  @override
  Future<Annonce> creerBrouillon(NouvelleAnnonce a) async {
    brouillons.add(a);
    if (erreur != null) throw PublicationException(erreur!);
    _valeurs['id-test'] = a;
    _statuts['id-test'] = StatutAnnonce.brouillon;
    return _annonce('id-test', a, StatutAnnonce.brouillon);
  }

  @override
  Future<Annonce> modifier(EditionAnnonce e, NouvelleAnnonce a) async {
    modifiees.add((e, a));
    if (erreur != null) throw PublicationException(erreur!);
    _valeurs[e.id] = a;
    // Comme le trigger : une annonce publiée modifiée repasse en attente ; sinon statut inchangé.
    final s = e.statut == StatutAnnonce.publiee ? StatutAnnonce.enAttente : e.statut;
    _statuts[e.id] = s;
    return _annonce(e.id, a, s);
  }

  @override
  Future<Annonce> finaliser(String id,
      {required double latitude, required double longitude, required bool envoyerEnValidation}) async {
    positions[id] = LatLng(latitude, longitude);
    if (envoyerEnValidation) {
      validees.add(id);
      _statuts[id] = StatutAnnonce.enAttente;
    }
    return _annonce(id, _valeurs[id]!, _statuts[id]!);
  }

  static Annonce _annonce(String id, NouvelleAnnonce a, StatutAnnonce s) => Annonce(
        id: id, titre: a.titre.trim(), typeBien: a.typeBien, typeOffre: a.typeOffre,
        prix: a.prix, ville: a.ville.trim(), statut: s, dateCreation: DateTime(2026, 11, 6, 10, 42),
      );
}

const villa = NouvelleAnnonce(
  titre: 'Villa s+4', typeBien: TypeBien.villa, typeOffre: TypeOffre.vente,
  prix: 450000, surface: 220, nbPieces: 5, ville: 'Hammamet', description: 'Avec piscine',
);

void grandEcran(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> ouvrir(WidgetTester tester, AnnonceRepository repo,
    {FauxPhotosRepository? photos, FausseGalerie? galerie}) async {
  grandEcran(tester);
  await tester.pumpWidget(MaterialApp(
    theme: darimmoTheme(),
    home: PublierAnnoncePage(
      repository: repo,
      photosRepository: photos ?? FauxPhotosRepository(),
      choisirPhotos: (galerie ?? FausseGalerie()).choisir,
      geocodage: FauxGeocodage(),
      localisation: FausseLocalisation(),
      afficherTuiles: false,
    ),
  ));
}

Future<void> remplir(WidgetTester tester) async {
  await tester.tap(find.text('Appartement'));
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : Appartement S+3 haut standing'), 'Appartement S+3 haut standing');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : 385 000'), '385 000');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : 120'), '145');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : La Marsa, Tunis'), 'Ennasr 2, Ariana');
  await tester.pump();
}

Future<void> continuer(WidgetTester tester) async {
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulaire vide : erreurs affichées, rien n’est envoyé', (tester) async {
    final repo = FauxRepository();
    await ouvrir(tester, repo);
    await continuer(tester);

    expect(find.text('Choisissez un type de bien'), findsOneWidget);
    expect(find.text('Le titre est obligatoire'), findsOneWidget);
    expect(find.text('Le prix est obligatoire'), findsOneWidget);
    expect(find.text('La surface est obligatoire'), findsOneWidget);
    expect(find.text('La ville est obligatoire'), findsOneWidget);
    expect(repo.brouillons, isEmpty);
  });

  testWidgets('parcours complet : brouillon, photos, emplacement, puis « en attente »', (tester) async {
    final repo = FauxRepository();
    final photos = FauxPhotosRepository();
    final galerie = FausseGalerie([photo('salon.jpg'), photo('cuisine.jpg')]);
    await ouvrir(tester, repo, photos: photos, galerie: galerie);
    await tester.tap(find.text('Louer'));
    await remplir(tester);
    await continuer(tester);

    // Étape 1 : brouillon créé avec les valeurs saisies
    final a = repo.brouillons.single;
    expect(a.typeBien, TypeBien.appartement);
    expect(a.typeOffre, TypeOffre.location);
    expect(a.prix, 385000);
    expect(a.surface, 145);
    expect(a.nbPieces, 3);
    expect(a.versLigne('u1')['statut'], 'brouillon');

    // Étape 2 : photos
    expect(find.text('Étape 2 sur 3'), findsOneWidget);
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(photos.envoyees, ['salon.jpg', 'cuisine.jpg']);
    expect(photos.ordres, [0, 1]);
    expect(find.text('Photos (2/10)'), findsOneWidget);
    await continuer(tester);

    // Étape 3 : emplacement, centré sur la ville saisie (Ennasr 2, Ariana)
    expect(find.text('Étape 3 sur 3'), findsOneWidget);
    expect(find.textContaining('Position approximative'), findsOneWidget);
    await tester.tap(find.text('Envoyer pour validation'));
    await tester.pumpAndSettle();
    expect(repo.positions['id-test'], ennasr);
    expect(repo.validees, ['id-test']);
    expect(find.text('Annonce envoyée !'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('385 000 DT/mois'), findsOneWidget);
  });

  testWidgets('retour au formulaire puis « Continuer » : le brouillon est mis à jour, pas dupliqué', (tester) async {
    final repo = FauxRepository();
    await ouvrir(tester, repo);
    await remplir(tester);
    await continuer(tester);
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Publier une annonce'), findsOneWidget, reason: 'textes de création conservés');

    await tester.enterText(find.widgetWithText(TextFormField, '385 000'), '390 000');
    await continuer(tester);
    expect(repo.brouillons, hasLength(1));
    expect(repo.modifiees.single.$1.id, 'id-test');
    expect(repo.modifiees.single.$2.prix, 390000);
    expect(find.text('Étape 2 sur 3'), findsOneWidget);
  });

  testWidgets('terrain : le compteur de pièces disparaît', (tester) async {
    await ouvrir(tester, FauxRepository());
    expect(find.text('Nombre de pièces'), findsOneWidget);
    await tester.tap(find.text('Terrain'));
    await tester.pump();
    expect(find.text('Nombre de pièces'), findsNothing);
  });

  testWidgets('erreur du serveur : message affiché, on reste sur le formulaire', (tester) async {
    final repo = FauxRepository(erreur: 'Publication refusée : votre compte est peut-être bloqué.');
    await ouvrir(tester, repo);
    await remplir(tester);
    await continuer(tester);

    expect(find.text('Étape 2 sur 3'), findsNothing);
    expect(find.textContaining('Publication refusée'), findsOneWidget);
  });

  group('[6.3] Modifier une annonce', () {
    test('versContenu n’envoie ni statut ni annonceur', () {
      final c = villa.versContenu();
      expect(c.containsKey('statut'), isFalse);
      expect(c.containsKey('id_annonceur'), isFalse);
      expect(c['titre'], 'Villa s+4');
    });

    test('seules une annonce rejetée ou un brouillon sont renvoyés explicitement', () {
      EditionAnnonce e(StatutAnnonce s) => EditionAnnonce(id: 'x', statut: s, valeurs: villa);
      expect(e(StatutAnnonce.rejetee).renvoyerEnValidation, isTrue);
      expect(e(StatutAnnonce.brouillon).renvoyerEnValidation, isTrue);
      // publiée : le trigger s'en charge ; envoyer le statut serait refusé
      expect(e(StatutAnnonce.publiee).renvoyerEnValidation, isFalse);
      expect(e(StatutAnnonce.enAttente).renvoyerEnValidation, isFalse);
    });

    /// Ouvre le formulaire en modification ; [retour] reçoit ce que l'écran renvoie.
    Future<void> ouvrirEdition(WidgetTester tester, FauxRepository repo, StatutAnnonce statut,
        void Function(Annonce?) retour) async {
      grandEcran(tester);
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              retour(await Navigator.push<Annonce>(context, MaterialPageRoute(
                builder: (_) => PublierAnnoncePage(
                  repository: repo,
                  photosRepository: FauxPhotosRepository(),
                  choisirPhotos: FausseGalerie().choisir,
                  geocodage: FauxGeocodage(),
                  localisation: FausseLocalisation(),
                  afficherTuiles: false,
                  edition: EditionAnnonce(
                      id: 'id-villa', statut: statut, valeurs: villa,
                      latitude: lac2.latitude, longitude: lac2.longitude),
                ),
              )));
            },
            child: const Text('ouvrir'),
          ),
        ),
      ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('annonce publiée : pré-remplie, enregistrée, « Terminer » sans renvoi', (tester) async {
      final repo = FauxRepository();
      Annonce? retour;
      await ouvrirEdition(tester, repo, StatutAnnonce.publiee, (a) => retour = a);

      expect(find.text('Modifier l’annonce'), findsOneWidget);
      expect(find.textContaining('elle sera retirée'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Villa s+4'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '450 000'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Hammamet'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // compteur de pièces

      await tester.enterText(find.widgetWithText(TextFormField, '450 000'), '420 000');
      await continuer(tester);

      expect(repo.brouillons, isEmpty, reason: 'pas de nouvelle annonce');
      final (edition, valeurs) = repo.modifiees.single;
      expect(edition.id, 'id-villa');
      expect(valeurs.prix, 420000);
      expect(valeurs.description, 'Avec piscine');

      await continuer(tester); // photos -> emplacement
      expect(find.text('Lat. 36,8421 · Long. 10,2752'), findsOneWidget, reason: 'position existante reprise');
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      expect(repo.positions['id-villa'], lac2);
      expect(repo.validees, isEmpty, reason: 'le trigger l’a déjà remise en attente');
      expect(retour?.statut, StatutAnnonce.enAttente);
      expect(find.text('Annonce envoyée !'), findsNothing);
      expect(find.text('ouvrir'), findsOneWidget, reason: 'écrans fermés');
    });

    testWidgets('annonce rejetée : « Renvoyer pour validation » à la fin', (tester) async {
      final repo = FauxRepository();
      Annonce? retour;
      await ouvrirEdition(tester, repo, StatutAnnonce.rejetee, (a) => retour = a);
      await continuer(tester); // formulaire -> photos
      await continuer(tester); // photos -> emplacement
      await tester.tap(find.text('Renvoyer pour validation'));
      await tester.pumpAndSettle();
      expect(repo.validees, ['id-villa']);
      expect(retour?.statut, StatutAnnonce.enAttente);
    });
  });
}
