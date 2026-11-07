// Tests de [7.3] Voir mes conversations (faux repository, sans Supabase).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc_temps_reel/core/darimmo_theme.dart';
import 'package:poc_temps_reel/features/conversations/conversations_view_model.dart';
import 'package:poc_temps_reel/features/conversations/data/conversations_repository.dart';
import 'package:poc_temps_reel/features/conversations/models/resume_conversation.dart';
import 'package:poc_temps_reel/features/conversations/ui/conversations_page.dart';

/// Vendredi 7 novembre 2026, 15 h (heure de référence des tests).
final maintenant = DateTime(2026, 11, 7, 15);

/// Ligne telle que la renvoie public.mes_conversations().
Map<String, dynamic> ligne(String id, String nom, DateTime date,
        {String? annonce = 'Villa avec piscine', String? message = 'Bonjour', int nonLus = 0}) =>
    {
      'id': id,
      'id_annonce': annonce == null ? null : 'a-$id',
      'titre_annonce': annonce,
      'photo_annonce': null,
      'id_interlocuteur': 'u-$id',
      'nom_interlocuteur': nom,
      'photo_interlocuteur': null,
      'dernier_message': message,
      'date_dernier_message': date.toUtc().toIso8601String(),
      'non_lus': nonLus,
    };

List<ResumeConversation> exemples() => [
      ligne('c2', 'Ines Gharbi', DateTime(2026, 11, 6, 18), annonce: 'S+2 meublé vue mer', message: 'Le loyer inclut les charges ?'),
      ligne('c1', 'Karim Jaziri', DateTime(2026, 11, 7, 14, 32),
          message: 'La visite samedi à 10 h vous convient ?', nonLus: 2),
      ligne('c3', 'Sami Ben Salah', DateTime(2026, 11, 3, 9), annonce: null, message: 'Merci, je vous rappelle.', nonLus: 1),
    ].map(ResumeConversation.depuisLigne).toList();

class FauxRepository implements ConversationsRepository {
  FauxRepository(this.resultat, {this.erreur});
  List<ResumeConversation> resultat;
  String? erreur;
  int appels = 0;
  final _flux = StreamController<void>.broadcast();
  bool ecoute = false;

  /// Simule un événement Realtime (nouveau message dans une conversation).
  void evenement() => _flux.add(null);

  @override
  Future<List<ResumeConversation>> lister() async {
    appels++;
    if (erreur != null) throw ConversationsException(erreur!);
    return resultat;
  }

  @override
  Stream<void> changements() {
    ecoute = true;
    return _flux.stream;
  }
}

