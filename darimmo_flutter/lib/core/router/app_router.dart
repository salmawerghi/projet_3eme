// =====================================================================
// DarImmo - Navigation (tâche 1.6) : go_router
//
// Toutes les routes de l'application sont ici. Pour brancher son écran :
// remplacer l'écran « BientotDisponible » de sa route par le vrai.
//
//   /bienvenue                      A  maquette A1 (premier écran sans session)
//   /bienvenue/connexion            A  2.2 (provisoire ; extra : email pré-rempli)
//   /bienvenue/inscription          A  2.1
//   Visiteur sans compte : seulement /accueil, /annonces/:id et /carte.
//   /accueil      (onglet)          B  3.1 / 3.2
//   /favoris      (onglet)          B  5.1 / 5.2
//   /messages     (onglet)          C  7.3
//   /profil       (onglet)          A  2.3
//   /messages/:id                   C  7.2 discussion
//   /annonces/:id                   B  3.3 détail (bouton Contacter : C 7.1)
//   /carte                          B  4.1 / 4.2
//   /publier                        C  6.1 + 6.2 + 6.4
//   /mes-annonces                   C  6.3 / 6.5
//   /mes-annonces/modifier          C  6.3 (extra : EditionAnnonce)
//   /admin                          A  9.x
// =====================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darimmo/core/router/navigation_principale.dart';
import 'package:darimmo/core/services.dart';
import 'package:darimmo/features/admin/presentation/screens/admin_page.dart';
import 'package:darimmo/features/auth/presentation/screens/bienvenue_page.dart';
import 'package:darimmo/features/auth/presentation/screens/connexion_page.dart';
import 'package:darimmo/features/auth/presentation/screens/inscription_page.dart';
import 'package:darimmo/features/chat/presentation/screens/conversations_page.dart';
import 'package:darimmo/features/chat/presentation/screens/discussion_page.dart';
import 'package:darimmo/features/detail/presentation/screens/detail_annonce_page.dart';
import 'package:darimmo/features/favorites/presentation/screens/favoris_page.dart';
import 'package:darimmo/features/map/presentation/screens/carte_page.dart';
import 'package:darimmo/features/profile/presentation/screens/profil_page.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/presentation/screens/mes_annonces_page.dart';
import 'package:darimmo/features/publish/presentation/screens/publier_annonce_page.dart';
import 'package:darimmo/features/search/presentation/screens/accueil_page.dart' show AccueilPage;

/// Pages qu'un visiteur sans compte peut voir (3.1 « En tant que visiteur… »).
/// La RLS autorise le rôle anon à lire les annonces publiées.
bool pageVisiteur(String lieu) => lieu == '/accueil' || lieu == '/carte' || lieu.startsWith('/annonces/');

GoRouter creerRouteur(Services s, {GlobalKey<NavigatorState>? cleNavigateur, String? initiale}) {
  PublierAnnoncePage formulaire({EditionAnnonce? edition}) => PublierAnnoncePage(
        repository: s.annonces,
        photosRepository: s.photos,
        choisirPhotos: s.choisirPhotos,
        geocodage: s.geocodage,
        localisation: s.localisation,
        afficherTuiles: s.afficherTuilesCarte,
        edition: edition,
      );

  return GoRouter(
    navigatorKey: cleNavigateur,
    // Au lancement : accueil si la session est conservée (2.2), sinon bienvenue (A1).
    initialLocation: initiale ?? (s.auth.estConnecte ? '/accueil' : '/bienvenue'),
    refreshListenable: s.auth, // connexion / déconnexion -> redirect recalculé
    redirect: (context, etat) {
      final lieu = etat.matchedLocation;
      final pageCompte = lieu.startsWith('/bienvenue'); // bienvenue, connexion, inscription
      if (s.auth.estConnecte) return pageCompte ? '/accueil' : null;
      if (pageCompte || pageVisiteur(lieu)) return null;
      return '/bienvenue'; // favoris, messages, profil, publier… demandent un compte
    },
    routes: [
      // Connexion et inscription sont « sous » la bienvenue : le bouton
      // retour du téléphone y ramène au lieu de fermer l'app.
      GoRoute(
        path: '/bienvenue',
        builder: (_, _) => BienvenuePage(
          onCreerCompte: (context) => context.go('/bienvenue/inscription'),
          onSeConnecter: (context) => context.go('/bienvenue/connexion'),
          onContinuerSansCompte: (context) => context.go('/accueil'),
        ),
        routes: [
          GoRoute(
            path: 'connexion',
            builder: (_, etat) => ConnexionPage(
              // Nouvelle clé si un email est transmis : les champs repartent de lui.
              key: ValueKey(etat.extra),
              auth: s.auth,
              emailInitial: etat.extra as String?,
              apresConnexion: () async => s.push?.enregistrer(),
              onCreerCompte: (context) => context.push('/bienvenue/inscription'),
            ),
          ),
          GoRoute(
            path: 'inscription',
            builder: (_, _) => InscriptionPage(
              auth: s.auth,
              apresConnexion: () async => s.push?.enregistrer(),
              onSeConnecter: (context, email) => context.go('/bienvenue/connexion', extra: email),
            ),
          ),
        ],
      ),

      // ----- Onglets (barre du bas) : chacun garde son historique
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => NavigationPrincipale(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accueil',
              builder: (_, _) => AccueilPage(
                repository: s.recherche,
                onOuvrir: (context, a) => context.push('/annonces/${a.id}'),
                onVoirCarte: (context) => context.push('/carte'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/favoris', builder: (_, _) => const FavorisPage())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              builder: (_, _) => ConversationsPage(
                repository: s.conversations,
                onOuvrir: (context, c) => context.push('/messages/${c.id}', extra: c.nomAffiche),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profil',
              builder: (_, _) => ProfilPage(email: s.auth.email, onDeconnexion: s.deconnecter),
            ),
          ]),
        ],
      ),

      // ----- Écrans plein écran (par-dessus les onglets)
      GoRoute(
        path: '/messages/:id',
        builder: (_, etat) => DiscussionPage(
              repository: s.chat,
              idConversation: etat.pathParameters['id']!,
              titre: etat.extra as String?,
              onVoirAnnonce: (context, idAnnonce) => context.push('/annonces/$idAnnonce'),
            ),
      ),
      GoRoute(path: '/annonces/:id', builder: (_, etat) => DetailAnnoncePage(idAnnonce: etat.pathParameters['id']!)),
      GoRoute(path: '/carte', builder: (_, _) => const CartePage()),
      GoRoute(path: '/publier', builder: (_, _) => formulaire()),
      GoRoute(
        path: '/mes-annonces',
        builder: (_, _) => MesAnnoncesPage(
          repository: s.mesAnnonces,
          onPublier: (context) => context.push('/publier'),
          onModifier: (context, edition) => context.push<Annonce>('/mes-annonces/modifier', extra: edition),
        ),
      ),
      GoRoute(
        path: '/mes-annonces/modifier',
        builder: (_, etat) => formulaire(edition: etat.extra as EditionAnnonce),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminPage()),
    ],
  );
}
