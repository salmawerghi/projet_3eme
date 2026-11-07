// Tests de [6.2] Ajouter des photos, avec un faux repository et une fausse galerie.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';
import 'package:darimmo/features/publish/presentation/viewmodels/photos_view_model.dart';
import 'package:darimmo/features/publish/presentation/screens/photos_annonce_page.dart';

import 'faux_photos_repository.dart';

void main() {
  group('PhotoChoisie', () {
    test('type MIME accepté par le bucket selon l’extension', () {
      expect(photo('a.JPG').typeMime, 'image/jpeg');
      expect(photo('a.jpeg').typeMime, 'image/jpeg');
      expect(photo('a.png').typeMime, 'image/png');
      expect(photo('a.webp').typeMime, 'image/webp');
      expect(photo('a.png').extension, 'png');
    });

    test('seuls les fichiers du dossier de l’annonce sont effacés du stockage', () {
      expect(enregistree('p', 0).dansLeBucket, isTrue);
      final seed = PhotoEnregistree(id: 'p', idAnnonce: 'a1', chemin: 'seed/x.jpg', url: 'u', ordre: 0);
      expect(seed.dansLeBucket, isFalse);
    });
  });

  group('PhotosViewModel', () {
    Future<PhotosViewModel> vm(FauxPhotosRepository repo, FausseGalerie galerie) async {
      final v = PhotosViewModel(repo, 'a1', galerie.choisir);
      await v.charger();
      return v;
    }

    test('charge les photos existantes dans l’ordre', () async {
      final v = await vm(FauxPhotosRepository([enregistree('p2', 1), enregistree('p1', 0)]), FausseGalerie());
      expect(v.tuiles.map((t) => t.enregistree!.id), ['p1', 'p2']);
      expect(v.pret, isTrue);
    });

    test('ajouter : aperçu immédiat, puis envoi avec des ordres 0, 1, 2', () async {
      final repo = FauxPhotosRepository();
      final v = await vm(repo, FausseGalerie([photo('1.jpg'), photo('2.jpg'), photo('3.jpg')]));
      await v.ajouter();
      expect(v.nombre, 3);
      expect(v.envoisEnCours, isTrue, reason: 'les tuiles sont affichées avant la fin de l’envoi');
      await v.termine;
      expect(v.tuiles.every((t) => t.etat == EtatPhoto.envoyee), isTrue);
      expect(repo.ordres, [0, 1, 2]);
      expect(v.pret, isTrue);
    });

    test('jamais plus de 10 photos', () async {
      final existantes = [for (var i = 0; i < 8; i++) enregistree('p$i', i)];
      final galerie = FausseGalerie([for (var i = 0; i < 5; i++) photo('$i.jpg')]);
      final repo = FauxPhotosRepository(existantes);
      final v = await vm(repo, galerie);
      await v.ajouter();
      await v.termine;
      expect(galerie.maximumsDemandes, [2], reason: 'la galerie limite le choix');
      expect(v.nombre, photosMax);
      expect(v.peutAjouter, isFalse);
      expect(repo.ordres..sort(), List.generate(10, (i) => i));
    });

    test('échec d’envoi : message clair, puis « Réessayer » réussit', () async {
      final repo = FauxPhotosRepository()..echecsAVenir = 1;
      final v = await vm(repo, FausseGalerie([photo('1.jpg'), photo('2.jpg')]));
      await v.ajouter();
      await v.termine;
      final echec = v.tuiles.first;
      expect(echec.etat, EtatPhoto.echec);
      expect(echec.erreur, contains('Vérifiez votre connexion'));
      expect(v.pret, isFalse);
      expect(repo.ordres, [0], reason: 'la 2e photo est partie quand même');

      v.reessayer(echec);
      await v.termine;
      expect(echec.etat, EtatPhoto.envoyee);
      expect(v.pret, isTrue);
      // L'ordre en base suit l'écran : la photo réessayée est la couverture.
      expect(echec.enregistree!.ordre, 0);
      expect(v.tuiles[1].enregistree!.ordre, 1);
    });

    test('retirer une photo envoyée : effacée et ordres renumérotés', () async {
      final repo = FauxPhotosRepository([enregistree('p0', 0), enregistree('p1', 1), enregistree('p2', 2)]);
      final v = await vm(repo, FausseGalerie());
      v.retirer(v.tuiles.first);
      await v.termine;
      expect(repo.supprimees, ['p0']);
      expect(v.tuiles.map((t) => t.enregistree!.ordre), [0, 1]);
      expect(repo.ordres, [0, 1]);
    });

    test('retirer une photo en échec : rien à effacer côté serveur', () async {
      final repo = FauxPhotosRepository()..echecsAVenir = 1;
      final v = await vm(repo, FausseGalerie([photo('1.jpg')]));
      await v.ajouter();
      await v.termine;
      v.retirer(v.tuiles.single);
      await v.termine;
      expect(v.nombre, 0);
      expect(repo.supprimees, isEmpty);
      expect(v.pret, isTrue);
    });

    test('suppression refusée : la photo revient à sa place avec un message', () async {
      final repo = FauxPhotosRepository([enregistree('p0', 0), enregistree('p1', 1)])..echecSuppression = true;
      final v = await vm(repo, FausseGalerie());
      v.retirer(v.tuiles.first);
      await v.termine;
      expect(v.tuiles.map((t) => t.enregistree!.id), ['p0', 'p1']);
      expect(v.erreur, contains('Connexion impossible'));
    });

    test('changer l’ordre : la dernière devient la couverture', () async {
      final repo = FauxPhotosRepository([enregistree('p0', 0), enregistree('p1', 1), enregistree('p2', 2)]);
      final v = await vm(repo, FausseGalerie());
      v.deplacer(2, 0);
      await v.termine;
      expect(v.tuiles.map((t) => t.enregistree!.id), ['p2', 'p0', 'p1']);
      expect({for (final p in repo.enBase) p.id: p.ordre}, {'p2': 0, 'p0': 1, 'p1': 2});
      expect(repo.appelsOrdonner, 1);
    });

    test('ordre déjà bon : aucune requête inutile', () async {
      final repo = FauxPhotosRepository([enregistree('p0', 0)]);
      final v = await vm(repo, FausseGalerie([photo('1.jpg')]));
      await v.ajouter();
      await v.termine;
      expect(repo.appelsOrdonner, 0);
    });
  });

  group('Écran Photos (maquette C2)', () {
    Future<void> ouvrir(WidgetTester tester, FauxPhotosRepository repo, FausseGalerie galerie,
        {Future<bool> Function(BuildContext)? onSuivant, void Function(bool?)? retour}) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final r = await Navigator.push<bool>(context, MaterialPageRoute(
                builder: (_) => PhotosAnnoncePage(
                  repository: repo,
                  idAnnonce: 'a1',
                  choisir: galerie.choisir,
                  onSuivant: onSuivant ?? (_) async => true,
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

    testWidgets('bandeau, compteur, ajout et pastille « COUVERTURE »', (tester) async {
      await ouvrir(tester, FauxPhotosRepository(), FausseGalerie([photo('1.jpg'), photo('2.jpg')]));
      expect(find.textContaining('Ajoutez jusqu’à 10 photos'), findsOneWidget);
      expect(find.textContaining('compressées avant l’envoi'), findsOneWidget);
      expect(find.text('Photos (0/10)'), findsOneWidget);

      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      expect(find.text('Photos (2/10)'), findsOneWidget);
      expect(find.text('COUVERTURE'), findsOneWidget);
      expect(find.text('Maintenez une photo et glissez-la pour changer l’ordre.'), findsOneWidget);
    });

    testWidgets('échec : bandeau rouge, bouton bloqué, « Réessayer » débloque', (tester) async {
      final repo = FauxPhotosRepository()..echecsAVenir = 1;
      await ouvrir(tester, repo, FausseGalerie([photo('1.jpg')]));
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.text('Échec'), findsOneWidget);
      expect(find.textContaining('Touchez « Réessayer »'), findsOneWidget);
      final bouton = find.widgetWithText(FilledButton, 'Continuer');
      expect(tester.widget<FilledButton>(bouton).onPressed, isNull);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Échec'), findsNothing);
      expect(tester.widget<FilledButton>(bouton).onPressed, isNotNull);
    });

    testWidgets('la croix retire la photo', (tester) async {
      final repo = FauxPhotosRepository([enregistree('p0', 0), enregistree('p1', 1)]);
      await ouvrir(tester, repo, FausseGalerie());
      expect(find.text('Photos (2/10)'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Retirer la photo').first);
      await tester.pumpAndSettle();
      expect(find.text('Photos (1/10)'), findsOneWidget);
      expect(repo.supprimees, ['p0']);
    });

    testWidgets('« Continuer » : étape suivante terminée -> ferme avec true', (tester) async {
      var appels = 0;
      bool? retour;
      await ouvrir(tester, FauxPhotosRepository(), FausseGalerie(), onSuivant: (_) async {
        appels++;
        return true;
      }, retour: (r) => retour = r);
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(appels, 1);
      expect(retour, isTrue);
    });

    testWidgets('« Continuer » : retour depuis l’étape suivante -> on reste sur les photos', (tester) async {
      await ouvrir(tester, FauxPhotosRepository(), FausseGalerie(), onSuivant: (_) async => false);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      final bouton = find.widgetWithText(FilledButton, 'Continuer');
      expect(tester.widget<FilledButton>(bouton).onPressed, isNotNull, reason: 'bouton de nouveau actif');
    });
  });
}
