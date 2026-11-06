-- =====================================================================
-- DarImmo - [1.3] Schéma de base de données (PostgreSQL / Supabase)
-- Auteur : membre C (Tech Lead BDD)        Relecture : membre A
--
-- Ordre d'exécution dans Supabase (SQL Editor) :
--   01_schema.sql  ->  02_fonctions.sql  ->  03_rls.sql  ->  04_storage_realtime.sql
--   puis 05_seed.sql (données de test, voir les instructions dans le fichier)
--
-- Le script est ré-exécutable sur une base VIDE. Pour repartir de zéro,
-- exécuter d'abord 00_reset.sql.
-- =====================================================================

-- PostGIS (requêtes géographiques : « autour de moi », distance).
-- Dans Supabase, les extensions vivent dans le schéma "extensions".
create extension if not exists postgis with schema extensions;

-- ---------------------------------------------------------------------
-- 1. Types énumérés
-- ---------------------------------------------------------------------
create type public.role_utilisateur  as enum ('utilisateur', 'admin');
create type public.type_bien         as enum ('appartement', 'villa', 'terrain', 'local');
create type public.type_offre        as enum ('vente', 'location');
create type public.statut_annonce    as enum ('brouillon', 'en_attente', 'publiee', 'rejetee', 'vendue', 'louee', 'masquee');
create type public.statut_signalement as enum ('en_attente', 'traite', 'classe');
create type public.plateforme        as enum ('android', 'ios');

-- ---------------------------------------------------------------------
-- 2. profiles : données publiques d'un utilisateur
--    Le compte (email, mot de passe) est géré par Supabase Auth (auth.users).
--    Une ligne profiles est créée automatiquement à l'inscription (trigger).
--    « Annonceur » n'est pas un rôle : tout utilisateur peut publier.
-- ---------------------------------------------------------------------
create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  nom               text not null default '',
  email             text,
  telephone         text,
  photo_url         text,
  role              public.role_utilisateur not null default 'utilisateur',
  bloque            boolean not null default false,
  date_inscription  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. device_tokens : jetons FCM (un utilisateur peut avoir plusieurs appareils)
