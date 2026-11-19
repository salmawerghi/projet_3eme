// Tests du squelette 1.6 : connexion obligatoire, onglets, routes des modules.
// Aucun accès réseau : Services construit avec de faux repositories.
import 'package:darimmo/app.dart';
import 'package:darimmo/core/router/app_router.dart';
import 'package:darimmo/core/services.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';
import 'package:darimmo/features/chat/data/repositories/conversations_repository.dart';
import 'package:darimmo/features/notifications/data/push_service.dart';
import 'package:darimmo/features/profile/data/repositories/profil_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';
import 'package:darimmo/features/publish/data/models/mon_annonce.dart';
import 'package:darimmo/features/publish/data/repositories/annonce_repository.dart';
import 'package:darimmo/features/publish/data/repositories/mes_annonces_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/admin/faux_admin.dart';
import '../features/auth/faux_auth.dart';
import '../features/chat/faux_chat.dart';
import '../features/publish/faux_photos_repository.dart';
import '../features/publish/faux_position.dart';
import '../features/report/faux_signalements.dart';
import '../features/detail/faux_detail.dart';
import '../features/favorites/faux_favoris.dart';
import '../features/map/fausse_carte.dart';
import '../features/search/fausse_recherche.dart';

class FauxAnnonces implements AnnonceRepository {
  @override
  Future<Annonce> creerBrouillon(NouvelleAnnonce a) =>
      throw UnimplementedError();
  @override
  Future<Annonce> modifier(EditionAnnonce e, NouvelleAnnonce a) =>
      throw UnimplementedError();
  @override
  Future<Annonce> finaliser(
    String id, {
    required double latitude,
    required double longitude,
    required bool envoyerEnValidation,
  }) => throw UnimplementedError();
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
  /// [7.1] annonce -> conversation déjà ouverte (pour vérifier la reprise).
  final ouvertes = <String, String>{};
  int ouvertures = 0;

  /// Erreur à lever par ouvrirAvecAnnonceur (null = succès).
  ContactException? erreurContact;

  @override
  Future<List<ResumeConversation>> lister() async => const [];
  @override
  Stream<void> changements() => const Stream.empty();

  @override
  Future<String> ouvrirAvecAnnonceur(String idAnnonce) async {
    ouvertures++;
    final erreur = erreurContact;
    if (erreur != null) throw erreur;
    return ouvertes.putIfAbsent(idAnnonce, () => 'c-${ouvertes.length + 1}');
  }
}

class FauxProfilRepository implements ProfilRepository {
  @override
  Future<DonneesProfil> charger() async =>
      const DonneesProfil(nom: 'Vendeur DarImmo');

  @override
  Future<DonneesProfil> enregistrer({
    required String nom,
    required String? telephone,
    PhotoChoisie? photo,
  }) async => DonneesProfil(nom: nom, telephone: telephone);
}

Services fauxServices(
  FauxAuth auth, {
  FaussesConversations? conversations,
  FauxDetail? detail,
  FauxFavoris? favoris,
  FauxCompte? compte,
  FausseModeration? moderation,
  FauxSignalements? signalements,
}) =>
    Services(
      auth: auth,
      compte: compte ?? FauxCompte(),
      moderation: moderation ?? FausseModeration(),
      profil: FauxProfilRepository(),
      recherche: FausseRecherche([
        annonceTest(1, titre: 'Appartement S+2 lumineux'),
      ]),
      detail: detail ?? FauxDetail(),
      carte: FausseCarte(),
      favoris: favoris ?? FauxFavoris(),
      signalements: signalements ?? FauxSignalements(),
      annonces: FauxAnnonces(),
      photos: FauxPhotosRepository(),
      mesAnnonces: FaussesMesAnnonces(),
      conversations: conversations ?? FaussesConversations(),
      chat: FauxChat(),
      geocodage: FauxGeocodage(),
      localisation: FausseLocalisation(),
      choisirPhotos: FausseGalerie().choisir,
      afficherTuilesCarte: false,
    );

