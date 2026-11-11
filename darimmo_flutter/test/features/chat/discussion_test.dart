// Tests de [7.2] Échanger en temps réel (faux repository, sans Supabase).
import 'dart:async';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/chat/data/models/infos_discussion.dart';
import 'package:darimmo/features/chat/data/models/message.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';
import 'package:darimmo/features/chat/presentation/screens/discussion_page.dart';
import 'package:darimmo/features/chat/presentation/viewmodels/discussion_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'faux_chat.dart';

/// Samedi 7 novembre 2026, 15 h.
final maintenant = DateTime(2026, 11, 7, 15);
DateTime horloge() => maintenant;

List<Message> historiqueExemple() => [
      msg(1, 'Bonjour, la villa est-elle toujours disponible ?', DateTime(2026, 11, 6, 10, 2), de: moiId),
      msg(2, 'Bonjour, oui elle est disponible.', DateTime(2026, 11, 6, 10, 5)),
      msg(3, 'La visite samedi à 10 h vous convient ?', DateTime(2026, 11, 7, 14, 32)),
    ];

InfosDiscussion infosExemple({String? idAnnonce = 'a1'}) => InfosDiscussion(
      conversation: ResumeConversation.depuisLigne({
        'id': 'c1',
        'id_annonce': idAnnonce,
        'titre_annonce': 'Villa avec piscine',
        'photo_annonce': null,
        'id_interlocuteur': autreId,
        'nom_interlocuteur': 'Karim Jaziri',
        'photo_interlocuteur': null,
        'dernier_message': 'La visite samedi à 10 h vous convient ?',
        'date_dernier_message': DateTime(2026, 11, 7, 14, 32).toUtc().toIso8601String(),
        'non_lus': 1,
      }),
      prix: 385000,
      ville: 'La Marsa',
    );

Future<DiscussionViewModel> vmDemarre(FauxChat repo) async {
  final vm = DiscussionViewModel(repo, 'c1', horloge: horloge);
  addTearDown(vm.dispose);
  await vm.demarrer();
  return vm;
}

