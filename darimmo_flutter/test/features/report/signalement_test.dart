// Tests de la 3.4 « Signaler une annonce » (maquettes B4, B5).
// Tâche du membre B, réalisée par le membre C. Aucun accès réseau.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darimmo/features/report/data/repositories/signalement_repository.dart';
import 'package:darimmo/features/report/presentation/widgets/feuille_signalement.dart';
import 'package:darimmo/features/report/presentation/widgets/lien_signaler.dart';

import '../../app/navigation_test.dart' show demarrer;
import '../detail/faux_detail.dart';
import 'faux_signalements.dart';

final lien = find.text('Signaler cette annonce');
final envoyer = find.text('Envoyer le signalement');

/// Ouvre le détail de l'annonce a1 et fait défiler jusqu'au lien.
Future<void> ouvrirDetail(WidgetTester tester, {bool connecte = true, FauxSignalements? repo, FauxDetail? detail}) async {
  await demarrer(tester, connecte: connecte, initiale: '/annonces/a1', signalements: repo, detail: detail);
  await tester.scrollUntilVisible(find.byType(LienSignaler), 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  test('motif enregistré : « Catégorie — précision »', () {
    expect(composerMotif('Bien déjà vendu ou loué', '  '), 'Bien déjà vendu ou loué');
    expect(composerMotif('Autre motif', ' Doublon '), 'Autre motif — Doublon');
    expect(composerMotif('Autre motif', 'x' * 600), hasLength(500));
  });

  testWidgets('choix d’un motif obligatoire, envoi, confirmation affichée', (tester) async {
    final repo = FauxSignalements();
    await ouvrirDetail(tester, repo: repo);

    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(find.text('Annonce frauduleuse ou arnaque'), findsOneWidget);

    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(find.text('Choisissez un motif.'), findsOneWidget);
    expect(repo.envoyes, isEmpty);

    await tester.tap(find.text('Annonce frauduleuse ou arnaque'));
    await tester.enterText(find.byType(TextField), 'Acompte demandé avant la visite.');
    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(repo.envoyes, {'a1': 'Annonce frauduleuse ou arnaque — Acompte demandé avant la visite.'});
    expect(find.textContaining('Merci ! Votre signalement a été envoyé'), findsOneWidget);
    expect(find.text('Vous avez signalé cette annonce'), findsOneWidget);
    expect(lien, findsNothing);
  });

  testWidgets('« Autre motif » exige une précision', (tester) async {
    final repo = FauxSignalements();
    await ouvrirDetail(tester, repo: repo);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre motif'));
    await tester.pumpAndSettle();
    expect(find.text('Précisez le motif'), findsOneWidget);
    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(find.text('Précisez le motif (5 caractères au moins).'), findsOneWidget);
    expect(repo.envoyes, isEmpty);
  });

  testWidgets('déjà signalée : plus de lien (un seul signalement par annonce)', (tester) async {
    await ouvrirDetail(tester, repo: FauxSignalements(dejaSignalees: {'a1'}));
    expect(find.text('Vous avez signalé cette annonce'), findsOneWidget);
    expect(lien, findsNothing);
  });

  testWidgets('erreur réseau : message dans la feuille, on peut réessayer', (tester) async {
    final repo = FauxSignalements()
      ..erreur = const SignalementException('Connexion impossible. Vérifiez Internet et réessayez.');
    await ouvrirDetail(tester, repo: repo);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photos inappropriées'));
    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(find.textContaining('Connexion impossible'), findsOneWidget);
    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(repo.envoyes, {'a1': 'Photos inappropriées'});
  });

  testWidgets('visiteur : invité à se connecter', (tester) async {
    final repo = FauxSignalements();
    await ouvrirDetail(tester, connecte: false, repo: repo);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(find.text('Connectez-vous pour signaler cette annonce'), findsOneWidget);
    expect(repo.envoyes, isEmpty);
  });

  testWidgets('sa propre annonce : pas de lien Signaler', (tester) async {
    await demarrer(
      tester,
      initiale: '/annonces/a1',
      detail: FauxDetail(annonces: {'a1': annonceDetailTest('a1', idAnnonceur: 'u1')}),
    );
    await tester.scrollUntilVisible(find.byType(LienSignaler), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(lien, findsNothing);
  });
}
