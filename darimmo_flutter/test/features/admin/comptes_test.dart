// Tests de la 9.3 « Bloquer ou débloquer un compte ».
// Tâche du membre A, réalisée par le membre C. Aucun accès réseau.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:darimmo/features/admin/data/models/compte_admin.dart';
import 'package:darimmo/features/admin/presentation/screens/admin_page.dart';
import 'package:darimmo/features/admin/presentation/viewmodels/comptes_view_model.dart';

import '../../app/navigation_test.dart' show demarrer;
import 'faux_admin.dart';

/// Ouvre l'écran Modération sur l'onglet Comptes.
Future<FausseModeration> ouvrirComptes(WidgetTester tester, [FausseModeration? repo]) async {
  final r = repo ?? FausseModeration();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: AdminPage(moderation: r, maintenant: () => dateModeration, onOuvrirAnnonce: (_, _) {}),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Comptes'));
  await tester.pumpAndSettle();
  return r;
}

Future<void> chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(const Key('recherche-comptes')), texte);
  await tester.pump(const Duration(milliseconds: 450)); // délai de la recherche
  await tester.pumpAndSettle();
}

void main() {
  group('Modèle', () {
    test('libellé et initiales : le nom, sinon l’email', () {
      final lignes = [
        {'id': '1', 'nom': 'Lina Acheteuse', 'email': 'acheteur@darimmo.test', 'photo_url': null, 'role': 'utilisateur', 'bloque': false},
        {'id': '2', 'nom': '', 'email': 'ali.test@gmail.com', 'photo_url': null, 'role': 'admin', 'bloque': true},
      ];
      final a = CompteAdmin.depuisLigne(lignes[0]);
      final b = CompteAdmin.depuisLigne(lignes[1]);
      expect([a.libelle, a.initiales, a.estAdmin, a.bloque], ['Lina Acheteuse', 'LA', false, false]);
      expect([b.libelle, b.initiales, b.estAdmin, b.bloque], ['ali.test@gmail.com', 'AT', true, true]);
    });
  });

  group('ComptesViewModel', () {
    test('sans recherche : comptes bloqués ; la recherche part après le délai', () async {
      final repo = FausseModeration();
      final vm = ComptesViewModel(repo, delai: Duration.zero);
      await vm.charger();
      expect(vm.comptes.map((c) => c.id), ['sami']);

      vm.chercher('l');
      vm.chercher('lin');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.recherches, ['', 'lin'], reason: 'une seule recherche pour plusieurs lettres');
      expect(vm.comptes.map((c) => c.id), ['lina']);
    });

    test('bloquer puis débloquer ; un admin ne peut pas être bloqué', () async {
      final repo = FausseModeration();
      final vm = ComptesViewModel(repo, delai: Duration.zero);
      vm.recherche = 'darimmo';
      await vm.charger();
      final lina = vm.comptes.firstWhere((c) => c.id == 'lina');
      expect(await vm.basculerBlocage(lina), isNull);
      expect(vm.comptes.firstWhere((c) => c.id == 'lina').bloque, isTrue);
      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'lina').bloque, isTrue);

      expect(await vm.basculerBlocage(vm.comptes.firstWhere((c) => c.id == 'lina')), isNull);
      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'lina').bloque, isFalse);

      final admin = vm.comptes.firstWhere((c) => c.id == 'adm');
      expect(await vm.basculerBlocage(admin), contains('administrateur'));
      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'adm').bloque, isFalse);
    });
  });

  group('Onglet Comptes', () {
    testWidgets('au départ : comptes bloqués, avec Débloquer', (tester) async {
      await ouvrirComptes(tester);
      expect(find.text('Comptes bloqués'), findsOneWidget);
      expect(find.text('Sami Vendeur'), findsOneWidget);
      expect(find.text('BLOQUÉ'), findsOneWidget);
      expect(find.text('Débloquer'), findsOneWidget);
    });

    testWidgets('rechercher puis bloquer (avec confirmation)', (tester) async {
      final repo = await ouvrirComptes(tester);
      await chercher(tester, 'lina');
      expect(find.text('Résultats'), findsOneWidget);
      expect(find.text('Lina Acheteuse'), findsOneWidget);

      await tester.tap(find.byKey(const Key('blocage-lina')));
      await tester.pumpAndSettle();
      expect(find.text('Bloquer Lina Acheteuse ?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Bloquer')));
      await tester.pumpAndSettle();

      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'lina').bloque, isTrue);
      expect(find.text('Lina Acheteuse est bloqué.'), findsOneWidget);
      expect(find.text('BLOQUÉ'), findsOneWidget);
    });

    testWidgets('bloquer puis Annuler : rien ne change', (tester) async {
      final repo = await ouvrirComptes(tester);
      await chercher(tester, 'lina');
      await tester.tap(find.byKey(const Key('blocage-lina')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'lina').bloque, isFalse);
    });

    testWidgets('débloquer : immédiat', (tester) async {
      final repo = await ouvrirComptes(tester);
      await tester.tap(find.byKey(const Key('blocage-sami')));
      await tester.pumpAndSettle();
      expect(repo.comptesEnBase.firstWhere((c) => c.id == 'sami').bloque, isFalse);
      expect(find.text('Sami Vendeur est débloqué.'), findsOneWidget);
    });

    testWidgets('un admin n’a pas de bouton Bloquer ; recherche sans résultat', (tester) async {
      await ouvrirComptes(tester);
      await chercher(tester, 'admin');
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.byKey(const Key('blocage-adm')), findsNothing);

      await chercher(tester, 'zzz');
      expect(find.text('Aucun compte ne correspond à « zzz ».'), findsOneWidget);
    });
  });

  testWidgets('compte bloqué : déconnecté à l’ouverture, avec un message', (tester) async {
    final auth = await demarrer(tester, compte: FauxCompte(bloque: true));
    await tester.pumpAndSettle();
    expect(auth.connecte, isFalse);
    expect(find.text('Votre compte a été suspendu par un administrateur. Contactez le support DarImmo.'), findsOneWidget);
  });
}
