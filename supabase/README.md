# DarImmo – Base de données Supabase (ticket [1.3], membre C)

## Fichiers (à exécuter dans cet ordre)

| Fichier | Contenu |
|---|---|
| `00_reset.sql` | Remise à zéro d'un projet de **test** (optionnel) |
| `01_schema.sql` | PostGIS, types énumérés, 9 tables, contraintes, index |
| `02_fonctions.sql` | Triggers (profil, position, statut, dernier message) et fonctions RPC |
| `03_rls.sql` | Règles de sécurité (RLS) de toutes les tables |
| `04_storage_realtime.sql` | Buckets `annonces-photos` et `avatars`, temps réel sur `messages` |
| `05_seed.sql` | Données de test : 3 comptes, 20 annonces, 1 conversation |

## Installation

1. Créer un projet sur supabase.com (région Europe).
2. **SQL Editor** → *New query* → coller `01_schema.sql` → *Run*. Répéter pour 02, 03, 04.
3. **Authentication → Users → Add user** : créer `admin@darimmo.test`, `vendeur@darimmo.test`,
   `acheteur@darimmo.test` (mot de passe `Test1234!`, cocher *Auto Confirm User*).
4. Exécuter `05_seed.sql`.
5. **Table Editor** : vérifier 20 lignes dans `annonces`, 2 dans `messages`.

## Ce que les applications doivent savoir

| Besoin | Appel |
|---|---|
| Inscription avec nom | `auth.signUp(email, password, data: {'nom': ...})` → profil créé automatiquement |
| Liste des annonces | `from('annonces').select('*, photos(url, ordre)')` → seules les annonces `publiee` reviennent pour les autres utilisateurs |
| Publier | `insert` dans `annonces` sans `id_annonceur` ni `statut` (remplis par le trigger) |
| Photos | upload dans `annonces-photos/<id_annonce>/<fichier>.jpg`, puis `insert` dans `photos` |
| Réordonner les photos | `rpc('reordonner_photos', {p_annonce, p_ids})` |
| Mes annonces | `from('annonces').select().eq('id_annonceur', userId)` |
| Marquer vendu | `update({'statut': 'vendue'})` (seulement depuis `publiee`) |
| Contacter l'annonceur | `rpc('ouvrir_conversation', {p_annonce})` → id de conversation |
| Mes conversations | `rpc('mes_conversations')` |
| Messages en direct | canal Realtime `postgres_changes` sur `messages`, filtre `id_conversation=eq.<id>` |
| Marquer comme lu | `rpc('marquer_conversation_lue', {p_conversation})` |
| Autour de moi (B) | `rpc('annonces_autour', {p_lat, p_lng, p_rayon_m})` |

## Cycle de vie d'une annonce (trigger `controler_statut_annonce`)

```
brouillon ──► en_attente ──(admin)──► publiee ──► vendue / louee
                 ▲   │                   │
                 │   └──(admin, motif)──► rejetee
                 └────── renvoi ─────────┘
publiee + contenu modifié par l'annonceur ──► en_attente
admin : peut aussi passer une annonce en masquee (signalement)
```

## Tests de sécurité à faire (avant de donner le script à A)

Dans le SQL Editor, simuler un utilisateur :

```sql
-- se faire passer pour l'acheteuse
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from auth.users where email='acheteur@darimmo.test'),
                    'role','authenticated')::text, true);
set local role authenticated;

select count(*) from public.annonces;          -- attendu : 18 (pas l'annonce en attente ni la rejetée)
update public.annonces set prix = 1 where true; -- attendu : 0 ligne modifiée (pas ses annonces)
select count(*) from public.messages;          -- attendu : 2 (sa conversation)
update public.profiles set role = 'admin' where id = auth.uid();
select role from public.profiles where id = auth.uid();  -- attendu : utilisateur
```

(Sélectionner tout le bloc et l'exécuter d'un coup : `set local` ne vaut que pour la transaction.)

## Limites connues

- Le blocage d'un compte (9.3, membre A) empêche de publier et d'écrire des messages ;
  l'application doit aussi vérifier `profiles.bloque` après la connexion et déconnecter l'utilisateur.
- À la suppression d'une annonce, l'application supprime d'abord ses fichiers du bucket
  (les lignes `photos` sont supprimées automatiquement en cascade).
- L'email et le téléphone des profils sont lisibles par tous (simplicité du MVP).
- L'envoi des notifications push (8.1, 8.2) sera ajouté avec l'Edge Function `send-push` (ticket 1.7).