void main() {
  group('DiscussionViewModel', () {
    test('historique chargé dans l’ordre, conversation marquée lue, Realtime écouté', () async {
      final repo = FauxChat(historique: historiqueExemple().reversed.toList());
      final vm = await vmDemarre(repo);
      expect(vm.messages.map((m) => m.id), [1, 2, 3]);
      expect(repo.ecoute, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(repo.marquesLus, 1);
    });

    test('séparateurs de jour : Hier puis Aujourd’hui', () async {
      final vm = await vmDemarre(FauxChat(historique: historiqueExemple()));
      final e = vm.elements();
      expect(e.whereType<SeparateurJour>().map((s) => s.texte), ['Hier', 'Aujourd’hui']);
      expect(e.first, isA<SeparateurJour>());
      expect((e[1] as BulleMessage).deMoi, isTrue);
      expect((e[2] as BulleMessage).deMoi, isFalse);
    });

    test('message reçu en temps réel : ajouté sans recharger et marqué lu', () async {
      final repo = FauxChat(historique: historiqueExemple());
      final vm = await vmDemarre(repo);
      await Future<void>.delayed(Duration.zero);
      final lusAvant = repo.marquesLus;

      repo.recevoir(msg(4, 'Vous êtes là ?', DateTime(2026, 11, 7, 14, 50)));
      await Future<void>.delayed(Duration.zero);
      expect(vm.messages.last.contenu, 'Vous êtes là ?');
      expect(repo.chargementsHistorique, 1, reason: 'pas de rechargement');
      expect(repo.marquesLus, lusAvant + 1);

      repo.recevoir(msg(4, 'Vous êtes là ?', DateTime(2026, 11, 7, 14, 50)));
      await Future<void>.delayed(Duration.zero);
      expect(vm.messages.where((m) => m.id == 4), hasLength(1), reason: 'pas de doublon');
    });

    test('envoi : affiché tout de suite « en cours », puis remplacé par la ligne enregistrée', () async {
      final repo = FauxChat(historique: historiqueExemple())..bloquerEnvoi = Completer<void>();
      final vm = await vmDemarre(repo);

      final envoi = vm.envoyer('  Oui, samedi me va très bien  ');
      await Future<void>.delayed(Duration.zero);
      expect(vm.messages.last.etat, EtatEnvoi.enCours);
      expect(vm.messages.last.contenu, 'Oui, samedi me va très bien', reason: 'espaces retirés');

      repo.bloquerEnvoi!.complete();
      await envoi;
      expect(vm.messages.last.etat, EtatEnvoi.envoye);
      expect(vm.messages.last.id, isNotNull);
      expect(vm.messages.where((m) => m.contenu == 'Oui, samedi me va très bien'), hasLength(1));
      expect(repo.envoyes, ['Oui, samedi me va très bien']);
    });

    test('envoi : Realtime livre mon message AVANT la réponse -> une seule bulle', () async {
      final repo = FauxChat(historique: historiqueExemple())..bloquerEnvoi = Completer<void>();
      final vm = await vmDemarre(repo);

      final envoi = vm.envoyer('Merci');
      await Future<void>.delayed(Duration.zero);
      repo.recevoir(msg(1000, 'Merci', DateTime(2026, 11, 7, 14, 40), de: moiId));
      await Future<void>.delayed(Duration.zero);
      expect(vm.messages.where((m) => m.contenu == 'Merci'), hasLength(1));

      repo.bloquerEnvoi!.complete();
      await envoi;
      expect(vm.messages.where((m) => m.contenu == 'Merci'), hasLength(1));
      expect(vm.messages.last.id, 1000);
    });

    test('message vide ou espaces : rien n’est envoyé', () async {
      final repo = FauxChat();
      final vm = await vmDemarre(repo);
      expect(await vm.envoyer('   '), isFalse);
      expect(vm.messages, isEmpty);
      expect(repo.envoyes, isEmpty);
    });

    test('échec d’envoi : « Non envoyé », puis Réessayer réussit', () async {
      final repo = FauxChat()..erreurEnvoi = 'Connexion impossible.';
      final vm = await vmDemarre(repo);
      await vm.envoyer('Bonjour');
      expect(vm.messages.single.etat, EtatEnvoi.echec);

      repo.erreurEnvoi = null;
      await vm.reessayer(vm.messages.single);
      expect(vm.messages.single.etat, EtatEnvoi.envoye);
      expect(repo.envoyes, ['Bonjour']);
    });

    test('échec d’envoi : Supprimer retire la bulle', () async {
      final repo = FauxChat()..erreurEnvoi = 'Connexion impossible.';
      final vm = await vmDemarre(repo);
      await vm.envoyer('Bonjour');
      vm.abandonner(vm.messages.single);
      expect(vm.messages, isEmpty);
    });

    test('reconnexion Realtime : l’historique est rechargé et les messages manqués ajoutés', () async {
      final repo = FauxChat(historique: historiqueExemple());
      final vm = await vmDemarre(repo);
      repo.historiqueResultat = [...historiqueExemple(), msg(5, 'Message pendant la coupure', DateTime(2026, 11, 7, 14, 55))];

      repo.reconnecter();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.chargementsHistorique, 2);
      expect(vm.messages.map((m) => m.id), [1, 2, 3, 5]);
    });

    test('erreur au chargement : message d’erreur', () async {
      final repo = FauxChat()..erreurHistorique = 'Connexion impossible. Vérifiez Internet et réessayez.';
      final vm = await vmDemarre(repo);
      expect(vm.erreur, contains('Connexion impossible'));
    });
  });

  group('Message', () {
    test('lecture d’une ligne de public.messages', () {
      final m = Message.depuisLigne({
        'id': 7,
        'id_conversation': 'c1',
        'id_expediteur': autreId,
        'contenu': 'Salut',
        'date_envoi': '2026-11-07T13:32:00+00:00',
        'lu': true,
      });
      expect(m.id, 7);
      expect(m.lu, isTrue);
      expect(m.dateEnvoi.isUtc, isFalse, reason: 'heure locale');
    });

    test('formaterHeure', () {
      expect(formaterHeure(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });
  });

  group('DiscussionPage (maquette C8)', () {
    Future<FauxChat> afficher(WidgetTester tester, {FauxChat? repo, List<String>? annoncesOuvertes}) async {
      final r = repo ?? FauxChat(historique: historiqueExemple(), infosResultat: infosExemple());
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: DiscussionPage(
          repository: r,
          idConversation: 'c1',
          titre: 'Karim Jaziri',
          horloge: horloge,
          onVoirAnnonce: (_, id) => annoncesOuvertes?.add(id),
        ),
      ));
      await tester.pumpAndSettle();
      return r;
    }

    testWidgets('en-tête, annonce liée, messages et heures', (tester) async {
      final ouvertes = <String>[];
      await afficher(tester, annoncesOuvertes: ouvertes);
      expect(find.text('Karim Jaziri'), findsOneWidget);
      expect(find.text('Villa avec piscine · La Marsa'), findsOneWidget);
      expect(find.text('385 000 DT'), findsOneWidget);
      expect(find.text('AUJOURD’HUI'), findsOneWidget);
      expect(find.text('HIER'), findsOneWidget);
      expect(find.text('La visite samedi à 10 h vous convient ?'), findsOneWidget);
      expect(find.text('14:32'), findsOneWidget);

      await tester.tap(find.text('Voir'));
      expect(ouvertes, ['a1']);
    });

    testWidgets('bouton Envoyer inactif tant que le champ est vide, puis envoi', (tester) async {
      final repo = await afficher(tester);
      IconButton bouton() => tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded));
      expect(bouton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Oui, samedi me va très bien');
      await tester.pump();
      expect(bouton().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(repo.envoyes, ['Oui, samedi me va très bien']);
      expect(find.text('Oui, samedi me va très bien'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    });

    testWidgets('message reçu en direct affiché sans recharger', (tester) async {
      final repo = await afficher(tester);
      repo.recevoir(msg(9, 'Je vous attends devant la porte', DateTime(2026, 11, 7, 14, 58)));
      await tester.pumpAndSettle();
      expect(find.text('Je vous attends devant la porte'), findsOneWidget);
    });

    testWidgets('échec : « Non envoyé » avec Réessayer', (tester) async {
      final repo = FauxChat(historique: historiqueExemple())..erreurEnvoi = 'Connexion impossible.';
      await afficher(tester, repo: repo);
      await tester.enterText(find.byType(TextField), 'Allô ?');
      await tester.pump(); // le bouton devient actif
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.text('Non envoyé'), findsOneWidget);

      repo.erreurEnvoi = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Non envoyé'), findsNothing);
      expect(repo.envoyes, ['Allô ?']);
    });

    testWidgets('conversation vide : invitation à écrire', (tester) async {
      await afficher(tester, repo: FauxChat());
      expect(find.textContaining('Écrivez le premier'), findsOneWidget);
    });

    testWidgets('annonce supprimée : pas de bouton Voir', (tester) async {
      await afficher(tester, repo: FauxChat(historique: historiqueExemple(), infosResultat: infosExemple(idAnnonce: null)));
      expect(find.text('Annonce supprimée'), findsOneWidget);
      expect(find.text('Voir'), findsNothing);
    });
  });
}
