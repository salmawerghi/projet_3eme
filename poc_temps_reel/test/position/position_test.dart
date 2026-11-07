// Tests de [6.4] Placer mon bien sur la carte (faux géocodage / GPS, carte sans tuiles).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc_temps_reel/core/darimmo_theme.dart';
import 'package:poc_temps_reel/features/position/data/geocodage.dart';
import 'package:poc_temps_reel/features/position/position_view_model.dart';
import 'package:poc_temps_reel/features/position/ui/position_annonce_page.dart';

import 'faux_position.dart';

void main() {
  group('NominatimGeocodage', () {
    test('requête limitée à la Tunisie, en français, et lecture de la réponse', () async {
      late Uri appelee;
      final client = MockClient((req) async {
        appelee = req.url;
        return http.Response(
            '[{"display_name":"Lac 2, Tunis","lat":"36.8421","lon":"10.2752"}]', 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final r = await NominatimGeocodage(client).rechercher('Lac 2');
      expect(appelee.host, 'nominatim.openstreetmap.org');
      expect(appelee.queryParameters['countrycodes'], 'tn');
      expect(appelee.queryParameters['accept-language'], 'fr');
      expect(r.single.libelle, 'Lac 2, Tunis');
      expect(r.single.position, lac2);
    });

    test('trop de requêtes (429) : message clair', () async {
      final client = MockClient((_) async => http.Response('', 429));
      expect(
        () => NominatimGeocodage(client).rechercher('Lac 2'),
        throwsA(isA<GeocodageException>().having((e) => e.message, 'message', contains('patientez'))),
      );
    });

    test('moins de 3 caractères : pas de requête', () async {
      var appels = 0;
      final client = MockClient((_) async {
        appels++;
        return http.Response('[]', 200);
      });
      expect(await NominatimGeocodage(client).rechercher('ab'), isEmpty);
      expect(appels, 0);
    });
  });

  group('PositionViewModel', () {
    test('nouvelle annonce : centrée sur l’adresse de l’étape 1, position approximative', () async {
      final geo = FauxGeocodage();
      final centres = <LatLng>[];
      final vm = PositionViewModel(geo, FausseLocalisation(), rechercheInitiale: 'Rue 1, Ennasr 2')
        ..onCentrer = centres.add;
      await vm.initialiser();
      expect(vm.position, ennasr);
      expect(vm.approximative, isTrue);
      expect(centres, [ennasr]);
    });

    test('annonce déjà placée : aucune recherche automatique', () async {
      final geo = FauxGeocodage();
      final vm = PositionViewModel(geo, FausseLocalisation(), initiale: lac2, rechercheInitiale: 'Ennasr');
      await vm.initialiser();
      expect(geo.recherches, isEmpty);
      expect(vm.position, lac2);
      expect(vm.modifiee, isFalse);
    });

    test('recherche d’adresse puis choix d’un résultat', () async {
      final vm = PositionViewModel(FauxGeocodage(), FausseLocalisation());
      await vm.rechercher('Lac');
      expect(vm.resultats, hasLength(2));
      vm.choisirResultat(vm.resultats.first);
      expect(vm.position, lac2);
      expect(vm.approximative, isFalse);
      expect(vm.resultats, isEmpty);
    });

    test('recherche trop courte ou sans résultat : message', () async {
      final vm = PositionViewModel(FauxGeocodage(), FausseLocalisation());
      await vm.rechercher('ab');
      expect(vm.erreur, contains('3 caractères'));
      await vm.rechercher('Tozeur');
      expect(vm.erreur, contains('Aucune adresse'));
    });

    test('ma position : succès, puis refus avec message', () async {
      final loc = FausseLocalisation();
      final vm = PositionViewModel(FauxGeocodage(), loc);
      await vm.utiliserMaPosition();
      expect(vm.position, telephone);

      loc.erreur = 'Autorisez DarImmo à accéder à votre position pour utiliser ce bouton.';
      await vm.utiliserMaPosition();
      expect(vm.erreur, contains('Autorisez DarImmo'));
      expect(vm.position, telephone, reason: 'la position précédente est gardée');
    });

    test('placer à la main : arrondi à 6 décimales', () {
      final vm = PositionViewModel(FauxGeocodage(), FausseLocalisation());
      vm.placer(const LatLng(36.123456789, 10.987654321));
      expect(vm.position, const LatLng(36.123457, 10.987654));
      expect(vm.modifiee, isTrue);
    });
  });

  group('Écran Emplacement (maquette C3)', () {
    Future<void> ouvrir(WidgetTester tester,
        {LatLng? initiale,
        String? recherche,
        FauxGeocodage? geo,
        FausseLocalisation? loc,
        Future<String?> Function(LatLng)? onValider,
        void Function(bool?)? retour}) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final r = await Navigator.push<bool>(context, MaterialPageRoute(
                builder: (_) => PositionAnnoncePage(
                  geocodage: geo ?? FauxGeocodage(),
                  localisation: loc ?? FausseLocalisation(),
                  positionInitiale: initiale,
                  rechercheInitiale: recherche,
                  libelleBouton: 'Envoyer pour validation',
                  afficherTuiles: false,
                  onValider: onValider ?? (_) async => null,
                ),
              ));
              retour?.call(r);
            },
            child: const Text('ouvrir'),
          ),
        ),
      ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    FilledButton bouton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Envoyer pour validation'));

    testWidgets('sans position : bouton bloqué ; toucher la carte place le marqueur', (tester) async {
      await ouvrir(tester);
      expect(find.text('Étape 3 sur 3'), findsOneWidget);
      expect(find.textContaining('Aucune position'), findsOneWidget);
      expect(bouton(tester).onPressed, isNull);

      await tester.tapAt(tester.getCenter(find.byType(PositionAnnoncePage)) + const Offset(0, -40));
      // flutter_map attend la fin du délai « double-tap » (zoom) avant de signaler un toucher simple.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('marqueur')), findsOneWidget);
      expect(find.textContaining('Lat. '), findsOneWidget);
      expect(bouton(tester).onPressed, isNotNull);
    });

    testWidgets('adresse de l’étape 1 : position approximative signalée', (tester) async {
      await ouvrir(tester, recherche: 'Ennasr 2, Ariana');
      expect(find.textContaining('Lat. 36,8601 · Long. 10,1655'), findsOneWidget);
      expect(find.textContaining('Position approximative'), findsOneWidget);
    });

    testWidgets('rechercher une adresse puis choisir un résultat', (tester) async {
      await ouvrir(tester);
      await tester.enterText(find.byType(TextField), 'Lac');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Rue du Lac Léman, Les Berges du Lac 2, Tunis'), findsOneWidget);

      await tester.tap(find.text('Rue du Lac Léman, Les Berges du Lac 2, Tunis'));
      await tester.pumpAndSettle();
      expect(find.text('Lat. 36,8421 · Long. 10,2752'), findsOneWidget);
    });

    testWidgets('« Utiliser ma position »', (tester) async {
      final loc = FausseLocalisation();
      await ouvrir(tester, loc: loc);
      await tester.tap(find.text('Utiliser ma position'));
      await tester.pumpAndSettle();
      expect(loc.appels, 1);
      expect(find.text('Lat. 36,4513 · Long. 10,7357'), findsOneWidget);
    });

    testWidgets('marqueur déplaçable : le glisser vers la droite augmente la longitude', (tester) async {
      LatLng? enregistree;
      await ouvrir(tester, initiale: lac2, onValider: (p) async {
        enregistree = p;
        return null;
      });
      await tester.drag(find.byKey(const Key('marqueur')), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(find.text('Lat. 36,8421 · Long. 10,2752'), findsNothing);

      await tester.tap(find.text('Envoyer pour validation'));
      await tester.pumpAndSettle();
      expect(enregistree!.longitude, greaterThan(lac2.longitude));
      expect(enregistree!.latitude, closeTo(lac2.latitude, 0.0005), reason: 'déplacement horizontal seulement');
    });

    testWidgets('valider : enregistre la position puis ferme avec true', (tester) async {
      LatLng? recue;
      bool? retour;
      await ouvrir(tester, initiale: lac2, onValider: (p) async {
        recue = p;
        return null;
      }, retour: (r) => retour = r);
      await tester.tap(find.text('Envoyer pour validation'));
      await tester.pumpAndSettle();
      expect(recue, lac2);
      expect(retour, isTrue);
    });

    testWidgets('erreur à l’enregistrement : message, on reste sur l’écran', (tester) async {
      await ouvrir(tester, initiale: lac2, onValider: (_) async => 'Annonce introuvable ou modification refusée.');
      await tester.tap(find.text('Envoyer pour validation'));
      await tester.pumpAndSettle();
      expect(find.text('Annonce introuvable ou modification refusée.'), findsOneWidget);
      expect(find.text('Étape 3 sur 3'), findsOneWidget);
    });
  });
}
