# DarImmo – application Flutter (squelette officiel, tâche 1.6)

Application immobilière DarImmo, version Flutter. Backend commun : Supabase
(scripts dans `../supabase/`). Le dossier `../poc_temps_reel/` est l'ancienne
preuve de concept : il reste comme référence, **on code maintenant ici**.

## Lancer l'application

1. Copier `env.example.json` en `env.json` et y mettre l'URL et la clé
   publique (« publishable ») du projet Supabase. `env.json` n'est **jamais**
   envoyé sur GitHub.
2. `flutter pub get`
3. `flutter run --dart-define-from-file=env.json` (web : ajouter `-d chrome`)

Notifications push (Android) : placer le fichier `google-services.json` de
l'app Android **`com.darimmo`** (projet Firebase `darimmo-12b8a`) dans
`android/app/`. Sans ce fichier, l'app fonctionne, mais sans notifications.

## Architecture

```
lib/
  main.dart              initialisation (Supabase, Firebase) puis DarImmoApp
  app.dart               MaterialApp.router + thème
  core/
    config/env.dart      clés lues depuis env.json
    services.dart        UN seul point d'accès aux repositories (remplaçables dans les tests)
    router/              go_router : toutes les routes + barre de navigation à 5 onglets
    theme/               couleurs et thème des maquettes v3 (Sidi Bou Saïd)
    carte/               widget carte OpenStreetMap partagé (CarteDarImmo)
    location/            géocodage (Nominatim) + position GPS
    widgets/             BientotDisponible : écran provisoire d'un module à faire
  features/<module>/
    data/                models/, repositories/ (accès Supabase)
    presentation/        screens/, viewmodels/ (Provider / ChangeNotifier), widgets/
```

Gestion d'état : **Provider** (`ChangeNotifier`), un view model par écran.
Navigation : **go_router** (`context.push('/messages/<id>')`, etc.). Sans
session, toute route redirige vers `/connexion`.

## Modules et responsables

| Module (`lib/features/`) | Route(s) | Responsable | État |
|---|---|---|---|
| `auth` | `/connexion` | A (2.1, 2.2, 2.4) | connexion provisoire (comptes de test) |
| `profile` | `/profil` | A (2.3) | provisoire : e-mail, Mes annonces, déconnexion |
| `admin` | `/admin` | A (9.1 à 9.4) | à faire |
| `search` | `/accueil` | B (3.1, 3.2) | à faire |
| `detail` | `/annonces/:id` | B (3.3, 3.4) | à faire |
| `map` | `/carte` | B (4.1, 4.2) | à faire (widget `core/carte` prêt) |
| `favorites` | `/favoris` | B (5.1, 5.2) | à faire |
| `publish` | `/publier`, `/mes-annonces` | C (6.1 à 6.5) | ✅ fait |
| `chat` | `/messages`, `/messages/:id` | C (7.1 à 7.3) | ✅ 7.3 faite, 7.2 à reprendre, 7.1 attend la 3.3 |
| `notifications` | – | C (8.1, 8.2) | ✅ fait |

Pour commencer un module « à faire » : remplacer le `BientotDisponible` de
l'écran correspondant par le vrai écran. La route existe déjà dans
`core/router/app_router.dart`. Les nouveaux repositories s'ajoutent dans
`core/services.dart`.

## Tests

`flutter test` : aucun test n'utilise le réseau (faux repositories).
`flutter analyze` doit afficher « No issues found! » avant chaque commit.

## Git

Une branche par story (ex. `feat/3.1-liste-annonces`), puis fusion dans `main`.
Ne jamais commiter `env.json` ni `google-services.json`.

## Icône

Logo v3 (arche blanche sur bleu). Après un changement de logo :
`dart run flutter_launcher_icons`.
