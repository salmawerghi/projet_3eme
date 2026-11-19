// Tests de la 5.1 « Ajouter ou retirer une annonce des favoris » et de la
// 5.2 « Consulter mes favoris » (maquettes B1, B4, B6).
// Tâches du membre B, réalisées par le membre C. Aucun accès réseau.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darimmo/features/favorites/presentation/viewmodels/etat_favoris.dart';
import 'package:darimmo/features/favorites/presentation/viewmodels/favoris_view_model.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';

import '../../app/navigation_test.dart' show demarrer;
import '../auth/faux_auth.dart';
import '../search/fausse_recherche.dart' show annonceTest;
import 'faux_favoris.dart';

/// 3 annonces : 2 ventes, 1 location.
final catalogue = [
  annonceTest(1, titre: 'Appartement S+2 lumineux'),
  annonceTest(2, titre: 'Villa jardin', type: TypeBien.villa, prix: 950000),
  annonceTest(3, titre: 'Studio meublé', offre: TypeOffre.location, prix: 450),
];

Finder coeur(String id) => find.byKey(Key('favori-$id'));

void main() {
  group('EtatFavoris (5.1)', () {
    test('visiteur : aucun favori, rien n’est demandé au serveur', () async {
      final repo = FauxFavoris(favoris: ['a1']);
      final etat = EtatFavoris(repository: repo, auth: FauxAuth());
      await Future<void>.delayed(Duration.zero);
      expect(etat.estFavori('a1'), isFalse);
      expect(repo.lecturesIds, 0);
      expect(await etat.basculer('a1'), 'Connectez-vous pour gérer vos favoris.');
    });

    test('connexion : favoris relus (état conservé) ; déconnexion : vidés', () async {
      final auth = FauxAuth();
      final etat = EtatFavoris(repository: FauxFavoris(favoris: ['a1']), auth: auth);
      await auth.connecter(email: 'vendeur@darimmo.test', motDePasse: 'Test1234!');
      await Future<void>.delayed(Duration.zero);
      expect(etat.estFavori('a1'), isTrue);
      expect(etat.charge, isTrue);

      await auth.deconnecter();
      expect(etat.estFavori('a1'), isFalse);
    });

    test('ajout puis retrait : le cœur change tout de suite, la base suit', () async {
      final repo = FauxFavoris()..attente = Completer<void>();
      final etat = EtatFavoris(repository: repo, auth: FauxAuth(connecte: true));
      await Future<void>.delayed(Duration.zero);

      final ajout = etat.basculer('a2');
      expect(etat.estFavori('a2'), isTrue, reason: 'optimiste : avant la réponse du serveur');
      expect(await etat.basculer('a2'), isNull, reason: 'double appui ignoré');
      repo.attente!.complete();
      expect(await ajout, isNull);
      expect(repo.favoris, ['a2']);

      repo.attente = null;
      await etat.basculer('a2');
      expect(etat.estFavori('a2'), isFalse);
      expect(repo.favoris, isEmpty);
    });

    test('échec du serveur : retour en arrière + message', () async {
      final repo = FauxFavoris();
      final etat = EtatFavoris(repository: repo, auth: FauxAuth(connecte: true));
      await Future<void>.delayed(Duration.zero);
      repo.echec = true;
      expect(await etat.basculer('a1'), contains('Connexion impossible'));
      expect(etat.estFavori('a1'), isFalse);
    });
  });

  group('FavorisViewModel (5.2)', () {
    test('retrait ailleurs : disparaît sans relecture ; ajout ailleurs : relecture', () async {
      final repo = FauxFavoris(catalogue: catalogue, favoris: ['a1', 'a2']);
      final etat = EtatFavoris(repository: repo, auth: FauxAuth(connecte: true));
      await Future<void>.delayed(Duration.zero);
      final vm = FavorisViewModel(repository: repo, etat: etat);
      await vm.charger();
      expect(vm.favoris.map((a) => a.id), ['a2', 'a1'], reason: 'le plus récent d’abord');

      await etat.basculer('a1');
      expect(vm.favoris.map((a) => a.id), ['a2']);
      expect(repo.lectures, 1);

      await etat.basculer('a3');
      await Future<void>.delayed(Duration.zero);
      expect(repo.lectures, 2);
      expect(vm.favoris.map((a) => a.id), ['a3', 'a2']);
    });

    test('favori d’une annonce plus visible (vendue) : pas de relecture sans fin', () async {
      final repo = FauxFavoris(catalogue: catalogue, favoris: ['a1']);
      final etat = EtatFavoris(repository: repo, auth: FauxAuth(connecte: true));
      await Future<void>.delayed(Duration.zero);
      final vm = FavorisViewModel(repository: repo, etat: etat);
      await vm.charger();

      await etat.basculer('vendue'); // absente du catalogue
      await Future<void>.delayed(Duration.zero);
      await etat.basculer('a2');
      await Future<void>.delayed(Duration.zero);
      expect(repo.lectures, 3, reason: 'une relecture par nouvel ajout, pas plus');
      expect(vm.favoris.map((a) => a.id), ['a2', 'a1']);
    });

    test('filtre Vente / Location et compteurs des puces', () async {
      final repo = FauxFavoris(catalogue: catalogue, favoris: ['a1', 'a2', 'a3']);
      final etat = EtatFavoris(repository: repo, auth: FauxAuth(connecte: true));
      await Future<void>.delayed(Duration.zero);
      final vm = FavorisViewModel(repository: repo, etat: etat);
      await vm.charger();
      expect([vm.nombre(null), vm.nombre(TypeOffre.vente), vm.nombre(TypeOffre.location)], [3, 2, 1]);
      vm.choisirFiltre(TypeOffre.location);
      expect(vm.affiches.map((a) => a.id), ['a3']);
    });
  });

  group('Cœur sur la liste et le détail (5.1)', () {
    testWidgets('accueil : cœur vide -> plein, retrouvé dans l’onglet Favoris', (tester) async {
      final repo = FauxFavoris();
      await demarrer(tester, favoris: repo);

      expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
      await tester.tap(coeur('a1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
      expect(repo.favoris, ['a1']);

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('1 bien sauvegardé'), findsOneWidget);
      expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
    });

    testWidgets('détail : cœur à côté de Contacter, déjà plein si favori', (tester) async {
      await demarrer(tester, initiale: '/annonces/a1', favoris: FauxFavoris(favoris: ['a1']));
      expect(coeur('a1'), findsOneWidget);
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
      expect(find.text('Contacter'), findsOneWidget);

      await tester.tap(coeur('a1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    });

    testWidgets('visiteur : invité à se connecter, rien n’est enregistré', (tester) async {
      final repo = FauxFavoris();
      await demarrer(tester, connecte: false, initiale: '/accueil', favoris: repo);

      await tester.tap(coeur('a1'));
      await tester.pumpAndSettle();
      expect(find.text('Connectez-vous pour enregistrer vos favoris'), findsOneWidget);
      expect(repo.favoris, isEmpty);

      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Se connecter')));
      await tester.pumpAndSettle();
      expect(find.text('Content de vous revoir'), findsOneWidget);
    });

    testWidgets('échec du serveur : cœur remis, message affiché', (tester) async {
      final repo = FauxFavoris();
      await demarrer(tester, favoris: repo);
      repo.echec = true;
      await tester.tap(coeur('a1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
      expect(find.textContaining('Connexion impossible'), findsOneWidget);
    });
  });

  group('Onglet Mes favoris (5.2)', () {
    Future<FauxFavoris> ouvrirOnglet(WidgetTester tester, {List<String> favoris = const ['a1', 'a2', 'a3']}) async {
      final repo = FauxFavoris(catalogue: catalogue, favoris: favoris);
      await demarrer(tester, initiale: '/favoris', favoris: repo);
      return repo;
    }

    testWidgets('liste, puces et filtre', (tester) async {
      await ouvrirOnglet(tester);
      expect(find.text('3 biens sauvegardés'), findsOneWidget);
      expect(find.text('Tous · 3'), findsOneWidget);
      expect(find.text('Vente · 2'), findsOneWidget);
      expect(find.text('Location · 1'), findsOneWidget);
      expect(find.text('Studio meublé'), findsOneWidget);

      await tester.tap(find.text('Vente · 2'));
      await tester.pumpAndSettle();
      expect(find.text('Studio meublé'), findsNothing);
      expect(find.text('Villa jardin'), findsOneWidget);
    });

    testWidgets('retrait depuis la liste, puis Annuler', (tester) async {
      final repo = await ouvrirOnglet(tester);
      await tester.tap(find.byKey(const Key('retirer-a2')));
      await tester.pumpAndSettle();
      expect(find.text('Villa jardin'), findsNothing);
      expect(find.text('2 biens sauvegardés'), findsOneWidget);
      expect(repo.favoris, ['a1', 'a3']);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Villa jardin'), findsOneWidget);
      expect(repo.favoris, containsAll(['a1', 'a2', 'a3']));
    });

    testWidgets('toucher une ligne ouvre le détail', (tester) async {
      await ouvrirOnglet(tester, favoris: ['a1']);
      await tester.tap(find.text('Appartement S+2 lumineux'));
      await tester.pumpAndSettle();
      expect(find.text('Contacter'), findsOneWidget, reason: 'écran 3.3');
    });

    testWidgets('aucun favori : message + Parcourir les annonces', (tester) async {
      await ouvrirOnglet(tester, favoris: []);
      expect(find.text('Aucun favori pour l’instant'), findsOneWidget);
      await tester.tap(find.text('Parcourir les annonces'));
      await tester.pumpAndSettle();
      expect(find.text('Annonces récentes'), findsOneWidget);
    });

    testWidgets('erreur réseau : Réessayer', (tester) async {
      final repo = FauxFavoris(catalogue: catalogue, favoris: ['a1']);
      // ids() réussit au démarrage, puis la liste échoue une fois
      await demarrer(tester, favoris: repo);
      repo.echec = true;
      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Favoris indisponibles'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('1 bien sauvegardé'), findsOneWidget);
    });
  });
}
