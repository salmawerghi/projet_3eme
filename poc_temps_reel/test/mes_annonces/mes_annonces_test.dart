// Tests de [6.3] [6.5] Mes annonces avec un faux repository (sans Supabase).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc_temps_reel/core/darimmo_theme.dart';
import 'package:poc_temps_reel/features/mes_annonces/data/mes_annonces_repository.dart';
import 'package:poc_temps_reel/features/mes_annonces/mes_annonces_view_model.dart';
import 'package:poc_temps_reel/features/mes_annonces/models/mon_annonce.dart';
import 'package:poc_temps_reel/features/mes_annonces/ui/annonce_card.dart';
import 'package:poc_temps_reel/features/mes_annonces/ui/mes_annonces_page.dart';
import 'package:poc_temps_reel/features/publish/models/annonce.dart';

/// Ligne telle que Supabase la renvoie (select MonAnnonce.colonnes).
Map<String, dynamic> ligne(String titre, String statut, {String? motif, List<Map<String, dynamic>> photos = const []}) => {
      'id': 'id-$titre',
      'titre': titre,
      'type_bien': 'villa',
      'type_offre': 'vente',
      'prix': 450000,
      'surface': 220,
      'nb_pieces': 5,
      'adresse': null,
      'ville': 'Hammamet',
      'description': null,
      'statut': statut,
      'motif_rejet': motif,
      'date_creation': '2026-11-06T10:42:00Z',
      'date_maj': '2026-11-07T09:00:00Z',
      'photos': photos,
    };

final exemples = [
  ligne('Villa s+4', 'publiee'),
  ligne('Duplex Lac', 'publiee'),
  ligne('Appart Ennasr', 'en_attente'),
  ligne('Maison Sfax', 'rejetee', motif: 'Les photos ne montrent pas l’intérieur.'),
  ligne('Terrain Nabeul', 'vendue'),
].map(MonAnnonce.depuisLigne).toList();

class FauxRepository implements MesAnnoncesRepository {
  FauxRepository(this.resultat, {this.erreur});
  List<MonAnnonce> resultat;
  String? erreur;
  int appels = 0;

  @override
  Future<List<MonAnnonce>> lister() async {
    appels++;
    if (erreur != null) throw MesAnnoncesException(erreur!);
    return resultat;
  }

  // ----- [6.3] actions : on simule la base en modifiant la liste
  final conclues = <String>[];
  final supprimees = <String>[];
  String? erreurAction;

  @override
  Future<void> marquerConclue(MonAnnonce a) async {
    if (erreurAction != null) throw MesAnnoncesException(erreurAction!);
    conclues.add(a.id);
    resultat = [
      for (final x in resultat)
        x.id == a.id ? MonAnnonce.depuisLigne(ligne(x.titre, a.statutConclu == StatutAnnonce.louee ? 'louee' : 'vendue')) : x,
    ];
  }

  @override
  Future<void> supprimer(MonAnnonce a) async {
    if (erreurAction != null) throw MesAnnoncesException(erreurAction!);
    supprimees.add(a.id);
    resultat = resultat.where((x) => x.id != a.id).toList();
  }
}

Future<void> ouvrir(WidgetTester tester, MesAnnoncesRepository repo, {OuvrirModification? onModifier}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: darimmoTheme(),
    home: MesAnnoncesPage(repository: repo, onModifier: onModifier),
  ));
  await tester.pumpAndSettle();
}

/// Liste verticale des annonces (la rangée de puces défile, elle, horizontalement).
final listeVerticale = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);

/// Carte d'une annonce, pour chercher un bouton dedans.
Finder carte(String titre) => find.ancestor(of: find.text(titre), matching: find.byType(AnnonceCard));

