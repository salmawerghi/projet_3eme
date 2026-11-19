// Tests de la 9.4 « Traiter les signalements » (maquette A8).
// Tâche du membre A, réalisée par le membre C. Aucun accès réseau.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darimmo/features/admin/data/models/annonce_signalee.dart';
import 'package:darimmo/features/admin/presentation/screens/admin_page.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

import 'faux_admin.dart';

/// Ouvre l'écran Modération sur l'onglet Signalements ; renvoie les annonces ouvertes.
Future<List<String>> ouvrirSignalements(WidgetTester tester, FausseModeration repo) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ouvertes = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: AdminPage(moderation: repo, maintenant: () => dateModeration, onOuvrirAnnonce: (_, id) => ouvertes.add(id)),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Signalements'));
  await tester.pumpAndSettle();
  return ouvertes;
}

void main() {
  test('regrouper : une carte par annonce, signalements dans l’ordre (réponse réelle de la base)', () {
    Map<String, dynamic> ligne(int id, String motif, String date, String auteur) => {
          'id': id,
          'motif': motif,
          'date': date,
          'auteur': {'nom': auteur},
          'annonce': {
            'id': 'c39306af-770d-4404-ac05-cab9d3777920',
            'titre': 'Studio meublé étudiant',
            'statut': 'publiee',
            'type_bien': 'appartement',
            'type_offre': 'location',
            'prix': 450.00,
            'ville': 'Sfax',
            'photos': [
              {'url': 'https://exemple.test/a.jpg', 'ordre': 0},
            ],
            'annonceur': {'nom': 'Sami Vendeur'},
          },
        };
    final annonces = AnnonceSignalee.regrouper([
      ligne(2, 'Photos ne correspondant pas au bien', '2026-11-04T22:32:09.721856+00:00', 'Lina Acheteuse'),
      ligne(5, 'Annonce frauduleuse ou arnaque — Acompte demandé.', '2026-11-19T08:00:00+00:00', 'Karim J.'),
      {'id': 9, 'motif': 'Doublon', 'date': '2026-11-19T09:00:00+00:00', 'auteur': null, 'annonce': null},
    ]);
    expect(annonces, hasLength(1));
    final a = annonces.single;
    expect(a.statut, StatutAnnonce.publiee);
    expect(a.ids, [2, 5]);
    expect(a.photoCouverture, 'https://exemple.test/a.jpg');
    expect(a.signalements[0].precision, isNull);
    expect(a.signalements[0].categorie, 'Photos ne correspondant pas au bien');
    expect(a.signalements[1].categorie, 'Annonce frauduleuse ou arnaque');
    expect(a.signalements[1].precision, 'Acompte demandé.');
  });

  testWidgets('liste : annonces signalées, nombre, motifs et auteurs', (tester) async {
    await ouvrirSignalements(tester, FausseModeration());
    expect(find.text('Signalements · 3'), findsOneWidget);
    expect(find.text('2 SIGNALEMENTS'), findsOneWidget);
    expect(find.text('1 SIGNALEMENT'), findsOneWidget);
    expect(find.text('« Le vendeur demande un acompte avant toute visite. »'), findsOneWidget);
    expect(find.text('Annonce frauduleuse ou arnaque · Karim Jaziri · il y a 2 h'), findsOneWidget);
    expect(find.text('Photos ne correspondant pas au bien'), findsOneWidget);
  });

  testWidgets('Masquer : confirmation, annonce masquée, signalements traités', (tester) async {
    final repo = FausseModeration();
    await ouvrirSignalements(tester, repo);

    await tester.tap(find.text('Masquer').first);
    await tester.pumpAndSettle();
    expect(find.text('Masquer cette annonce ?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Masquer')));
    await tester.pumpAndSettle();

    expect(repo.masquees, ['s1']);
    expect(repo.traites, [2, 5]);
    expect(find.text('« Studio meublé étudiant » est masquée. L’annonceur est prévenu.'), findsOneWidget);
    expect(find.text('Signalements · 1'), findsOneWidget);
  });

  testWidgets('Masquer puis Annuler : rien n’est fait', (tester) async {
    final repo = FausseModeration();
    await ouvrirSignalements(tester, repo);
    await tester.tap(find.text('Masquer').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repo.masquees, isEmpty);
    expect(find.text('Signalements · 3'), findsOneWidget);
  });

  testWidgets('Classer sans suite : l’annonce reste en ligne', (tester) async {
    final repo = FausseModeration();
    await ouvrirSignalements(tester, repo);
    await tester.tap(find.text('Classer sans suite').last);
    await tester.pumpAndSettle();
    expect(repo.classes, [7]);
    expect(repo.masquees, isEmpty);
    expect(find.text('Signalement classé sans suite : « Local commercial Gabès » reste en ligne.'), findsOneWidget);
    expect(find.text('Local commercial Gabès'), findsNothing);
  });

  testWidgets('toucher l’annonce ouvre son détail', (tester) async {
    final ouvertes = await ouvrirSignalements(tester, FausseModeration());
    await tester.tap(find.text('Local commercial Gabès'));
    expect(ouvertes, ['s2']);
  });

  testWidgets('aucun signalement : message', (tester) async {
    await ouvrirSignalements(tester, FausseModeration(null, []));
    expect(find.text('Aucun signalement à traiter.'), findsOneWidget);
  });
}
