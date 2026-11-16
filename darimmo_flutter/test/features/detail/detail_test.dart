// Tests de la 3.3 « Consulter le détail d'une annonce » (maquette B4).
// Tâche du membre B, réalisée par le membre C. Aucun accès réseau.
import 'package:darimmo/features/detail/data/models/annonce_detail.dart';
import 'package:darimmo/features/detail/data/repositories/detail_repository.dart';
import 'package:darimmo/features/detail/presentation/screens/detail_annonce_page.dart';
import 'package:darimmo/features/detail/presentation/viewmodels/detail_view_model.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/navigation_test.dart' show demarrer;
import 'faux_detail.dart';

/// Réponse réelle de la base (requête testée avec la clé publique), photos mélangées exprès.
Map<String, dynamic> ligneReelle() => {
      'id': '7a9b4b38-e758-4a60-a771-38c2016fbd2f',
      'titre': 'Appartement S+2 lumineux',
      'description': 'Proche du centre, 2e étage avec ascenseur.',
      'type_bien': 'appartement',
      'type_offre': 'location',
      'prix': 950.0,
      'surface': 95.0,
      'nb_pieces': 3,
      'adresse': 'Rue de Marseille',
      'ville': 'Tunis',
      'latitude': 36.8008,
      'longitude': 10.1815,
      'statut': 'publiee',
      'id_annonceur': '5e935bcc-23cd-4b55-977b-f26811bef9cb',
      'date_creation': '2026-11-04T22:24:19.164916+00:00',
      'photos': [
        {'url': 'https://exemple.test/b.jpg', 'ordre': 1},
        {'url': 'https://exemple.test/a.jpg', 'ordre': 0},
      ],
      'annonceur': {
        'nom': 'Sami Vendeur',
        'photo_url': null,
        'date_inscription': '2026-11-04T22:23:21.540651+00:00',
      },
    };

/// La page (ListView) et non la galerie (PageView), qui défile aussi.
final pageDefilante = find.byType(Scrollable).first;

