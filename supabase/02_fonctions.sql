-- =====================================================================
-- DarImmo - Fonctions, triggers et fonctions RPC
-- À exécuter après 01_schema.sql
--
-- Rappel : auth.uid() = id de l'utilisateur connecté.
-- Dans le SQL Editor (ou avec la clé service_role), auth.uid() est NULL :
-- les triggers de contrôle laissent alors tout passer (utile pour le seed).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Fonctions utilitaires (SECURITY DEFINER pour éviter la récursion RLS)
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select p.role = 'admin' from public.profiles p where p.id = auth.uid()), false);
$$;

create or replace function public.est_bloque()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select p.bloque from public.profiles p where p.id = auth.uid()), false);
$$;

-- ---------------------------------------------------------------------
-- Trigger : création du profil à l'inscription (story 2.1)
-- L'application envoie le nom (et le téléphone facultatif) dans les métadonnées :
--   supabase.auth.signUp(email, password, data: {'nom': 'Ali', 'telephone': '+21622345678'})
-- ---------------------------------------------------------------------
create or replace function public.creer_profil()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, nom, telephone)
  values (new.id, new.email,
          left(trim(coalesce(new.raw_user_meta_data ->> 'nom', '')), 80),
          nullif(trim(coalesce(new.raw_user_meta_data ->> 'telephone', '')), ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.creer_profil();

-- ---------------------------------------------------------------------
-- Trigger : un utilisateur ne peut pas modifier son rôle ni son blocage
-- ---------------------------------------------------------------------
create or replace function public.proteger_profil()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.role   := old.role;
    new.bloque := old.bloque;
  end if;
  new.id := old.id;
  return new;
end;
$$;

create trigger profiles_proteger
  before update on public.profiles
  for each row execute function public.proteger_profil();

-- ---------------------------------------------------------------------
-- Trigger : position PostGIS calculée depuis latitude / longitude
-- ---------------------------------------------------------------------
create or replace function public.calculer_position()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.latitude is null or new.longitude is null then
    new.position := null;
  else
    new.position := extensions.st_setsrid(
      extensions.st_makepoint(new.longitude, new.latitude), 4326
    )::extensions.geography;
  end if;
  return new;
end;
$$;

create trigger annonces_position
  before insert or update of latitude, longitude on public.annonces
  for each row execute function public.calculer_position();

-- ---------------------------------------------------------------------
-- Trigger : cycle de vie du statut d'une annonce (stories 6.1, 6.3, 6.5, 9.2)
--
--   Annonceur :  brouillon -> en_attente      (envoi)
--                rejetee   -> en_attente      (renvoi après correction)
--                publiee   -> vendue | louee
--                publiee + contenu modifié -> en_attente (re-modération)
--   Admin     :  tout est permis (valider, rejeter avec motif, masquer)
-- ---------------------------------------------------------------------
create or replace function public.controler_statut_annonce()
returns trigger
language plpgsql set search_path = ''
as $$
declare
  contenu_modifie boolean;
begin
  new.date_maj := now();

  -- SQL Editor / service_role / administrateur : pas de contrôle
  if auth.uid() is null or public.is_admin() then
    if new.statut = 'rejetee' and coalesce(trim(new.motif_rejet), '') = '' then
      raise exception 'Un motif est obligatoire pour rejeter une annonce';
    end if;
    if new.statut in ('en_attente', 'publiee') then
      new.motif_rejet := null;
    end if;
    return new;
  end if;

  -- ----- Annonceur : création
  if tg_op = 'INSERT' then
    new.id_annonceur := auth.uid();
    new.motif_rejet  := null;
    if new.statut <> 'brouillon' then
      new.statut := 'en_attente';
    end if;
    return new;
  end if;

  -- ----- Annonceur : modification
  new.id_annonceur := old.id_annonceur;
  new.motif_rejet  := old.motif_rejet;

  if new.statut is distinct from old.statut then
    if not (
         (old.statut = 'brouillon' and new.statut = 'en_attente')
      or (old.statut = 'rejetee'   and new.statut = 'en_attente')
      or (old.statut = 'publiee'   and new.statut in ('vendue', 'louee'))
    ) then
      raise exception 'Changement de statut non autorisé : % -> %', old.statut, new.statut;
    end if;
    if new.statut = 'en_attente' then
      new.motif_rejet := null;
    end if;
    return new;
  end if;

  -- Statut inchangé : une annonce publiée dont le contenu change repasse en attente
  contenu_modifie :=
    (new.titre, new.description, new.type_bien, new.type_offre, new.prix, new.surface,
     new.nb_pieces, new.adresse, new.ville, new.latitude, new.longitude)
    is distinct from
    (old.titre, old.description, old.type_bien, old.type_offre, old.prix, old.surface,
     old.nb_pieces, old.adresse, old.ville, old.latitude, old.longitude);

  if old.statut = 'publiee' and contenu_modifie then
    new.statut := 'en_attente';
  end if;

  return new;
end;
$$;

create trigger annonces_statut
  before insert or update on public.annonces
  for each row execute function public.controler_statut_annonce();

-- ---------------------------------------------------------------------
-- Trigger : date du dernier message d'une conversation (tri story 7.3)
-- ---------------------------------------------------------------------
create or replace function public.maj_dernier_message()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.conversations
     set date_dernier_message = new.date_envoi
   where id = new.id_conversation;
  return new;
end;
$$;

create trigger messages_dernier_message
  after insert on public.messages
  for each row execute function public.maj_dernier_message();

-- =====================================================================
-- Fonctions RPC appelées par les applications
--   Flutter : supabase.rpc('nom_fonction', params: {...})
--   RN      : supabase.rpc('nom_fonction', {...})
-- =====================================================================

-- ---------------------------------------------------------------------
-- [7.1] Ouvrir (ou reprendre) la conversation avec l'annonceur
-- Retourne l'id de la conversation.
-- ---------------------------------------------------------------------
create or replace function public.ouvrir_conversation(p_annonce uuid)
returns uuid
language plpgsql security invoker set search_path = ''
as $$
declare
  v_vendeur uuid;
  v_conv    uuid;
begin
  if auth.uid() is null then
    raise exception 'Connexion obligatoire';
  end if;

  select a.id_annonceur into v_vendeur
    from public.annonces a
   where a.id = p_annonce and a.statut = 'publiee';

  if v_vendeur is null then
    raise exception 'Annonce introuvable ou non publiée';
  end if;
  if v_vendeur = auth.uid() then
    raise exception 'Vous ne pouvez pas vous contacter vous-même';
  end if;

  insert into public.conversations (id_annonce, id_acheteur, id_vendeur)
  values (p_annonce, auth.uid(), v_vendeur)
  on conflict (id_annonce, id_acheteur) do nothing;

  select c.id into v_conv
    from public.conversations c
   where c.id_annonce = p_annonce and c.id_acheteur = auth.uid();

  return v_conv;
end;
$$;

-- ---------------------------------------------------------------------
-- [7.3] Mes conversations : interlocuteur, annonce, dernier message, non-lus
-- ---------------------------------------------------------------------
create or replace function public.mes_conversations()
returns table (
  id                    uuid,
  id_annonce            uuid,
  titre_annonce         text,
  photo_annonce         text,
  id_interlocuteur      uuid,
  nom_interlocuteur     text,
  photo_interlocuteur   text,
  dernier_message       text,
  date_dernier_message  timestamptz,
  non_lus               bigint
)
language sql stable security invoker set search_path = ''
as $$
  select
    c.id,
    c.id_annonce,
    a.titre,
    (select p.url from public.photos p
      where p.id_annonce = c.id_annonce order by p.ordre limit 1),
    i.id,
    i.nom,
    i.photo_url,
    (select m.contenu from public.messages m
      where m.id_conversation = c.id order by m.date_envoi desc limit 1),
    c.date_dernier_message,
    (select count(*) from public.messages m
      where m.id_conversation = c.id
        and m.id_expediteur <> auth.uid()
        and not m.lu)
  from public.conversations c
  left join public.annonces a on a.id = c.id_annonce
  join public.profiles i
    on i.id = case when c.id_acheteur = auth.uid() then c.id_vendeur else c.id_acheteur end
  where auth.uid() in (c.id_acheteur, c.id_vendeur)
  order by c.date_dernier_message desc;
$$;

-- ---------------------------------------------------------------------
-- [7.3] Marquer comme lus les messages reçus dans une conversation
-- (les messages ne sont pas modifiables directement par le client)
-- ---------------------------------------------------------------------
create or replace function public.marquer_conversation_lue(p_conversation uuid)
returns void
language sql security definer set search_path = ''
as $$
  update public.messages m
     set lu = true
   where m.id_conversation = p_conversation
     and m.id_expediteur <> auth.uid()
     and not m.lu
     and exists (
       select 1 from public.conversations c
        where c.id = p_conversation
          and auth.uid() in (c.id_acheteur, c.id_vendeur)
     );
$$;

-- ---------------------------------------------------------------------
-- [6.2] Réordonner les photos d'une annonce en une seule fois
-- p_ids = ids des photos dans le nouvel ordre
-- ---------------------------------------------------------------------
create or replace function public.reordonner_photos(p_annonce uuid, p_ids uuid[])
returns void
language plpgsql security invoker set search_path = ''
as $$
begin
  set constraints public.photos_ordre_unique deferred;
  update public.photos p
     set ordre = array_position(p_ids, p.id) - 1
   where p.id_annonce = p_annonce
     and p.id = any (p_ids);
end;
$$;

-- ---------------------------------------------------------------------
-- [4.2] (pour B) Annonces publiées autour d'un point, triées par distance
-- ---------------------------------------------------------------------
create or replace function public.annonces_autour(
  p_lat double precision,
  p_lng double precision,
  p_rayon_m integer default 5000
)
returns setof public.annonces
language sql stable security invoker set search_path = ''
as $$
  with centre as (
    select extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography as g
  )
  select a.*
    from public.annonces a, centre
   where a.statut = 'publiee'
     and a.position is not null
     and extensions.st_dwithin(a.position, centre.g, p_rayon_m)
   order by extensions.st_distance(a.position, centre.g);
$$;
