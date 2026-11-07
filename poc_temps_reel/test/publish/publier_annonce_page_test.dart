// Tests de l'écran [6.1] avec un faux repository (sans Supabase).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc_temps_reel/core/darimmo_theme.dart';
import 'package:poc_temps_reel/features/publish/data/annonce_repository.dart';
import 'package:poc_temps_reel/features/publish/models/annonce.dart';
import 'package:poc_temps_reel/features/publish/ui/publier_annonce_page.dart';

class FauxRepository implements AnnonceRepository {
  FauxRepository({this.erreur});
  final String? erreur;
  final recues = <NouvelleAnnonce>[];
  final modifiees = <(EditionAnnonce, NouvelleAnnonce)>[];

  @override
  Future<Annonce> publier(NouvelleAnnonce a) async {
    recues.add(a);
    if (erreur != null) throw PublicationException(erreur!);
    return _annonce('id-test', a, StatutAnnonce.enAttente);
  }

  @override
  Future<Annonce> modifier(EditionAnnonce e, NouvelleAnnonce a) async {
    modifiees.add((e, a));
    if (erreur != null) throw PublicationException(erreur!);
    // Comme le trigger : publiée ou rejetée modifiée -> en attente
    return _annonce(e.id, a, StatutAnnonce.enAttente);
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

Future<void> ouvrir(WidgetTester tester, AnnonceRepository repo) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: darimmoTheme(), home: PublierAnnoncePage(repository: repo)));
}

Future<void> remplir(WidgetTester tester) async {
  await tester.tap(find.text('Appartement'));
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : Appartement S+3 haut standing'), 'Appartement S+3 haut standing');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : 385 000'), '385 000');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : 120'), '145');
  await tester.enterText(find.widgetWithText(TextFormField, 'Ex : La Marsa, Tunis'), 'Ennasr 2, Ariana');
  await tester.pump();
}

Future<void> envoyer(WidgetTester tester) async {
  await tester.tap(find.text('Envoyer pour validation'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulaire vide : erreurs affichées, rien n’est envoyé', (tester) async {
    final repo = FauxRepository();
    await ouvrir(tester, repo);
    await envoyer(tester);

    expect(find.text('Choisissez un type de bien'), findsOneWidget);
    expect(find.text('Le titre est obligatoire'), findsOneWidget);
    expect(find.text('Le prix est obligatoire'), findsOneWidget);
    expect(find.text('La surface est obligatoire'), findsOneWidget);
    expect(find.text('La ville est obligatoire'), findsOneWidget);
    expect(repo.recues, isEmpty);
  });

  testWidgets('formulaire rempli : envoi puis écran « en attente »', (tester) async {
    final repo = FauxRepository();
    await ouvrir(tester, repo);
    await tester.tap(find.text('Louer'));
    await remplir(tester);
    await envoyer(tester);

    expect(repo.recues, hasLength(1));
    final a = repo.recues.single;
    expect(a.typeBien, TypeBien.appartement);
    expect(a.typeOffre, TypeOffre.location);
    expect(a.prix, 385000);
    expect(a.surface, 145);
    expect(a.nbPieces, 3);

    expect(find.text('Annonce envoyée !'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('385 000 DT/mois'), findsOneWidget);
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
    await envoyer(tester);

    expect(find.text('Annonce envoyée !'), findsNothing);
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

    Future<Annonce?> ouvrirEdition(WidgetTester tester, FauxRepository repo, StatutAnnonce statut) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Annonce? retour;
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              retour = await Navigator.push<Annonce>(context, MaterialPageRoute(
                builder: (_) => PublierAnnoncePage(
                    repository: repo, edition: EditionAnnonce(id: 'id-villa', statut: statut, valeurs: villa)),
              ));
            },
            child: const Text('ouvrir'),
          ),
        ),
      ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return retour;
    }

    testWidgets('formulaire pré-rempli, enregistrement puis retour à la liste', (tester) async {
      final repo = FauxRepository();
      await ouvrirEdition(tester, repo, StatutAnnonce.publiee);

      expect(find.text('Modifier l’annonce'), findsOneWidget);
      expect(find.textContaining('elle sera retirée'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Villa s+4'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '450 000'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Hammamet'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // compteur de pièces

      await tester.enterText(find.widgetWithText(TextFormField, '450 000'), '420 000');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(repo.recues, isEmpty, reason: 'pas de nouvelle annonce');
      final (edition, valeurs) = repo.modifiees.single;
      expect(edition.id, 'id-villa');
      expect(valeurs.prix, 420000);
      expect(valeurs.typeBien, TypeBien.villa);
      expect(valeurs.description, 'Avec piscine');
      expect(find.text('Modifier l’annonce'), findsNothing, reason: 'écran fermé');
      expect(find.text('Annonce envoyée !'), findsNothing);
    });

    testWidgets('annonce rejetée : bouton « Renvoyer pour validation »', (tester) async {
      await ouvrirEdition(tester, FauxRepository(), StatutAnnonce.rejetee);
      expect(find.text('Renvoyer pour validation'), findsOneWidget);
    });
  });
}
