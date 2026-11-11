// Tests de la 2.1 « S'inscrire par email » (maquette A3), dans l'application
// complète (routeur + faux repositories, aucun accès réseau).
import 'dart:async';

import 'package:darimmo/app.dart';
import 'package:darimmo/core/router/app_router.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/navigation_test.dart' show fauxServices;
import 'faux_auth.dart';

Future<FauxAuth> ouvrirInscription(WidgetTester tester, {bool confirmationEmail = true}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final auth = FauxAuth(confirmationEmail: confirmationEmail);
  final routeur = creerRouteur(fauxServices(auth));
  addTearDown(routeur.dispose);
  await tester.pumpWidget(DarImmoApp(routeur: routeur));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Créer un compte'));
  await tester.pumpAndSettle();
  expect(find.text('Gratuit · moins d’une minute'), findsOneWidget);
  return auth;
}

Finder champ(String libelle) => find.widgetWithText(TextFormField, libelle);

Future<void> remplir(
  WidgetTester tester, {
  String nom = 'Yasmine Trabelsi',
  String email = 'yasmine.t@gmail.com',
  String motDePasse = 'Soleil2026!',
  String telephone = '',
  bool cgu = true,
}) async {
  await tester.enterText(champ('Nom complet'), nom);
  await tester.enterText(champ('Adresse email'), email);
  await tester.enterText(champ('Mot de passe'), motDePasse);
  await tester.enterText(champ('Téléphone (facultatif)'), telephone);
  if (cgu) {
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
  }
  await tester.pump();
}

Future<void> valider(WidgetTester tester) async {
  final bouton = find.widgetWithText(FilledButton, 'Créer mon compte');
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulaire vide : chaque champ obligatoire est signalé, rien n’est envoyé', (tester) async {
    final auth = await ouvrirInscription(tester);
    await valider(tester);
    expect(find.text('Le nom est obligatoire'), findsOneWidget);
    expect(find.text('L’adresse email est obligatoire'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire'), findsOneWidget);
    expect(find.text('Acceptez les conditions pour créer votre compte'), findsOneWidget);
    expect(auth.derniereInscription, isNull);
  });

  testWidgets('email invalide et mot de passe de 7 caractères refusés', (tester) async {
    final auth = await ouvrirInscription(tester);
    await remplir(tester, email: 'yasmine@gmail', motDePasse: 'Abc123!');
    await valider(tester);
    expect(find.text('Adresse email invalide (ex : nom@gmail.com)'), findsOneWidget);
    expect(find.text('Au moins 8 caractères'), findsOneWidget);
    expect(auth.derniereInscription, isNull);
  });

  testWidgets('conditions non cochées : rien n’est envoyé', (tester) async {
    final auth = await ouvrirInscription(tester);
    await remplir(tester, cgu: false);
    await valider(tester);
    expect(find.text('Acceptez les conditions pour créer votre compte'), findsOneWidget);
    expect(auth.derniereInscription, isNull);
  });

  testWidgets('email déjà utilisé : erreur claire sous le champ, qui disparaît si on le corrige', (tester) async {
    await ouvrirInscription(tester);
    await remplir(tester, email: 'acheteur@darimmo.test');
    await valider(tester);
    expect(find.text(messageEmailDejaUtilise), findsOneWidget);
    expect(find.text('Vérifiez votre boîte mail'), findsNothing);

    await tester.enterText(champ('Adresse email'), 'autre@gmail.com');
    await tester.pump();
    expect(find.text(messageEmailDejaUtilise), findsNothing);
  });

  testWidgets('compte créé : écran « Vérifiez votre boîte mail », puis connexion avec l’email pré-rempli',
      (tester) async {
    final auth = await ouvrirInscription(tester);
    await remplir(tester, telephone: '22 345 678');
    await valider(tester);

    expect(auth.derniereInscription, {
      'nom': 'Yasmine Trabelsi',
      'email': 'yasmine.t@gmail.com',
      'motDePasse': 'Soleil2026!',
      'telephone': '+21622345678',
    });
    expect(find.text('Vérifiez votre boîte mail'), findsOneWidget);
    expect(find.textContaining('yasmine.t@gmail.com', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Je n’ai rien reçu : renvoyer l’email'));
    await tester.pumpAndSettle();
    expect(auth.renvois, 1);
    expect(find.text('Email renvoyé. Pensez à regarder dans les spams.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    final email = tester.widget<TextField>(find.widgetWithText(TextField, 'Email'));
    final mdp = tester.widget<TextField>(find.widgetWithText(TextField, 'Mot de passe'));
    expect(email.controller!.text, 'yasmine.t@gmail.com');
    expect(mdp.controller!.text, isEmpty);
  });

  testWidgets('sans confirmation d’email (session ouverte) : accueil directement', (tester) async {
    await ouvrirInscription(tester, confirmationEmail: false);
    await remplir(tester);
    await valider(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Trouvez votre chez-vous'), findsOneWidget);
  });

  testWidgets('erreur réseau : bandeau, et le bouton est désactivé pendant l’envoi', (tester) async {
    final auth = await ouvrirInscription(tester);
    auth.attente = Completer<void>();
    auth.erreurInscription = const InscriptionException('Inscription impossible. Vérifiez Internet et réessayez.');
    await remplir(tester);
    final bouton = find.widgetWithText(FilledButton, 'Créer mon compte');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pump();
    final enCours = find.widgetWithText(FilledButton, 'Création du compte…');
    expect(tester.widget<FilledButton>(enCours).onPressed, isNull);

    auth.attente!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Inscription impossible. Vérifiez Internet et réessayez.'), findsOneWidget);
    expect(find.text('Vérifiez votre boîte mail'), findsNothing);
  });

  testWidgets('indicateur de force du mot de passe (maquette A3)', (tester) async {
    await ouvrirInscription(tester);
    expect(find.text('Au moins 8 caractères'), findsOneWidget);
    await tester.enterText(champ('Mot de passe'), 'abc');
    await tester.pump();
    expect(find.text('Trop court'), findsOneWidget);
    expect(find.text('3 caractères · 8 minimum'), findsOneWidget);
    await tester.enterText(champ('Mot de passe'), 'Soleil2026!');
    await tester.pump();
    expect(find.text('Mot de passe solide'), findsOneWidget);
  });

  testWidgets('« Déjà inscrit ? Se connecter » revient à la connexion', (tester) async {
    await ouvrirInscription(tester);
    final lien = find.widgetWithText(TextButton, 'Se connecter');
    await tester.ensureVisible(lien);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Gratuit · moins d’une minute'), findsNothing);
  });
}