Future<FauxAuth> demarrer(
  WidgetTester tester, {
  bool connecte = true,
  String? initiale,
  FaussesConversations? conversations,
  FauxDetail? detail,
  FauxFavoris? favoris,
  FauxCompte? compte,
  FausseModeration? moderation,
  FauxSignalements? signalements,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final auth = FauxAuth(connecte: connecte);
  final routeur = creerRouteur(
    fauxServices(
      auth,
      conversations: conversations,
      detail: detail,
      favoris: favoris,
      compte: compte,
      moderation: moderation,
      signalements: signalements,
    ),
    initiale: initiale,
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(DarImmoApp(routeur: routeur));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('non connecté : bienvenue (A1), connexion, puis accueil', (
    tester,
  ) async {
    final auth = await demarrer(tester, connecte: false);
    expect(
      find.text('Trouvez le bien qui vous ressemble, partout en Tunisie.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('J’ai déjà un compte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Content de vous revoir'),
      findsOneWidget,
      reason: 'maquette A2',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse email'),
      'vendeur@darimmo.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'Test1234!',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(auth.connexions, 1);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Trouvez votre chez-vous'),
      findsOneWidget,
      reason: 'accueil 3.1 du membre B',
    );
    expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
  });

  testWidgets('bouton retour de la connexion : revient à la bienvenue', (
    tester,
  ) async {
    await demarrer(tester, connecte: false);
    await tester.tap(find.text('J’ai déjà un compte'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('J’ai déjà un compte'), findsOneWidget);
  });

  testWidgets(
    'visiteur : « Continuer sans compte » montre les annonces, un onglet privé ramène à la bienvenue',
    (tester) async {
      await demarrer(tester, connecte: false);
      await tester.tap(find.text('Continuer sans compte'));
      await tester.pumpAndSettle();
      expect(
        find.text('Appartement S+2 lumineux'),
        findsOneWidget,
        reason: '3.1 « En tant que visiteur »',
      );

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('J’ai déjà un compte'), findsOneWidget);
    },
  );

  testWidgets('session conservée : l’app s’ouvre directement sur l’accueil', (
    tester,
  ) async {
    await demarrer(tester);
    expect(find.text('Trouvez votre chez-vous'), findsOneWidget);
    expect(find.text('Continuer sans compte'), findsNothing);
  });

  testWidgets('mauvais mot de passe : message clair', (tester) async {
    await demarrer(tester, connecte: false, initiale: '/bienvenue/connexion');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse email'),
      'vendeur@darimmo.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'faux',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets(
    'connexion : champs vides signalés, pas de comptes de test ni de texte provisoire',
    (tester) async {
      final auth = await demarrer(
        tester,
        connecte: false,
        initiale: '/bienvenue/connexion',
      );
      expect(find.text('vendeur'), findsNothing);
      expect(find.text('acheteur'), findsNothing);
      expect(find.textContaining('provisoire'), findsNothing);

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('L’adresse email est obligatoire'), findsOneWidget);
      expect(find.text('Entrez votre mot de passe'), findsOneWidget);
      expect(auth.connexions, 0);
    },
  );

  testWidgets('connexion : l’œil affiche puis masque le mot de passe', (
    tester,
  ) async {
    await demarrer(tester, connecte: false, initiale: '/bienvenue/connexion');
    TextField champ() => tester.widget<TextField>(
      find.widgetWithText(TextField, 'Mot de passe'),
    );
    expect(champ().obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();
    expect(champ().obscureText, isFalse);
  });

  testWidgets('les 4 onglets de la maquette et le bouton Publier', (
    tester,
  ) async {
    await demarrer(tester);
    for (final libelle in [
      'Accueil',
      'Favoris',
      'Publier',
      'Messages',
      'Profil',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(libelle),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Mes favoris'), findsOneWidget, reason: 'écran 5.2');
    expect(find.text('Aucun favori pour l’instant'), findsOneWidget);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune conversation'),
      findsWidgets,
      reason: 'écran 7.3 du membre C',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Publier'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Publier une annonce'),
      findsOneWidget,
      reason: 'formulaire 6.1 par-dessus les onglets',
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Profil : Mes annonces, puis déconnexion', (tester) async {
    await demarrer(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('vendeur@darimmo.test'), findsOneWidget);

    await tester.tap(find.text('Mes annonces'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune annonce pour l’instant'),
      findsOneWidget,
      reason: 'écran 6.3 du membre C',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    final boutonDeconnexion = find.text('Se déconnecter');
    await tester.scrollUntilVisible(
      boutonDeconnexion,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(boutonDeconnexion);
    await tester.pumpAndSettle();
    expect(
      find.text('J’ai déjà un compte'),
      findsOneWidget,
      reason: 'retour à la bienvenue',
    );
  });

  testWidgets('route du détail d’une annonce (3.3)', (tester) async {
    final detail = FauxDetail();
    await demarrer(tester, initiale: '/annonces/abc-123', detail: detail);
    expect(detail.appels, 1);
    expect(find.text('Appartement S+2 lumineux'), findsOneWidget);
    expect(find.text('Bientôt disponible'), findsNothing);
  });

  testWidgets('route de reset password : écran de changement du mot de passe', (
    tester,
  ) async {
    await demarrer(tester, connecte: false, initiale: '/reset-password');
    expect(find.text('Choisissez un nouveau mot de passe'), findsOneWidget);
    expect(find.text('Enregistrer le nouveau mot de passe'), findsOneWidget);
  });

  test('chemin ouvert par une notification (8.1 / 8.2)', () {
    expect(
      PushService.cheminPour({'type': 'message', 'id_conversation': 'c1'}),
      '/messages/c1',
    );
    expect(PushService.cheminPour({'type': 'statut'}), '/mes-annonces');
    expect(PushService.cheminPour({'type': 'autre'}), isNull);
  });
}