-- ---------------------------------------------------------------------
create table public.device_tokens (
  id          bigint generated always as identity primary key,
  id_user     uuid not null references public.profiles (id) on delete cascade,
  token       text not null unique,
  plateforme  public.plateforme not null default 'android',
  date_maj    timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (id_user);

-- ---------------------------------------------------------------------
-- 4. annonces
--    Les champs métier peuvent être vides UNIQUEMENT pour un brouillon (bonus 6.6).
--    "position" est calculée automatiquement à partir de latitude/longitude (trigger).
-- ---------------------------------------------------------------------
create table public.annonces (
  id             uuid primary key default gen_random_uuid(),
  titre          text not null check (char_length(titre) between 3 and 120),
  description    text check (char_length(description) <= 5000),
  type_bien      public.type_bien,
  type_offre     public.type_offre,
  prix           numeric(12, 2) check (prix > 0),
  surface        numeric(8, 2)  check (surface > 0),
  nb_pieces      smallint       check (nb_pieces between 0 and 50),
  adresse        text,
  ville          text,
  latitude       double precision check (latitude  between -90  and 90),
  longitude      double precision check (longitude between -180 and 180),
  position       extensions.geography(Point, 4326),
  statut         public.statut_annonce not null default 'en_attente',
  motif_rejet    text,
  id_annonceur   uuid not null references public.profiles (id) on delete cascade,
  date_creation  timestamptz not null default now(),
  date_maj       timestamptz not null default now(),

  -- Une annonce non brouillon doit être complète
  constraint annonce_complete check (
    statut = 'brouillon' or (
      type_bien is not null and type_offre is not null and prix is not null
      and surface is not null and nb_pieces is not null and ville is not null
    )
  ),
  -- Latitude et longitude vont ensemble
  constraint coordonnees_completes check ((latitude is null) = (longitude is null))
);
create index annonces_position_idx   on public.annonces using gist (position);
create index annonces_recherche_idx  on public.annonces (statut, ville, type_bien, type_offre, prix);
create index annonces_annonceur_idx  on public.annonces (id_annonceur);
create index annonces_date_idx       on public.annonces (date_creation desc);

-- ---------------------------------------------------------------------
-- 5. photos : 10 photos maximum par annonce (ordre de 0 à 9, unique)
--    La contrainte d'unicité est DEFERRABLE pour pouvoir réordonner
--    les photos en une seule requête (fonction reordonner_photos).
-- ---------------------------------------------------------------------
create table public.photos (
  id              uuid primary key default gen_random_uuid(),
  id_annonce      uuid not null references public.annonces (id) on delete cascade,
  chemin_storage  text not null,             -- ex : "<id_annonce>/<uuid>.jpg" dans le bucket annonces-photos
  url             text not null,             -- URL publique
  ordre           smallint not null check (ordre between 0 and 9),
  constraint photos_ordre_unique unique (id_annonce, ordre) deferrable initially immediate
);

-- ---------------------------------------------------------------------
-- 6. favoris (N-N profils <-> annonces)
-- ---------------------------------------------------------------------
create table public.favoris (
  id_user     uuid not null references public.profiles (id) on delete cascade,
  id_annonce  uuid not null references public.annonces (id) on delete cascade,
  date        timestamptz not null default now(),
  primary key (id_user, id_annonce)
);
create index favoris_annonce_idx on public.favoris (id_annonce);

-- ---------------------------------------------------------------------
-- 7. conversations : un acheteur et un vendeur autour d'une annonce
--    Une seule conversation par (annonce, acheteur) -> story 7.1 « reprend l'existante ».
--    Si l'annonce est supprimée, la conversation est conservée (id_annonce = null).
-- ---------------------------------------------------------------------
create table public.conversations (
  id                    uuid primary key default gen_random_uuid(),
  id_annonce            uuid references public.annonces (id) on delete set null,
  id_acheteur           uuid not null references public.profiles (id) on delete cascade,
  id_vendeur            uuid not null references public.profiles (id) on delete cascade,
  date_creation         timestamptz not null default now(),
  date_dernier_message  timestamptz not null default now(),
  constraint conversation_unique unique (id_annonce, id_acheteur),
  constraint pas_soi_meme check (id_acheteur <> id_vendeur)
);
create index conversations_acheteur_idx on public.conversations (id_acheteur, date_dernier_message desc);
create index conversations_vendeur_idx  on public.conversations (id_vendeur,  date_dernier_message desc);

-- ---------------------------------------------------------------------
-- 8. messages
-- ---------------------------------------------------------------------
create table public.messages (
  id               bigint generated always as identity primary key,
  id_conversation  uuid not null references public.conversations (id) on delete cascade,
  id_expediteur    uuid not null references public.profiles (id) on delete cascade,
  contenu          text not null check (char_length(contenu) between 1 and 2000),
  date_envoi       timestamptz not null default now(),
  lu               boolean not null default false
);
create index messages_conversation_idx on public.messages (id_conversation, date_envoi);

-- ---------------------------------------------------------------------
-- 9. alertes (bonus 3.6 / 8.3) : critères de recherche enregistrés
-- ---------------------------------------------------------------------
create table public.alertes (
  id             bigint generated always as identity primary key,
  id_user        uuid not null references public.profiles (id) on delete cascade,
  nom            text not null default 'Ma recherche',
  criteres       jsonb not null default '{}'::jsonb,   -- ex : {"ville":"Sfax","prix_max":250000}
  active         boolean not null default true,
  date_creation  timestamptz not null default now()
);
create index alertes_user_idx on public.alertes (id_user);

-- ---------------------------------------------------------------------
-- 10. signalements : un seul par utilisateur et par annonce
-- ---------------------------------------------------------------------
create table public.signalements (
  id          bigint generated always as identity primary key,
  id_annonce  uuid not null references public.annonces (id) on delete cascade,
  id_user     uuid not null references public.profiles (id) on delete cascade,
  motif       text not null check (char_length(motif) between 3 and 500),
  statut      public.statut_signalement not null default 'en_attente',
  date        timestamptz not null default now(),
  constraint signalement_unique unique (id_user, id_annonce)
);
create index signalements_statut_idx on public.signalements (statut, date);