void main() {
  group('MonAnnonce.depuisLigne', () {
    test('lit les colonnes, le statut et la première photo par ordre', () {
      final a = MonAnnonce.depuisLigne(ligne('Villa', 'en_attente', photos: [
        {'url': 'https://x/2.jpg', 'ordre': 1},
        {'url': 'https://x/1.jpg', 'ordre': 0},
      ]));
      expect(a.statut, StatutAnnonce.enAttente);
      expect(a.typeBien, TypeBien.villa);
      expect(a.prix, 450000);
      expect(a.photoUrl, 'https://x/1.jpg');
    });

    test('accepte un brouillon incomplet (champs vides)', () {
      final l = ligne('Brouillon', 'brouillon')
        ..['type_bien'] = null
        ..['type_offre'] = null
        ..['prix'] = null
        ..['ville'] = null;
      final a = MonAnnonce.depuisLigne(l);
      expect(a.typeBien, isNull);
      expect(a.prix, isNull);
      expect(a.photoUrl, isNull);
    });
  });

  group('MesAnnoncesViewModel', () {
    test('compteurs, résumé et filtres visibles', () async {
      final vm = MesAnnoncesViewModel(FauxRepository(exemples));
      await vm.charger();
      expect(vm.resume, '5 annonces · 2 en ligne');
      expect(vm.compter(FiltreAnnonces.rejetees), 1);
      expect(vm.filtresVisibles, [
        FiltreAnnonces.toutes,
        FiltreAnnonces.publiees,
        FiltreAnnonces.enAttente,
        FiltreAnnonces.rejetees,
        FiltreAnnonces.vendues,
      ]);
    });

    test('le filtre ne garde que les statuts choisis', () async {
      final vm = MesAnnoncesViewModel(FauxRepository(exemples));
      await vm.charger();
      vm.choisirFiltre(FiltreAnnonces.publiees);
      expect(vm.annonces.map((a) => a.titre), ['Villa s+4', 'Duplex Lac']);
    });

    test('revient sur « Toutes » si le filtre choisi devient vide', () async {
      final repo = FauxRepository(exemples);
      final vm = MesAnnoncesViewModel(repo);
      await vm.charger();
      vm.choisirFiltre(FiltreAnnonces.rejetees);
      repo.resultat = exemples.where((a) => a.statut != StatutAnnonce.rejetee).toList();
      await vm.charger();
      expect(vm.filtre, FiltreAnnonces.toutes);
    });

    test('erreur du repository : message gardé, pas d’exception', () async {
      final vm = MesAnnoncesViewModel(FauxRepository(const [], erreur: 'Connexion impossible.'));
      await vm.charger();
      expect(vm.erreur, 'Connexion impossible.');
      expect(vm.chargement, isFalse);
    });
  });

  group('Écran Mes annonces', () {
    testWidgets('affiche les annonces, les badges et le motif du rejet', (tester) async {
      await ouvrir(tester, FauxRepository(exemples));
      expect(find.text('Mes annonces'), findsOneWidget);
      expect(find.text('5 annonces · 2 en ligne'), findsOneWidget);
      expect(find.text('Villa s+4'), findsOneWidget);
      expect(find.text('Publiée'), findsNWidgets(2));
      expect(find.text('Motif du rejet'), findsOneWidget);
      expect(find.text('Les photos ne montrent pas l’intérieur.'), findsOneWidget);
      expect(find.text('450 000 DT'), findsWidgets);
      // Avec les boutons d'action, la 5e carte est sous l'écran : on fait défiler.
      await tester.scrollUntilVisible(find.text('Terrain Nabeul'), 200, scrollable: listeVerticale);
      expect(find.descendant(of: carte('Terrain Nabeul'), matching: find.text('450 000 DT')), findsOneWidget);
    });

    testWidgets('toucher une puce filtre la liste', (tester) async {
      await ouvrir(tester, FauxRepository(exemples));
      // La rangée de puces défile horizontalement : on l'amène à l'écran d'abord.
      await tester.ensureVisible(find.text('Rejetées · 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rejetées · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Maison Sfax'), findsOneWidget);
      expect(find.text('Villa s+4'), findsNothing);
    });

    testWidgets('aucune annonce : message vide', (tester) async {
      await ouvrir(tester, FauxRepository(const []));
      expect(find.text('Aucune annonce pour l’instant'), findsOneWidget);
    });

    testWidgets('erreur : message et bouton Réessayer qui recharge', (tester) async {
      final repo = FauxRepository(const [], erreur: 'Connexion impossible.');
      await ouvrir(tester, repo);
      expect(find.text('Impossible de charger vos annonces'), findsOneWidget);

      repo.erreur = null;
      repo.resultat = exemples;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(repo.appels, 2);
      expect(find.text('Villa s+4'), findsOneWidget);
    });
  });

  // ===================================================================
  // [6.3] Étape 2 : modifier, marquer vendue / louée, supprimer
  // ===================================================================
  group('Actions possibles selon le statut', () {
    MonAnnonce a(String statut, {String offre = 'vente'}) =>
        MonAnnonce.depuisLigne(ligne('A', statut)..['type_offre'] = offre);

    test('publiée : modifier et marquer vendue', () {
      expect(a('publiee').peutModifier, isTrue);
      expect(a('publiee').peutMarquerVendue, isTrue);
      expect(a('publiee').statutConclu, StatutAnnonce.vendue);
      expect(a('publiee', offre: 'location').statutConclu, StatutAnnonce.louee);
    });

    test('rejetée / en attente : modifier seulement', () {
      for (final s in ['rejetee', 'en_attente']) {
        expect(a(s).peutModifier, isTrue, reason: s);
        expect(a(s).peutMarquerVendue, isFalse, reason: s);
      }
    });

    test('vendue, louée, masquée : ni modifier ni marquer vendue', () {
      for (final s in ['vendue', 'louee', 'masquee']) {
        expect(a(s).peutModifier, isFalse, reason: s);
        expect(a(s).peutMarquerVendue, isFalse, reason: s);
      }
    });

    test('versEdition reprend les valeurs de l’annonce', () {
      final e = a('rejetee').versEdition()!;
      expect(e.id, 'id-A');
      expect(e.statut, StatutAnnonce.rejetee);
      expect(e.valeurs.prix, 450000);
      expect(e.valeurs.nbPieces, 5);
      expect(e.valeurs.ville, 'Hammamet');
    });

    test('chemins des photos lus pour la suppression', () {
      final x = MonAnnonce.depuisLigne(ligne('A', 'publiee', photos: [
        {'url': 'u1', 'ordre': 0, 'chemin_storage': 'id-A/1.jpg'},
        {'url': 'u2', 'ordre': 1, 'chemin_storage': 'id-A/2.jpg'},
      ]));
      expect(x.cheminsPhotos, ['id-A/1.jpg', 'id-A/2.jpg']);
      expect(x.nbPhotos, 2);
    });
  });

  group('MesAnnoncesViewModel : actions', () {
    test('supprimer : la liste et les compteurs sont recalculés', () async {
      final repo = FauxRepository(exemples);
      final vm = MesAnnoncesViewModel(repo);
      await vm.charger();
      final erreur = await vm.supprimer(vm.annonces.first);
      expect(erreur, isNull);
      expect(repo.supprimees, ['id-Villa s+4']);
      expect(vm.resume, '4 annonces · 1 en ligne');
      expect(vm.estEnCours(exemples.first), isFalse);
    });

    test('marquer vendue : le statut change après rechargement', () async {
      final repo = FauxRepository(exemples);
      final vm = MesAnnoncesViewModel(repo);
      await vm.charger();
      await vm.marquerConclue(vm.annonces.first);
      expect(vm.compter(FiltreAnnonces.vendues), 2);
      expect(vm.enLigne, 1);
    });

    test('erreur : message renvoyé, liste inchangée', () async {
      final repo = FauxRepository(exemples)..erreurAction = 'Changement de statut non autorisé';
      final vm = MesAnnoncesViewModel(repo);
      await vm.charger();
      expect(await vm.marquerConclue(vm.annonces.first), 'Changement de statut non autorisé');
      expect(vm.total, 5);
    });
  });

  group('Écran Mes annonces : actions', () {
    Future<Annonce?> pasDeModification(BuildContext _, EditionAnnonce _) async => null;

    testWidgets('boutons de la maquette C5 selon le statut', (tester) async {
      await ouvrir(tester, FauxRepository(exemples), onModifier: pasDeModification);
      final villa = carte('Villa s+4');
      expect(find.descendant(of: villa, matching: find.text('Modifier')), findsOneWidget);
      expect(find.descendant(of: villa, matching: find.text('Marquer vendue')), findsOneWidget);
      expect(find.descendant(of: villa, matching: find.byTooltip('Supprimer')), findsOneWidget);

      final attente = carte('Appart Ennasr');
      expect(find.descendant(of: attente, matching: find.text('Modifier')), findsOneWidget);
      expect(find.descendant(of: attente, matching: find.text('Marquer vendue')), findsNothing);

      await tester.scrollUntilVisible(find.text('Maison Sfax'), 200, scrollable: listeVerticale);
      expect(find.descendant(of: carte('Maison Sfax'), matching: find.text('Modifier et renvoyer')), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Terrain Nabeul'), 200, scrollable: listeVerticale);
      final vendue = carte('Terrain Nabeul');
      expect(find.descendant(of: vendue, matching: find.textContaining('Modifier')), findsNothing);
      expect(find.descendant(of: vendue, matching: find.byTooltip('Supprimer')), findsOneWidget);
    });

    testWidgets('supprimer : Annuler ne fait rien, Supprimer retire l’annonce', (tester) async {
      final repo = FauxRepository(exemples);
      await ouvrir(tester, repo);
      final corbeille = find.descendant(of: carte('Duplex Lac'), matching: find.byTooltip('Supprimer'));

      await tester.tap(corbeille);
      await tester.pumpAndSettle();
      expect(find.text('Supprimer cette annonce ?'), findsOneWidget);
      expect(find.textContaining('« Duplex Lac » sera supprimée définitivement'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repo.supprimees, isEmpty);
      expect(find.text('Duplex Lac'), findsOneWidget);

      await tester.tap(corbeille);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(repo.supprimees, ['id-Duplex Lac']);
      expect(find.text('Duplex Lac'), findsNothing);
      expect(find.text('Annonce supprimée.'), findsOneWidget);
      expect(find.text('4 annonces · 1 en ligne'), findsOneWidget);
    });

    testWidgets('marquer vendue après confirmation', (tester) async {
      final repo = FauxRepository(exemples);
      await ouvrir(tester, repo);
      await tester.tap(find.descendant(of: carte('Villa s+4'), matching: find.text('Marquer vendue')));
      await tester.pumpAndSettle();
      expect(find.text('Marquer comme vendue ?'), findsOneWidget);
      // 2e « Marquer vendue » = bouton de la boîte de dialogue
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Marquer vendue')));
      await tester.pumpAndSettle();
      expect(repo.conclues, ['id-Villa s+4']);
      expect(find.text('Annonce marquée vendue.'), findsOneWidget);
      expect(find.text('5 annonces · 1 en ligne'), findsOneWidget);
    });

    testWidgets('modifier : ouvre le formulaire pré-rempli puis annonce la re-validation', (tester) async {
      EditionAnnonce? recue;
      Future<Annonce?> onModifier(BuildContext _, EditionAnnonce e) async {
        recue = e;
        return Annonce(
          id: e.id, titre: e.valeurs.titre, typeBien: e.valeurs.typeBien, typeOffre: e.valeurs.typeOffre,
          prix: e.valeurs.prix, ville: e.valeurs.ville, statut: StatutAnnonce.enAttente, dateCreation: DateTime(2026),
        );
      }

      final repo = FauxRepository(exemples);
      await ouvrir(tester, repo, onModifier: onModifier);
      await tester.tap(find.descendant(of: carte('Villa s+4'), matching: find.text('Modifier')));
      await tester.pumpAndSettle();
      expect(recue?.id, 'id-Villa s+4');
      expect(recue?.statut, StatutAnnonce.publiee);
      expect(repo.appels, 2, reason: 'liste rechargée au retour');
      expect(find.text('Annonce modifiée : elle est de nouveau en attente de validation.'), findsOneWidget);
    });
  });
}
