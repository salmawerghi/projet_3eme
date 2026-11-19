// Tests de la 9.1 « Rôle administrateur » et de la 9.2 « Valider ou rejeter
// une annonce » (maquette A7). Tâches du membre A, réalisées par le membre C.
// Aucun accès réseau.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darimmo/features/admin/data/models/annonce_a_moderer.dart';
import 'package:darimmo/features/admin/data/repositories/moderation_repository.dart';
import 'package:darimmo/features/admin/presentation/screens/admin_page.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/moderation_view_model.dart';
import 'package:darimmo/features/auth/presentation/viewmodels/etat_compte.dart';

import '../../app/navigation_test.dart' show demarrer;
import '../auth/faux_auth.dart';
import 'faux_admin.dart';

/// L'écran seul ; renvoie les annonces ouvertes.
Future<List<String>> ouvrir(WidgetTester tester, FausseModeration repo) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ouvertes = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: AdminPage(
      moderation: repo,
      maintenant: () => dateModeration,
      onOuvrirAnnonce: (_, id) => ouvertes.add(id),
    ),
  ));
  await tester.pumpAndSettle();
  return ouvertes;
}

/// Le bouton qui contient [texte] (FilledButton.icon, OutlinedButton…).
Finder bouton(String texte) =>
    find.ancestor(of: find.text(texte), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

void main() {
  group('Modèle', () {
    test('depuisLigne lit la réponse de la base (requête testée avec admin@)', () {
      final a = AnnonceAModerer.depuisLigne({
        'id': '296ced0c-d286-4980-b76f-2e970b98462b',
        'titre': 'Appartement s+2',
        'type_bien': 'appartement',
        'type_offre': 'vente',
        'prix': 345000.00,
        'ville': 'La Marsa,Tunis',
        'date_maj': '2026-11-07T20:45:09.872435+00:00',
        'annonceur': {'nom': 'Sami Vendeur'},
        'photos': [
          {'url': 'https://exemple.test/b.jpg', 'ordre': 1},
          {'url': 'https://exemple.test/a.jpg', 'ordre': 0},
        ],
      });
      expect(a.nomAnnonceur, 'Sami Vendeur');
      expect(a.initiales, 'SV');
      expect(a.photoCouverture, 'https://exemple.test/a.jpg');
      expect(a.nbPhotos, 2);
      expect(a.resume, 'La Marsa,Tunis · 345 000 DT');
    });

    test('motif de rejet obligatoire, 10 caractères au moins', () {
      expect(validerMotif(''), contains('obligatoire'));
      expect(validerMotif('  flou  '), contains('trop court'));
      expect(validerMotif('Photos floues, refaites-les.'), isNull);
    });
  });

  group('EtatCompte (9.1)', () {
    test('rôle lu à la connexion, oublié à la déconnexion', () async {
      final auth = FauxAuth();
      final compte = FauxCompte(admin: true);
      final etat = EtatCompte(repository: compte, auth: auth);
      expect(etat.estAdmin, isFalse);
      expect(compte.lectures, 0);

      await auth.connecter(email: 'admin@darimmo.test', motDePasse: 'Test1234!');
      await Future<void>.delayed(Duration.zero);
      expect(etat.estAdmin, isTrue);

      await auth.deconnecter();
      expect(etat.estAdmin, isFalse);
    });
  });

  group('ModerationViewModel (9.2)', () {
    test('valider : l’annonce quitte la liste', () async {
      final repo = FausseModeration();
      final vm = ModerationViewModel(repo);
      await vm.charger();
      expect(vm.annonces.map((a) => a.id), ['m1', 'm2']);
      expect(await vm.valider('m1'), isNull);
      expect(vm.annonces.map((a) => a.id), ['m2']);
      expect(repo.validees, ['m1']);
    });

    test('rejeter sans motif valable : rien n’est envoyé', () async {
      final repo = FausseModeration();
      final vm = ModerationViewModel(repo);
      await vm.charger();
      expect(await vm.rejeter('m1', '  '), contains('obligatoire'));
      expect(repo.rejets, isEmpty);
      expect(await vm.rejeter('m1', 'Prix incohérent avec le bien.'), isNull);
      expect(repo.rejets, {'m1': 'Prix incohérent avec le bien.'});
    });

    test('déjà traitée par un autre admin : retirée + message', () async {
      final repo = FausseModeration();
      final vm = ModerationViewModel(repo);
      await vm.charger();
      repo.erreur = const ModerationException(ModerationException.messageDejaTraitee, dejaTraitee: true);
      expect(await vm.valider('m1'), ModerationException.messageDejaTraitee);
      expect(vm.annonces.map((a) => a.id), ['m2']);
    });

    test('erreur réseau : l’annonce reste dans la liste', () async {
      final repo = FausseModeration();
      final vm = ModerationViewModel(repo);
      await vm.charger();
      repo.erreur = const ModerationException('Connexion impossible. Vérifiez Internet et réessayez.');
      expect(await vm.valider('m1'), contains('Connexion impossible'));
      expect(vm.annonces, hasLength(2));
    });

    test('double appui sur Valider : une seule demande', () async {
      final repo = FausseModeration()..attente = Completer<void>();
      final vm = ModerationViewModel(repo);
      await vm.charger();
      final premier = vm.valider('m1');
      expect(vm.enCours('m1'), isTrue);
      expect(await vm.valider('m1'), isNull);
      repo.attente!.complete();
      await premier;
      expect(repo.validees, ['m1']);
    });
  });

  group('Écran Modération (maquette A7)', () {
    testWidgets('liste des annonces en attente, la plus ancienne d’abord', (tester) async {
      await ouvrir(tester, FausseModeration());
      expect(find.text('En attente · 2'), findsOneWidget);
      expect(find.text('Les plus anciennes d’abord'), findsOneWidget);
      expect(find.textContaining('Sami Vendeur · hier'), findsOneWidget);
      expect(find.textContaining('Ines Gharbi · il y a 3 h'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Appartement s+2')).dy,
        lessThan(tester.getTopLeft(find.text('Villa Hammamet')).dy),
      );
    });

    testWidgets('Valider : annonce publiée, message, compteur mis à jour', (tester) async {
      final repo = FausseModeration();
      await ouvrir(tester, repo);
      await tester.tap(bouton('Valider').first);
      await tester.pumpAndSettle();
      expect(repo.validees, ['m1']);
      expect(find.text('« Appartement s+2 » est publiée. L’annonceur est prévenu.'), findsOneWidget);
      expect(find.text('En attente · 1'), findsOneWidget);
      expect(find.text('Appartement s+2'), findsNothing);
    });

    testWidgets('Rejeter : motif obligatoire, motif rapide, Confirmer le rejet', (tester) async {
      final repo = FausseModeration();
      await ouvrir(tester, repo);
      await tester.tap(bouton('Rejeter').first);
      await tester.pumpAndSettle();
      expect(find.text('Motif du rejet (visible par l’annonceur)'), findsOneWidget);

      await tester.tap(bouton('Confirmer le rejet'));
      await tester.pumpAndSettle();
      expect(find.text('Le motif est obligatoire : il est envoyé à l’annonceur.'), findsOneWidget);
      expect(repo.rejets, isEmpty);

      await tester.tap(find.text('Prix incohérent'));
      await tester.pumpAndSettle();
      await tester.tap(bouton('Confirmer le rejet'));
      await tester.pumpAndSettle();
      expect(repo.rejets, {'m1': 'Prix incohérent avec le bien décrit.'});
      expect(find.text('« Appartement s+2 » est rejetée. L’annonceur est prévenu.'), findsOneWidget);
      expect(find.text('En attente · 1'), findsOneWidget);
    });

    testWidgets('Rejeter puis Annuler : rien n’est envoyé', (tester) async {
      final repo = FausseModeration();
      await ouvrir(tester, repo);
      await tester.tap(bouton('Rejeter').first);
      await tester.pumpAndSettle();
      await tester.tap(bouton('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Motif du rejet (visible par l’annonceur)'), findsNothing);
      expect(repo.rejets, isEmpty);
    });

    testWidgets('toucher l’annonce ouvre son détail', (tester) async {
      final ouvertes = await ouvrir(tester, FausseModeration());
      await tester.tap(find.text('Villa Hammamet'));
      expect(ouvertes, ['m2']);
    });

    testWidgets('aucune annonce en attente : message', (tester) async {
      await ouvrir(tester, FausseModeration([]));
      expect(find.text('Aucune annonce en attente. Tout est à jour !'), findsOneWidget);
      expect(find.text('En attente · 0'), findsOneWidget);
    });

    testWidgets('erreur réseau : Réessayer', (tester) async {
      final repo = FausseModeration()..erreur = const ModerationException('Connexion impossible. Vérifiez Internet et réessayez.');
      await ouvrir(tester, repo);
      expect(find.textContaining('Connexion impossible'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('En attente · 2'), findsOneWidget);
    });
  });

  group('Accès (9.1)', () {
    testWidgets('utilisateur : pas de lien admin, /admin renvoie à l’accueil', (tester) async {
      await demarrer(tester, initiale: '/profil');
      expect(find.text('Espace administration'), findsNothing);

      await demarrer(tester, initiale: '/admin');
      expect(find.byType(AdminPage), findsNothing);
      expect(find.text('Annonces récentes'), findsOneWidget);
    });

    testWidgets('admin : lien dans le profil -> Modération', (tester) async {
      await demarrer(tester, initiale: '/profil', compte: FauxCompte(admin: true));
      await tester.ensureVisible(find.text('Espace administration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Espace administration'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.text('En attente · 2'), findsOneWidget);
    });
  });
}
