// Tests de la 4.1 « Voir les annonces sur une carte » et de la 4.2 « Voir les
// biens autour de moi » (maquette B3). Tâches du membre B, réalisées par le
// membre C. Aucun accès réseau ni GPS.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:darimmo/features/map/data/models/annonce_carte.dart';
import 'package:darimmo/features/map/presentation/screens/carte_page.dart';
import 'package:darimmo/features/map/presentation/viewmodels/carte_view_model.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

import '../../app/navigation_test.dart' show demarrer;
import '../publish/faux_position.dart';
import 'fausse_carte.dart';

/// Réponse réelle de la base (requête testée avec la clé publique), photos mélangées exprès.
Map<String, dynamic> ligneReelle() => {
      'id': '7a9b4b38-e758-4a60-a771-38c2016fbd2f',
      'titre': 'Appartement S+2 lumineux',
      'type_bien': 'appartement',
      'type_offre': 'location',
      'prix': 950.00,
      'ville': 'Tunis',
      'latitude': 36.8008,
      'longitude': 10.1815,
      'photos': [
        {'url': 'https://exemple.test/b.jpg', 'ordre': 1},
        {'url': 'https://exemple.test/a.jpg', 'ordre': 0},
      ],
    };

/// L'écran seul ; renvoie la liste des annonces ouvertes.
Future<List<String>> ouvrir(WidgetTester tester, FausseCarte repo, {FausseLocalisation? localisation}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ouvertes = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: CartePage(
      repository: repo,
      localisation: localisation ?? FausseLocalisation(),
      afficherTuiles: false,
      onOuvrirAnnonce: (_, id) => ouvertes.add(id),
      onQuitter: (_) {},
    ),
  ));
  await tester.pumpAndSettle();
  return ouvertes;
}

String resume(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('resume-carte'))).data!;

