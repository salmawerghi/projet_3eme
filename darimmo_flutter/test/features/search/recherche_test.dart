// Tests de la 3.1 (liste des annonces) et de la 3.2 (filtres) — membre B.
// Aucun accès réseau : FausseRecherche remplace Supabase.
import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/data/models/filtre_recherche.dart';
import 'package:darimmo/features/search/data/repositories/recherche_repository.dart';
import 'package:darimmo/features/search/presentation/screens/accueil_page.dart';
import 'package:darimmo/features/search/presentation/viewmodels/accueil_view_model.dart';
import 'package:darimmo/features/search/presentation/widgets/carte_annonce_recherche.dart';
import 'package:darimmo/features/search/presentation/widgets/feuille_filtres.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fausse_recherche.dart';

/// Laisse passer les requêtes du faux repository et le délai du compteur de la feuille.
Future<void> attendre(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  group('Modèle', () {
    test('depuisLigne lit la réponse de la base et trie les photos par ordre', () {
      final a = AnnonceRecherche.depuisLigne({
        'id': 'x1',
        'titre': 'Appartement S+2 lumineux',
        'type_bien': 'appartement',
        'type_offre': 'location',
        'prix': 950,
        'surface': 85.5,
        'nb_pieces': 3,
        'ville': 'Tunis',
        'date_creation': '2026-11-05T10:00:00+00:00',
        'photos': [
          {'url': 'b.jpg', 'ordre': 1},
          {'url': 'a.jpg', 'ordre': 0},
        ],
      });
      expect(a.typeOffre, TypeOffre.location);
      expect(a.typeBien, TypeBien.appartement);
      expect(a.prix, 950);
      expect(a.surface, 85.5);
      expect(a.photos, ['a.jpg', 'b.jpg']);
      expect(a.photoCouverture, 'a.jpg');
    });

    test('S+n : nb_pieces compte TOUTES les pièces (S+2 = 3 pièces)', () {
      expect(annonceTest(1, pieces: 3).libelleTaille, 'S+2');
      expect(annonceTest(1, pieces: 1).libelleTaille, 'S+0 (studio)');
      expect(annonceTest(1, type: TypeBien.local, pieces: 3).libelleTaille, '3 pièces');
      expect(annonceTest(1, type: TypeBien.terrain, pieces: 0).libelleTaille, isNull);
    });

    test('filtre : S+n minimum -> nb_pieces >= n + 1, copie et égalité', () {
      expect(const FiltreRecherche(sPlusMin: 2).nbPiecesMin, 3);
      expect(FiltreRecherche.vide.nbPiecesMin, isNull);
      const f = FiltreRecherche(typeOffre: TypeOffre.location, ville: 'Tunis');
      expect(f.copie(ville: () => null), const FiltreRecherche(typeOffre: TypeOffre.location));
      expect(f.copie(ville: () => '   ').ville, isNull, reason: 'texte vide = pas de filtre');
      expect(f.copie(texte: () => 'villa').nbFiltresFeuille, 2, reason: 'la barre de recherche ne compte pas');
      expect(FiltreRecherche.vide.copie(texte: () => '').estVide, isTrue);
    });

    test('recherche : % et _ cherchés tels quels, syntaxe PostgREST neutralisée', () {
      expect(motifContient('Tunis'), '%Tunis%');
      expect(motifContient('100%_x'), r'%100\%\_x%');
      expect(texteRechercheSur('  La Marsa, (Tunis)* '), 'La Marsa Tunis');
      expect(texteRechercheSur(' ,() '), isNull);
    });

    test('échelle du curseur de prix : DT/mois pour la location', () {
      expect(echellePrix(TypeOffre.location), (max: 10000.0, pas: 50));
      expect(echellePrix(TypeOffre.vente).max, 3000000);
      expect(echellePrix(null).max, 3000000);
    });

    test('ancienneté et prix affichés sur la carte', () {
      expect(formaterAnciennete(dateRef.subtract(const Duration(hours: 2)), dateRef), 'il y a 2 h');
      expect(formaterAnciennete(dateRef.subtract(const Duration(minutes: 5)), dateRef), 'il y a 5 min');
      expect(formaterAnciennete(dateRef.subtract(const Duration(days: 1, hours: 2)), dateRef), 'hier');
      expect(formaterAnciennete(DateTime(2026, 10, 1), dateRef), '01/10/2026');
      expect(formaterPrixAnnonce(annonceTest(1, offre: TypeOffre.location, prix: 950)), '950 DT/mois');
      expect(formaterPrixAnnonce(annonceTest(1, prix: 385000)), '385 000 DT');
    });
  });

  group('AccueilViewModel', () {
    test('chargement progressif : 25 annonces = pages de 10, 10 puis 5', () async {
      final repo = FausseRecherche([for (var i = 0; i < 25; i++) annonceTest(i)]);
      final vm = AccueilViewModel(repo);
      await vm.demarrer();
      expect(vm.annonces.length, 10);
      expect(vm.aEncore, isTrue);
      await vm.chargerSuite();
      await vm.chargerSuite();
      expect(vm.annonces.length, 25);
      expect(vm.aEncore, isFalse);
      expect(vm.annonces.map((a) => a.id).toSet().length, 25, reason: 'aucun doublon');
      await vm.chargerSuite();
      expect(repo.demandes.map((d) => d.$2), [0, 1, 2], reason: 'plus rien à charger');
    });

    test('changer de filtre pendant un chargement : la réponse de l’ancien filtre est ignorée', () async {
      final repo = FausseRecherche([
        annonceTest(1, titre: 'Villa à vendre', type: TypeBien.villa),
        annonceTest(2, titre: 'Studio à louer', offre: TypeOffre.location, prix: 600),
      ])
        ..bloquer = true;
      final vm = AccueilViewModel(repo);
      final premier = vm.demarrer();
      final second = vm.appliquer(const FiltreRecherche(typeOffre: TypeOffre.location));
      expect(repo.nbEnAttente, 2);

      repo.liberer(); // réponse du filtre vide, arrivée en retard
      await premier;
      expect(vm.annonces, isEmpty);
      expect(vm.chargement, isTrue, reason: 'le nouveau filtre est encore en cours');

      repo.liberer();
      await second;
      expect(vm.annonces.map((a) => a.titre), ['Studio à louer']);
      expect(vm.chargement, isFalse);
    });

    test('erreur sur la première page puis Réessayer', () async {
      final repo = FausseRecherche([annonceTest(1)])..echecs.add(0);
      final vm = AccueilViewModel(repo);
      await vm.demarrer();
      expect(vm.erreur, contains('Connexion impossible'));
      await vm.recharger();
      expect(vm.erreur, isNull);
      expect(vm.annonces.length, 1);
    });

    test('erreur sur la page suivante : la liste reste, Réessayer reprend', () async {
      final repo = FausseRecherche([for (var i = 0; i < 15; i++) annonceTest(i)])..echecs.add(1);
      final vm = AccueilViewModel(repo);
      await vm.demarrer();
      await vm.chargerSuite();
      expect(vm.annonces.length, 10);
      expect(vm.erreurSuite, isNotNull);
      await vm.chargerSuite();
      expect(repo.demandes.length, 2, reason: 'pas de nouvel essai automatique en boucle');
      await vm.reessayerSuite();
      expect(vm.erreurSuite, isNull);
      expect(vm.annonces.length, 15);
    });

    test('puces : toucher une puce active la désactive ; Terrain efface les pièces', () async {
      final vm = AccueilViewModel(FausseRecherche());
      await vm.demarrer();
      await vm.basculerOffre(TypeOffre.location);
      expect(vm.filtre.typeOffre, TypeOffre.location);
      await vm.basculerOffre(TypeOffre.location);
      expect(vm.filtre.typeOffre, isNull);
      await vm.appliquer(const FiltreRecherche(sPlusMin: 2));
      await vm.basculerType(TypeBien.terrain);
      expect(vm.filtre, const FiltreRecherche(typeBien: TypeBien.terrain));
    });
  });

  group('Écran d’accueil (maquettes B1-B2)', () {
    late FausseRecherche repo;
    late List<String> ouvertes;

    final annonces = [
      annonceTest(1, titre: 'Appartement S+2 lumineux', offre: TypeOffre.location, prix: 950, surface: 85, pieces: 3),
      annonceTest(2, titre: 'Villa avec piscine', type: TypeBien.villa, prix: 950000, surface: 320, pieces: 6, ville: 'Hammamet'),
      annonceTest(3, titre: 'Terrain constructible', type: TypeBien.terrain, prix: 120000, surface: 600, pieces: 0, ville: 'Ariana'),
      annonceTest(4, titre: 'Studio centre Sousse', offre: TypeOffre.location, prix: 450, surface: 35, pieces: 1, ville: 'Sousse'),
    ];

    Future<void> ouvrir(WidgetTester tester, [List<AnnonceRecherche>? liste]) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repo = FausseRecherche(liste ?? annonces);
      ouvertes = [];
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: AccueilPage(
          repository: repo,
          maintenant: () => dateRef,
          onOuvrir: (_, a) => ouvertes.add(a.id),
        ),
      ));
      await attendre(tester);
    }

    Future<void> ouvrirFiltres(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Filtres'));
      await attendre(tester);
    }

    Finder bouton(String texte) => find.widgetWithText(FilledButton, texte);

    testWidgets('3.1 : cartes avec photo, titre, prix, ville, surface ; toucher ouvre le détail', (tester) async {
      await ouvrir(tester);
      expect(find.text('Annonces récentes'), findsOneWidget);
      expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
      expect(find.text('950 DT/mois'), findsOneWidget);
      expect(find.text('85 m²'), findsOneWidget);
      expect(find.text('S+2'), findsOneWidget, reason: '3 pièces = S+2, pas S+3');
      expect(find.text('APPARTEMENT · LOCATION'), findsOneWidget);
      expect(find.text('il y a 1 h'), findsOneWidget);

      await tester.tap(find.text('Appartement S+2 lumineux'));
      expect(ouvertes, ['a1']);
    });

    testWidgets('3.1 : indicateur pendant le chargement', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repo = FausseRecherche(annonces)..bloquer = true;
      await tester.pumpWidget(MaterialApp(
        home: AccueilPage(repository: repo, onOuvrir: (_, _) {}),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.liberer();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Villa avec piscine'), findsOneWidget);
    });

    testWidgets('3.1 : message si aucune annonce publiée', (tester) async {
      await ouvrir(tester, const []);
      expect(find.text('Aucune annonce pour l’instant'), findsOneWidget);
    });

    testWidgets('3.1 : erreur de connexion puis Réessayer', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repo = FausseRecherche(annonces)..echecs.add(0);
      await tester.pumpWidget(MaterialApp(home: AccueilPage(repository: repo, onOuvrir: (_, _) {})));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger les annonces'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Villa avec piscine'), findsOneWidget);
    });

    testWidgets('3.1 : chargement progressif en faisant défiler', (tester) async {
      await ouvrir(tester, [for (var i = 0; i < 23; i++) annonceTest(i, titre: 'Bien n°$i')]);
      expect(repo.demandes.map((d) => d.$2), [0]);
      await tester.scrollUntilVisible(find.text('Bien n°22'), 500, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(repo.demandes.map((d) => d.$2), [0, 1, 2]);
      expect(find.text('Chargement des annonces suivantes…'), findsNothing, reason: 'tout est chargé');
    });

    testWidgets('3.2 : filtrer location + appartement + S+1 min + ville, compteur à jour', (tester) async {
      await ouvrir(tester);
      await ouvrirFiltres(tester);
      expect(bouton('Afficher 4 annonces'), findsOneWidget);
      expect(find.text('Tous les prix'), findsOneWidget);

      await tester.tap(find.text('Louer'));
      await attendre(tester);
      expect(find.text('Prix (DT/mois)'), findsOneWidget, reason: 'échelle des loyers');
      expect(bouton('Afficher 2 annonces'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Appartement'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'S+1'));
      await attendre(tester);
      expect(bouton('Afficher 1 annonce'), findsOneWidget, reason: 'le studio (S+0) est exclu');

      await tester.enterText(find.widgetWithText(TextField, 'Toutes les villes'), 'tun');
      await attendre(tester);
      expect(find.text('Tunis'), findsWidgets, reason: 'suggestion de ville');
      await tester.tap(bouton('Afficher 1 annonce'));
      await attendre(tester);

      expect(find.text('Résultats'), findsOneWidget);
      expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
      expect(find.text('Studio centre Sousse'), findsNothing);
      expect(find.text('Villa avec piscine'), findsNothing);
      expect(repo.demandes.last.$1,
          const FiltreRecherche(typeOffre: TypeOffre.location, typeBien: TypeBien.appartement, sPlusMin: 1, ville: 'tun'));
      expect(find.text('4'), findsOneWidget, reason: 'pastille : 4 filtres actifs');
    });

    testWidgets('3.2 : « Aucun bien trouvé » puis Réinitialiser les filtres', (tester) async {
      await ouvrir(tester);
      await ouvrirFiltres(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Terrain'));
      await tester.tap(find.text('Louer'));
      await attendre(tester);
      expect(find.text('Nombre de pièces minimum'), findsNothing, reason: 'un terrain n’a pas de pièces');
      expect(bouton('Aucun bien trouvé'), findsOneWidget);
      await tester.tap(bouton('Aucun bien trouvé'));
      await attendre(tester);

      expect(find.text('Aucun bien trouvé'), findsOneWidget);
      await tester.tap(find.text('Réinitialiser les filtres'));
      await attendre(tester);
      expect(find.text('Annonces récentes'), findsOneWidget);
      expect(find.text('Villa avec piscine'), findsOneWidget);
    });

    testWidgets('3.2 : prix min / max saisis ; min > max refusé ; Réinitialiser dans la feuille', (tester) async {
      await ouvrir(tester);
      await ouvrirFiltres(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Min'), '500 000');
      await tester.enterText(find.widgetWithText(TextField, 'Max'), '100000');
      await attendre(tester);
      expect(find.text('Le prix minimum dépasse le prix maximum'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Max'), '1000000');
      await attendre(tester);
      expect(bouton('Afficher 1 annonce'), findsOneWidget, reason: 'seule la villa à 950 000 DT');

      await tester.tap(find.text('Réinitialiser'));
      await attendre(tester);
      expect(bouton('Afficher 4 annonces'), findsOneWidget);
      expect(find.text('Tous les prix'), findsOneWidget);
    });

    testWidgets('3.2 : fermer la feuille sans valider ne change rien', (tester) async {
      await ouvrir(tester);
      await ouvrirFiltres(tester);
      await tester.tap(find.text('Louer'));
      await attendre(tester);
      await tester.tapAt(const Offset(200, 20)); // toucher au-dessus de la feuille
      await attendre(tester);
      expect(find.text('Annonces récentes'), findsOneWidget);
      expect(find.text('Villa avec piscine'), findsOneWidget);
    });

    testWidgets('barre de recherche et puces rapides', (tester) async {
      await ouvrir(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Ville, quartier, titre…'), 'Sousse');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await attendre(tester);
      expect(find.text('Studio centre Sousse'), findsOneWidget);
      expect(find.text('Villa avec piscine'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tout'));
      await attendre(tester);
      final barre = tester.widget<TextField>(find.widgetWithText(TextField, 'Ville, quartier, titre…'));
      expect(barre.controller!.text, isEmpty, reason: '« Tout » vide aussi la barre de recherche');
      expect(find.text('Villa avec piscine'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Location'));
      await attendre(tester);
      expect(find.text('Villa avec piscine'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Location'));
      await attendre(tester);
      expect(find.text('Villa avec piscine'), findsOneWidget, reason: 'deuxième toucher = puce désactivée');
    });
  });
}