void main() {
  group('ResumeConversation', () {
    test('lit une ligne de mes_conversations()', () {
      final c = ResumeConversation.depuisLigne(ligne('c1', 'Karim Jaziri', maintenant, nonLus: 2));
      expect(c.nomAffiche, 'Karim Jaziri');
      expect(c.initiales, 'KJ');
      expect(c.titreAnnonce, 'Villa avec piscine');
      expect(c.aDesNonLus, isTrue);
      expect(c.annonceSupprimee, isFalse);
    });

    test('annonce supprimée et nom vide', () {
      final c = ResumeConversation.depuisLigne(ligne('c', '  ', maintenant, annonce: null));
      expect(c.annonceSupprimee, isTrue);
      expect(c.nomAffiche, 'Utilisateur DarImmo');
      expect(c.initiales, 'UD');
    });

    test('recherche par personne ou par bien, sans accents ni majuscules', () {
      final c = ResumeConversation.depuisLigne(ligne('c', 'Inès Gharbi', maintenant, annonce: 'S+2 meublé vue mer'));
      expect(c.correspond('ines'), isTrue);
      expect(c.correspond('MEUBLE'), isTrue);
      expect(c.correspond('villa'), isFalse);
      expect(c.correspond('  '), isTrue);
    });
  });

  group('formaterDateConversation (maquette C7)', () {
    test('aujourd’hui : heure', () => expect(formaterDateConversation(DateTime(2026, 11, 7, 9, 5), maintenant), '09:05'));
    test('hier', () => expect(formaterDateConversation(DateTime(2026, 11, 6, 23, 59), maintenant), 'Hier'));
    test('cette semaine : jour', () => expect(formaterDateConversation(DateTime(2026, 11, 3, 8), maintenant), 'Mar.'));
    test('plus ancien : date', () => expect(formaterDateConversation(DateTime(2026, 10, 28), maintenant), '28/10'));
    test('autre année', () => expect(formaterDateConversation(DateTime(2025, 12, 31), maintenant), '31/12/25'));
  });

  group('formaterJourDiscussion (séparateurs de la maquette C8)', () {
    test('aujourd’hui / hier', () {
      expect(formaterJourDiscussion(DateTime(2026, 11, 7, 0, 1), maintenant), 'Aujourd’hui');
      expect(formaterJourDiscussion(DateTime(2026, 11, 6, 23, 59), maintenant), 'Hier');
    });
    test('jour et date en toutes lettres', () {
      expect(formaterJourDiscussion(DateTime(2026, 11, 4, 22, 32), maintenant), 'Mercredi 4 novembre');
      expect(formaterJourDiscussion(DateTime(2025, 8, 15), maintenant), 'Vendredi 15 août 2025');
    });
  });

  group('ConversationsViewModel', () {
    test('tri du plus récent au plus ancien et total des non-lus', () async {
      final vm = ConversationsViewModel(FauxRepository(exemples()));
      await vm.charger();
      expect(vm.conversations.map((c) => c.id), ['c1', 'c2', 'c3']);
      expect(vm.totalNonLus, 3);
      expect(vm.resume, '3 messages non lus');
    });

    test('résumé : aucun non lu, aucune conversation', () async {
      final repo = FauxRepository([ResumeConversation.depuisLigne(ligne('c', 'A B', maintenant))]);
      final vm = ConversationsViewModel(repo);
      await vm.charger();
      expect(vm.resume, 'Tout est lu');
      repo.resultat = const [];
      await vm.charger();
      expect(vm.resume, 'Aucune conversation');
    });

    test('un événement temps réel recharge la liste', () async {
      final repo = FauxRepository(exemples());
      final vm = ConversationsViewModel(repo);
      await vm.demarrer();
      expect(repo.ecoute, isTrue);
      repo.resultat = [...exemples(), ResumeConversation.depuisLigne(ligne('c4', 'Yosr Mansour', maintenant))];
      repo.evenement();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(vm.total, 4);
      expect(vm.conversations.first.id, 'c4');
      vm.dispose();
    });

    test('erreur : message gardé', () async {
      final vm = ConversationsViewModel(FauxRepository(const [], erreur: 'Connexion impossible.'));
      await vm.charger();
      expect(vm.erreur, 'Connexion impossible.');
    });
  });

  group('Écran Messages (maquette C7)', () {
    Future<void> ouvrir(WidgetTester tester, FauxRepository repo, {OuvrirConversation? onOuvrir}) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: darimmoTheme(),
        home: ConversationsPage(
          repository: repo,
          onOuvrir: onOuvrir ?? (_, _) async {},
          maintenant: () => maintenant,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('nom, annonce, dernier message, heure et pastille de non-lus', (tester) async {
      await ouvrir(tester, FauxRepository(exemples()));
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('3 messages non lus'), findsOneWidget);

      final karim = find.ancestor(of: find.text('Karim Jaziri'), matching: find.byType(LigneConversation));
      expect(find.descendant(of: karim, matching: find.text('Villa avec piscine')), findsOneWidget);
      expect(find.descendant(of: karim, matching: find.text('La visite samedi à 10 h vous convient ?')), findsOneWidget);
      expect(find.descendant(of: karim, matching: find.text('14:32')), findsOneWidget);
      expect(find.descendant(of: karim, matching: find.text('2')), findsOneWidget);
      expect(find.descendant(of: karim, matching: find.text('KJ')), findsOneWidget, reason: 'initiales sans photo');

      expect(find.text('Hier'), findsOneWidget);
      expect(find.text('Annonce supprimée'), findsOneWidget);
    });

    testWidgets('ordre d’affichage : la plus récente en haut', (tester) async {
      await ouvrir(tester, FauxRepository(exemples()));
      final y = [for (final n in ['Karim Jaziri', 'Ines Gharbi', 'Sami Ben Salah']) tester.getTopLeft(find.text(n)).dy];
      expect(y[0] < y[1] && y[1] < y[2], isTrue);
    });

    testWidgets('recherche « une personne ou un bien »', (tester) async {
      await ouvrir(tester, FauxRepository(exemples()));
      await tester.enterText(find.byType(TextField), 'meuble');
      await tester.pump();
      expect(find.text('Ines Gharbi'), findsOneWidget);
      expect(find.text('Karim Jaziri'), findsNothing);
    });

    testWidgets('ouvrir une conversation puis recharger au retour', (tester) async {
      final repo = FauxRepository(exemples());
      ResumeConversation? ouverte;
      await ouvrir(tester, repo, onOuvrir: (_, c) async {
        ouverte = c;
        repo.resultat = exemples().map((x) => x.id == c.id
            ? ResumeConversation.depuisLigne(ligne(x.id, x.nomAffiche, x.dateDernierMessage,
                message: x.dernierMessage, nonLus: 0))
            : x).toList();
      });
      await tester.tap(find.text('Karim Jaziri'));
      await tester.pumpAndSettle();
      expect(ouverte?.id, 'c1');
      expect(repo.appels, 2);
      expect(find.text('1 message non lu'), findsOneWidget, reason: 'les 2 messages de Karim sont lus');
    });

    testWidgets('nouveau message en direct : la liste se met à jour', (tester) async {
      final repo = FauxRepository(exemples());
      await ouvrir(tester, repo);
      repo.resultat = [
        ResumeConversation.depuisLigne(ligne('c2', 'Ines Gharbi', DateTime(2026, 11, 7, 14, 59),
            annonce: 'S+2 meublé vue mer', message: 'Je peux visiter demain ?', nonLus: 1)),
        ...exemples().where((c) => c.id != 'c2'),
      ];
      repo.evenement();
      await tester.pumpAndSettle();
      expect(find.text('Je peux visiter demain ?'), findsOneWidget);
      expect(find.text('4 messages non lus'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Ines Gharbi')).dy, lessThan(tester.getTopLeft(find.text('Karim Jaziri')).dy));
    });

    testWidgets('aucune conversation : message d’aide', (tester) async {
      await ouvrir(tester, FauxRepository(const []));
      expect(find.text('Aucune conversation'), findsNWidgets(2)); // sous-titre + message
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('erreur : bouton Réessayer', (tester) async {
      final repo = FauxRepository(const [], erreur: 'Connexion impossible.');
      await ouvrir(tester, repo);
      expect(find.text('Impossible de charger vos messages'), findsOneWidget);
      repo
        ..erreur = null
        ..resultat = exemples();
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Karim Jaziri'), findsOneWidget);
    });
  });
}