void main() {
  group('Modèle', () {
    test('depuisLigne lit la réponse de la base, 1re photo dans l’ordre', () {
      final a = AnnonceCarte.depuisLigne(ligneReelle())!;
      expect(a.titre, 'Appartement S+2 lumineux');
      expect(a.typeOffre, TypeOffre.location);
      expect(a.position, const LatLng(36.8008, 10.1815));
      expect(a.photoCouverture, 'https://exemple.test/a.jpg');
    });

    test('sans position : pas de marqueur possible -> null ; sans photo -> null', () {
      expect(AnnonceCarte.depuisLigne({...ligneReelle(), 'latitude': null}), isNull);
      expect(AnnonceCarte.depuisLigne({...ligneReelle(), 'photos': []})!.photoCouverture, isNull);
    });

    test('prix court des marqueurs (maquette B3)', () {
      AnnonceCarte a(double prix, [TypeOffre o = TypeOffre.vente]) =>
          annonceCarte('x', centreHammamet, prix: prix, offre: o);
      expect(libellePrixCourt(a(1250000)), '1,25 M');
      expect(libellePrixCourt(a(1000000)), '1 M');
      expect(libellePrixCourt(a(950000)), '950 k');
      expect(libellePrixCourt(a(65000)), '65 k');
      expect(libellePrixCourt(a(800)), '800');
      expect(libellePrixCourt(a(1400, TypeOffre.location)), '1 400 DT/m');
      expect(libellePrixComplet(a(385000)), '385 000 DT');
      expect(libellePrixComplet(a(950, TypeOffre.location)), '950 DT/mois');
    });

    test('cadreDuRayon contient le cercle', () {
      final c = cadreDuRayon(centreHammamet, 5000);
      const d = Distance();
      expect(d(centreHammamet, LatLng(c.north, centreHammamet.longitude)), closeTo(5000, 25));
      expect(d(centreHammamet, LatLng(centreHammamet.latitude, c.east)), closeTo(5000, 25));
    });
  });

  group('CarteViewModel', () {
    test('4.1 : toutes les annonces', () async {
      final vm = CarteViewModel(repository: FausseCarte(), localisation: FausseLocalisation());
      await vm.afficherToutes();
      expect(vm.mode, ModeCarte.toutes);
      expect(vm.annonces.map((a) => a.id), ['h1', 'h2', 'h3', 't1']);
    });

    test('4.2 : position demandée seulement au clic, puis rayon de 5 km autour', () async {
      final repo = FausseCarte();
      final loc = FausseLocalisation();
      final vm = CarteViewModel(repository: repo, localisation: loc);
      await vm.afficherToutes();
      expect(loc.appels, 0, reason: 'pas de demande de position à l’ouverture');

      expect(await vm.activerAutourDeMoi(), isTrue);
      expect(loc.appels, 1);
      expect(vm.mode, ModeCarte.autour);
      expect(vm.maPosition, telephone);
      expect(repo.appelsAutour.single, (telephone, 5000));
      expect(vm.annonces.map((a) => a.id), ['h1', 'h2', 'h3'], reason: 'la plus proche d’abord, Tunis exclue');
    });

    test('4.2 : changer de rayon relance la fonction PostGIS', () async {
      final repo = FausseCarte();
      final vm = CarteViewModel(repository: repo, localisation: FausseLocalisation());
      await vm.activerAutourDeMoi();
      await vm.changerRayon(2);
      expect(repo.appelsAutour.last.$2, 2000);
      expect(vm.annonces.map((a) => a.id), ['h1', 'h2']);
    });

    test('4.2 : refus de la position -> message, on reste sur toutes les annonces', () async {
      final repo = FausseCarte();
      final vm = CarteViewModel(
        repository: repo,
        localisation: FausseLocalisation(erreur: 'Autorisez DarImmo à accéder à votre position.'),
      );
      await vm.afficherToutes();
      expect(await vm.activerAutourDeMoi(), isFalse);
      expect(vm.messageLocalisation, 'Autorisez DarImmo à accéder à votre position.');
      expect(vm.mode, ModeCarte.toutes);
      expect(vm.annonces, hasLength(4));
      expect(repo.appelsAutour, isEmpty);
    });

    test('réponse en retard ignorée (rayon changé deux fois de suite)', () async {
      final repo = FausseCarte();
      final vm = CarteViewModel(repository: repo, localisation: FausseLocalisation());
      await vm.activerAutourDeMoi();
      repo.bloquer = true;
      final r1 = vm.changerRayon(1); // 1 km : h1
      final r20 = vm.changerRayon(20); // 20 km : h1 h2 h3
      repo.liberer(); // la réponse « 1 km » arrive…
      repo.liberer(); // … puis « 20 km »
      await Future.wait([r1, r20]);
      expect(vm.rayonKm, 20);
      expect(vm.annonces.map((a) => a.id), ['h1', 'h2', 'h3']);
    });

    test('la sélection disparaît si l’annonce sort du rayon', () async {
      final vm = CarteViewModel(repository: FausseCarte(), localisation: FausseLocalisation());
      await vm.activerAutourDeMoi();
      vm.selectionner('h3');
      expect(vm.selection?.id, 'h3');
      await vm.changerRayon(1);
      expect(vm.selection, isNull);
    });

    test('erreur réseau puis Réessayer', () async {
      final repo = FausseCarte()..echec = true;
      final vm = CarteViewModel(repository: repo, localisation: FausseLocalisation());
      await vm.afficherToutes();
      expect(vm.erreur, contains('Connexion impossible'));
      await vm.reessayer();
      expect(vm.erreur, isNull);
      expect(vm.annonces, hasLength(4));
    });
  });

  group('Écran (maquette B3)', () {
    testWidgets('4.1 : un marqueur par bien ; marqueur -> aperçu ; aperçu -> détail', (tester) async {
      final ouvertes = await ouvrir(tester, FausseCarte());

      expect(resume(tester), '4 biens sur la carte');
      for (final prix in ['950 DT/m', '1,25 M', '385 k', '540 k']) {
        expect(find.text(prix), findsOneWidget, reason: prix);
      }
      expect(find.byKey(const Key('apercu-annonce')), findsNothing);

      await tester.tap(find.text('1,25 M'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apercu-annonce')), findsOneWidget);
      expect(find.text('1 250 000 DT'), findsOneWidget);
      expect(find.text('Villa jardin'), findsOneWidget);

      await tester.tap(find.byKey(const Key('apercu-annonce')));
      expect(ouvertes, ['h2']);
    });

    testWidgets('4.2 : Autour de moi -> rayon, ma position, biens proches ; rayon modifiable', (tester) async {
      final repo = FausseCarte();
      await ouvrir(tester, repo);

      await tester.tap(find.byKey(const Key('puce-autour')));
      await tester.pumpAndSettle();
      expect(resume(tester), 'Rayon 5 km · 3 biens');
      expect(find.bySemanticsLabel('Ma position'), findsOneWidget);
      expect(find.text('540 k'), findsNothing, reason: 'Tunis est hors du rayon');

      await tester.tap(find.text('1 km'));
      await tester.pumpAndSettle();
      expect(resume(tester), 'Rayon 1 km · 1 bien');
      expect(repo.appelsAutour.last.$2, 1000);

      // Retour à toutes les annonces
      await tester.tap(find.byKey(const Key('puce-autour')));
      await tester.pumpAndSettle();
      expect(resume(tester), '4 biens sur la carte');
      expect(find.text('1 km'), findsNothing);
    });

    testWidgets('4.2 : rayon sans bien -> conseil d’élargir', (tester) async {
      await ouvrir(tester, FausseCarte([annonceCarte('t1', const LatLng(36.8008, 10.1815))]));
      await tester.tap(find.byKey(const Key('puce-autour')));
      await tester.pumpAndSettle();
      expect(resume(tester), 'Rayon 5 km · aucun bien');
      expect(find.textContaining('Choisissez un rayon plus grand'), findsOneWidget);
    });

    testWidgets('4.2 : autorisation refusée -> message explicatif, Réessayer, Fermer', (tester) async {
      final loc = FausseLocalisation(erreur: 'Autorisez DarImmo à accéder à votre position pour utiliser ce bouton.');
      await ouvrir(tester, FausseCarte(), localisation: loc);

      await tester.tap(find.byTooltip('Me localiser'));
      await tester.pumpAndSettle();
      expect(find.text('Autorisez DarImmo à accéder à votre position pour utiliser ce bouton.'), findsOneWidget);
      expect(resume(tester), '4 biens sur la carte');

      loc.erreur = null; // l'utilisateur a autorisé dans la fenêtre système
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(resume(tester), 'Rayon 5 km · 3 biens');
      expect(find.textContaining('Autorisez'), findsNothing);
    });

    testWidgets('erreur réseau -> Réessayer', (tester) async {
      await ouvrir(tester, FausseCarte()..echec = true);
      expect(find.textContaining('Connexion impossible'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(resume(tester), '4 biens sur la carte');
    });
  });

  group('Navigation', () {
    testWidgets('accueil -> Voir la carte -> marqueur -> aperçu -> détail', (tester) async {
      await demarrer(tester, connecte: false, initiale: '/accueil');
      await tester.tap(find.text('Voir la carte'));
      await tester.pumpAndSettle();
      expect(find.byType(CartePage), findsOneWidget);

      await tester.tap(find.text('1,25 M'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apercu-annonce')));
      await tester.pumpAndSettle();
      expect(find.byType(CartePage), findsNothing);
    });
  });
}