/// L'écran seul, avec un faux bouton Contacter qui affiche l'id reçu.
Future<void> ouvrir(WidgetTester tester, FauxDetail repo, {String id = 'a1'}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: DetailAnnoncePage(
      idAnnonce: id,
      repository: repo,
      afficherTuilesCarte: false,
      onQuitter: (_) {},
      boutonContacter: (idAnnonceur) => Text('contacter:$idAnnonceur'),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Modèle', () {
    test('depuisLigne lit la réponse de la base, photos dans l’ordre', () {
      final a = AnnonceDetail.depuisLigne(ligneReelle());
      expect(a.titre, 'Appartement S+2 lumineux');
      expect(a.typeBien, TypeBien.appartement);
      expect(a.typeOffre, TypeOffre.location);
      expect(a.statut, StatutAnnonce.publiee);
      expect(a.photos, ['https://exemple.test/a.jpg', 'https://exemple.test/b.jpg']);
      expect(a.annonceur.nom, 'Sami Vendeur');
      expect(a.annonceur.initiales, 'SV');
      expect(a.idAnnonceur, '5e935bcc-23cd-4b55-977b-f26811bef9cb');
      expect(a.lieu, 'Rue de Marseille, Tunis');
      expect(a.libelleTaille, 'S+2');
      expect(a.aUnePosition, isTrue);
      expect(a.prixAuM2, isNull, reason: 'pas de prix au m² pour une location');
    });

    test('sans photo, sans position, sans profil lisible : valeurs de repli', () {
      final l = ligneReelle()
        ..['photos'] = []
        ..['latitude'] = null
        ..['longitude'] = null
        ..['adresse'] = ' '
        ..['annonceur'] = null;
      final a = AnnonceDetail.depuisLigne(l);
      expect(a.photos, isEmpty);
      expect(a.aUnePosition, isFalse);
      expect(a.lieu, 'Tunis');
      expect(a.annonceur.nom, 'Annonceur DarImmo');
    });

    test('prix au m² pour une vente ; terrain sans pièces ; local en pièces', () {
      expect(annonceDetailTest('v', offre: TypeOffre.vente, prix: 950000, surface: 320).prixAuM2, 950000 / 320);
      expect(annonceDetailTest('t', type: TypeBien.terrain, pieces: 0).libelleTaille, isNull);
      expect(annonceDetailTest('l', type: TypeBien.local, pieces: 2).libelleTaille, '2 pièces');
    });

    test('sous-titre de l’annonceur', () {
      final a = Annonceur(nom: 'Lina', dateInscription: DateTime(2026, 3, 10));
      expect(sousTitreAnnonceur(a, 8), 'Membre depuis mars 2026 · 8 annonces');
      expect(sousTitreAnnonceur(a, 1), 'Membre depuis mars 2026 · 1 annonce');
      expect(sousTitreAnnonceur(const Annonceur(nom: 'Lina'), null), '');
    });
  });

  group('DetailViewModel', () {
    test('succès', () async {
      final vm = DetailViewModel(repository: FauxDetail(), idAnnonce: 'a1');
      await vm.charger();
      expect(vm.annonce?.id, 'a1');
      expect(vm.erreur, isNull);
      expect(vm.chargement, isFalse);
    });

    test('annonce introuvable : pas de « Réessayer »', () async {
      final vm = DetailViewModel(repository: FauxDetail()..inconnuesIntrouvables = true, idAnnonce: 'x');
      await vm.charger();
      expect(vm.annonce, isNull);
      expect(vm.introuvable, isTrue);
      expect(vm.erreur, DetailException.messageIntrouvable);
    });

    test('erreur réseau puis nouvel essai réussi', () async {
      final repo = FauxDetail()..erreurs.add(const DetailException('Connexion impossible.'));
      final vm = DetailViewModel(repository: repo, idAnnonce: 'a1');
      await vm.charger();
      expect(vm.erreur, 'Connexion impossible.');
      expect(vm.introuvable, isFalse);
      await vm.charger();
      expect(vm.erreur, isNull);
      expect(vm.annonce, isNotNull);
    });
  });

  group('Écran (maquette B4)', () {
    testWidgets('3.3 : photos, prix, caractéristiques, description, ville, annonceur, Contacter', (tester) async {
      await ouvrir(tester, FauxDetail());
      expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
      expect(find.text('APPARTEMENT · LOCATION'), findsOneWidget);
      expect(find.text('VÉRIFIÉE'), findsOneWidget);
      expect(find.text('Rue de Marseille, Tunis'), findsOneWidget);
      expect(find.text('950 DT/mois'), findsOneWidget, reason: 'prix (Text.rich)');
      expect(find.text('95 m²'), findsOneWidget);
      expect(find.text('S+2'), findsOneWidget);
      expect(find.text('Proche du centre, 2e étage avec ascenseur.'), findsOneWidget);
      expect(find.text('Sami Vendeur'), findsOneWidget);
      expect(find.text('Membre depuis mars 2026 · 8 annonces'), findsOneWidget);
      expect(find.text('contacter:vendeur-1'), findsOneWidget, reason: 'id de l’annonceur transmis au bouton 7.1');
      expect(find.text('Lire la suite'), findsNothing, reason: 'description courte');
    });

    testWidgets('galerie défilante : 1/3 puis 2/3 en glissant', (tester) async {
      await ouvrir(tester, FauxDetail());
      expect(find.text('1/3 PHOTOS'), findsOneWidget);
      await tester.drag(find.byKey(const Key('galerie')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/3 PHOTOS'), findsOneWidget);
    });

    testWidgets('toucher une photo l’ouvre en plein écran', (tester) async {
      await ouvrir(tester, FauxDetail());
      await tester.tap(find.byKey(const Key('galerie')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('emplacement : mini-carte si la position est connue', (tester) async {
      await ouvrir(tester, FauxDetail());
      await tester.scrollUntilVisible(find.byKey(const Key('mini-carte')), 300, scrollable: pageDefilante);
      expect(find.text('Emplacement'), findsOneWidget);
    });

    testWidgets('emplacement : rien si l’annonce n’a pas de position', (tester) async {
      await ouvrir(tester, FauxDetail(annonces: {'p': annonceDetailTest('p', latitude: null, longitude: null)}), id: 'p');
      await tester.scrollUntilVisible(find.text('Sami Vendeur'), 300, scrollable: pageDefilante);
      expect(find.text('Emplacement'), findsNothing);
      expect(find.byKey(const Key('mini-carte')), findsNothing);
    });

    testWidgets('vente : prix au m² ; pas de photo : image de remplacement', (tester) async {
      await ouvrir(
        tester,
        FauxDetail(annonces: {
          'v': annonceDetailTest('v', type: TypeBien.villa, offre: TypeOffre.vente, prix: 950000, surface: 320, photos: []),
        }),
        id: 'v',
      );
      expect(find.text('≈ 2 969 DT/m²'), findsOneWidget);
      expect(find.text('VILLA · VENTE'), findsOneWidget);
      expect(find.textContaining('PHOTO'), findsNothing);
    });

    testWidgets('annonce non publiée (vue par son annonceur) : bandeau de statut, pas « VÉRIFIÉE »', (tester) async {
      await ouvrir(tester, FauxDetail(annonces: {'e': annonceDetailTest('e', statut: StatutAnnonce.enAttente)}), id: 'e');
      expect(find.text('En attente'), findsOneWidget);
      expect(find.textContaining('En attente de validation'), findsOneWidget);
      expect(find.text('VÉRIFIÉE'), findsNothing);
    });

    testWidgets('description longue : « Lire la suite » puis « Réduire »', (tester) async {
      final longue = List.filled(40, 'Très bel appartement lumineux.').join(' ');
      await ouvrir(tester, FauxDetail(annonces: {'d': annonceDetailTest('d', description: longue)}), id: 'd');
      await tester.scrollUntilVisible(find.text('Lire la suite'), 300, scrollable: pageDefilante);
      await tester.ensureVisible(find.text('Lire la suite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lire la suite'));
      await tester.pumpAndSettle();
      expect(find.text('Réduire'), findsOneWidget);
    });

    testWidgets('annonce introuvable : message et Retour, pas de Réessayer', (tester) async {
      await ouvrir(tester, FauxDetail()..inconnuesIntrouvables = true, id: 'x');
      expect(find.text(DetailException.messageIntrouvable), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('erreur réseau puis Réessayer', (tester) async {
      final repo = FauxDetail()..erreurs.add(const DetailException('Connexion impossible. Vérifiez Internet et réessayez.'));
      await ouvrir(tester, repo);
      expect(find.text('Connexion impossible. Vérifiez Internet et réessayez.'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
      expect(repo.appels, 2);
    });
  });

  group('Dans l’application (routeur + bouton 7.1)', () {
    testWidgets('ma propre annonce : « C’est votre annonce »', (tester) async {
      // FauxAuth connecté = utilisateur 'u1'
      final detail = FauxDetail(annonces: {'m': annonceDetailTest('m', idAnnonceur: 'u1')});
      await demarrer(tester, initiale: '/annonces/m', detail: detail);
      expect(find.text('C’est votre annonce'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Contacter'), findsNothing);
    });

    testWidgets('annonce d’un autre : bouton Contacter actif', (tester) async {
      await demarrer(tester, initiale: '/annonces/a1');
      expect(find.widgetWithText(FilledButton, 'Contacter'), findsOneWidget);
    });

    testWidgets('ouverte seule (notification) : la flèche retour mène à l’accueil', (tester) async {
      await demarrer(tester, initiale: '/annonces/a1');
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Trouvez votre chez-vous'), findsOneWidget);
    });
  });
}
