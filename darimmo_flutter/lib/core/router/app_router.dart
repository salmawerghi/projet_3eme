// =====================================================================
// DarImmo - Navigation (tâche 1.6) : go_router
//
// Toutes les routes de l'application sont ici. Pour brancher son écran :
// remplacer l'écran « BientotDisponible » de sa route par le vrai.
//
//   /connexion                      A  2.1 / 2.2 (provisoire)
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
import 'package:darimmo/features/auth/presentation/screens/connexion_page.dart';
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

GoRouter creerRouteur(Services s, {GlobalKey<NavigatorState>? cleNavigateur, String initiale = '/accueil'}) {
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
    initialLocation: initiale,
    refreshListenable: s.auth, // connexion / déconnexion -> redirect recalculé
    redirect: (context, etat) {
      final surConnexion = etat.matchedLocation == '/connexion';
      if (!s.auth.estConnecte) return surConnexion ? null : '/connexion';
      if (surConnexion) return '/accueil';
      return null;
    },
    routes: [
      GoRoute(
        path: '/connexion',
        builder: (_, _) => ConnexionPage(auth: s.auth, apresConnexion: () async => s.push?.enregistrer()),
      ),

      // ----- Onglets (barre du bas) : chacun garde son historique
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => NavigationPrincipale(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/accueil', builder: (_, _) => const AccueilPage())]),
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
