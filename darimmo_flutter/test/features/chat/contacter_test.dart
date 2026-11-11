// Tests de la 7.1 « Contacter l'annonceur depuis une annonce » (membre C).
// Application complète (routeur + faux repositories), aucun accès réseau.
import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';
import 'package:darimmo/features/chat/presentation/screens/discussion_page.dart';
import 'package:darimmo/features/chat/presentation/widgets/bouton_contacter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/navigation_test.dart' show FaussesConversations, demarrer;

final bouton = find.widgetWithText(FilledButton, 'Contacter');

void main() {
  testWidgets('connecté : ouvre la discussion, puis reprend la même conversation', (tester) async {
    final conversations = FaussesConversations();
    await demarrer(tester, initiale: '/annonces/a1', conversations: conversations);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(DiscussionPage), findsOneWidget);
    expect(conversations.ouvertes, {'a1': 'c-1'});

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(DiscussionPage), findsOneWidget);
    expect(conversations.ouvertures, 2);
    expect(conversations.ouvertes, {'a1': 'c-1'}, reason: 'pas de deuxième conversation pour la même annonce');
  });

  testWidgets('visiteur : compte obligatoire, propose de se connecter sans appeler le serveur', (tester) async {
    final conversations = FaussesConversations();
    await demarrer(tester, connecte: false, initiale: '/annonces/a1', conversations: conversations);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text('Connectez-vous pour contacter l’annonceur'), findsOneWidget);
    expect(conversations.ouvertures, 0);

    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Se connecter')));
    await tester.pumpAndSettle();
    expect(find.text('Content de vous revoir'), findsOneWidget);
  });

  testWidgets('visiteur : « Créer un compte » ouvre l’inscription', (tester) async {
    await demarrer(tester, connecte: false, initiale: '/annonces/a1');
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Créer un compte')));
    await tester.pumpAndSettle();
    expect(find.text('Gratuit · moins d’une minute'), findsOneWidget);
  });

  testWidgets('se contacter soi-même : refus du serveur affiché clairement', (tester) async {
    final conversations = FaussesConversations()
      ..erreurContact = ContactException.depuisServeur('Vous ne pouvez pas vous contacter vous-même');
    await demarrer(tester, initiale: '/annonces/a1', conversations: conversations);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text('C’est votre annonce : vous ne pouvez pas vous contacter vous-même.'), findsOneWidget);
    expect(find.byType(DiscussionPage), findsNothing);
  });

  testWidgets('session expirée pendant l’envoi : propose de se reconnecter', (tester) async {
    final conversations = FaussesConversations()..erreurContact = ContactException.depuisServeur('Connexion obligatoire');
    await demarrer(tester, initiale: '/annonces/a1', conversations: conversations);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.text('Connectez-vous pour contacter l’annonceur'), findsOneWidget);
  });

  testWidgets('ma propre annonce : bouton désactivé « C’est votre annonce »', (tester) async {
    final conversations = FaussesConversations();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BoutonContacter(
          idAnnonce: 'a1',
          repository: conversations,
          estConnecte: true,
          estMonAnnonce: true,
          onOuvrirConversation: (_, _) {},
          onSeConnecter: (_) {},
          onCreerCompte: (_) {},
        ),
      ),
    ));
    expect(find.text('Contacter'), findsNothing);
    final b = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'C’est votre annonce'));
    expect(b.onPressed, isNull);
  });

  test('messages du serveur traduits (fonction SQL ouvrir_conversation)', () {
    expect(ContactException.depuisServeur('Connexion obligatoire').connexionRequise, isTrue);
    expect(ContactException.depuisServeur('Annonce introuvable ou non publiée').message,
        'Cette annonce n’est plus disponible.');
    expect(ContactException.depuisServeur('Vous ne pouvez pas vous contacter vous-même').connexionRequise, isFalse);
    expect(ContactException.depuisServeur('autre chose').message, 'Erreur du serveur. Réessayez.');
  });
}
