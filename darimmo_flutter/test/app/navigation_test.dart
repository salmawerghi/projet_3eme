// Tests du squelette 1.6 : connexion obligatoire, onglets, routes des modules.
// Aucun accès réseau : Services construit avec de faux repositories.
import 'package:darimmo/app.dart';
import 'package:darimmo/core/router/app_router.dart';
import 'package:darimmo/core/services.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';
import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';
import 'package:darimmo/features/notifications/data/push_service.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/data/models/mon_annonce.dart';
import 'package:darimmo/features/publish/data/repositories/annonce_repository.dart';
import 'package:darimmo/features/publish/data/repositories/mes_annonces_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/publish/faux_photos_repository.dart';
import '../features/publish/faux_position.dart';

class FauxAuth extends AuthRepository {
  FauxAuth({this.connecte = false});
  bool connecte;
  int connexions = 0;

  @override
  bool get estConnecte => connecte;
  @override
  String? get idUtilisateur => connecte ? 'u1' : null;
  @override
  String? get email => connecte ? 'vendeur@darimmo.test' : null;

  @override
  Future<void> connecter({required String email, required String motDePasse}) async {
    if (motDePasse != 'Test1234!') throw const ConnexionException('Email ou mot de passe incorrect.');
    connexions++;
    connecte = true;
    notifyListeners();
  }

  @override
  Future<void> deconnecter() async {
    connecte = false;
    notifyListeners();
  }
}

class FauxAnnonces implements AnnonceRepository {
  @override
  Future<Annonce> creerBrouillon(NouvelleAnnonce a) => throw UnimplementedError();
  @override
  Future<Annonce> modifier(EditionAnnonce e, NouvelleAnnonce a) => throw UnimplementedError();
  @override
  Future<Annonce> finaliser(String id,
          {required double latitude, required double longitude, required bool envoyerEnValidation}) =>
      throw UnimplementedError();
}

class FaussesMesAnnonces implements MesAnnoncesRepository {
  @override
  Future<List<MonAnnonce>> lister() async => const [];
  @override
  Future<void> marquerConclue(MonAnnonce a) async {}
  @override
  Future<void> supprimer(MonAnnonce a) async {}
}

class FaussesConversations implements ConversationsRepository {
  @override
  Future<List<ResumeConversation>> lister() async => const [];
  @override
  Stream<void> changements() => const Stream.empty();
}

Services fauxServices(FauxAuth auth) => Services(
      auth: auth,
      annonces: FauxAnnonces(),
      photos: FauxPhotosRepository(),
      mesAnnonces: FaussesMesAnnonces(),
      conversations: FaussesConversations(),
      geocodage: FauxGeocodage(),
      localisation: FausseLocalisation(),
      choisirPhotos: FausseGalerie().choisir,
      afficherTuilesCarte: false,
    );

Future<FauxAuth> demarrer(WidgetTester tester, {bool connecte = true, String initiale = '/accueil'}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final auth = FauxAuth(connecte: connecte);
  final routeur = creerRouteur(fauxServices(auth), initiale: initiale);
  addTearDown(routeur.dispose);
  await tester.pumpWidget(DarImmoApp(routeur: routeur));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('non connecté : redirigé vers la connexion, puis accueil après connexion', (tester) async {
    final auth = await demarrer(tester, connecte: false);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(auth.connexions, 1);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('3.1 Voir la liste des annonces · 3.2 Filtrer les annonces'), findsOneWidget);
  });

  testWidgets('mauvais mot de passe : message clair', (tester) async {
    await demarrer(tester, connecte: false);
    await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'faux');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('les 4 onglets de la maquette et le bouton Publier', (tester) async {
    await demarrer(tester);
    for (final libelle in ['Accueil', 'Favoris', 'Publier', 'Messages', 'Profil']) {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(libelle)), findsOneWidget);
    }

    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5.2 Consulter mes favoris'), findsOneWidget);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune conversation'), findsWidgets, reason: 'écran 7.3 du membre C');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Publier')));
    await tester.pumpAndSettle();
    expect(find.text('Publier une annonce'), findsOneWidget, reason: 'formulaire 6.1 par-dessus les onglets');
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Profil : Mes annonces, puis déconnexion', (tester) async {
    await demarrer(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('vendeur@darimmo.test'), findsOneWidget);

    await tester.tap(find.text('Mes annonces'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune annonce pour l’instant'), findsOneWidget, reason: 'écran 6.3 du membre C');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('route du détail d’une annonce (3.3, membre B)', (tester) async {
    await demarrer(tester, initiale: '/annonces/abc-123');
    expect(find.widgetWithText(AppBar, 'Détail de l’annonce'), findsOneWidget);
    expect(find.text('id = abc-123'), findsOneWidget);
  });

  test('chemin ouvert par une notification (8.1 / 8.2)', () {
    expect(PushService.cheminPour({'type': 'message', 'id_conversation': 'c1'}), '/messages/c1');
    expect(PushService.cheminPour({'type': 'statut'}), '/mes-annonces');
    expect(PushService.cheminPour({'type': 'autre'}), isNull);
  });
}
