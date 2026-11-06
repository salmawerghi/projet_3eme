-- =====================================================================
-- DarImmo - Règles de sécurité (Row Level Security)
-- À exécuter après 02_fonctions.sql
--
-- Principe : RLS activé sur TOUTES les tables. Sans politique, rien n'est
-- autorisé. Chaque politique ci-dessous ouvre un droit précis.
-- Rôles Supabase : "anon" = visiteur non connecté, "authenticated" = connecté.
-- =====================================================================

alter table public.profiles      enable row level security;
alter table public.device_tokens enable row level security;
alter table public.annonces      enable row level security;
alter table public.photos        enable row level security;
alter table public.favoris       enable row level security;
alter table public.conversations enable row level security;
alter table public.messages      enable row level security;
alter table public.alertes       enable row level security;
alter table public.signalements  enable row level security;

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
create policy "profils visibles par tous"
  on public.profiles for select
  to anon, authenticated
  using (true);

create policy "chacun modifie son profil, l'admin modifie tout"
  on public.profiles for update
  to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());
-- (rôle et blocage protégés par le trigger profiles_proteger)

-- ---------------------------------------------------------------------
-- device_tokens : chacun gère ses jetons
-- ---------------------------------------------------------------------
create policy "jetons : propriétaire"
  on public.device_tokens for all
  to authenticated
  using (id_user = auth.uid())
  with check (id_user = auth.uid());

-- ---------------------------------------------------------------------
-- annonces
-- ---------------------------------------------------------------------
create policy "annonces publiées visibles par tous, les siennes par l'annonceur, tout par l'admin"
  on public.annonces for select
  to anon, authenticated
  using (statut = 'publiee' or id_annonceur = auth.uid() or public.is_admin());

create policy "un utilisateur non bloqué publie"
  on public.annonces for insert
  to authenticated
  with check (id_annonceur = auth.uid() and not public.est_bloque());

create policy "l'annonceur modifie ses annonces, l'admin modère"
  on public.annonces for update
  to authenticated
  using ((id_annonceur = auth.uid() and not public.est_bloque()) or public.is_admin())
  with check ((id_annonceur = auth.uid() and not public.est_bloque()) or public.is_admin());
-- (transitions de statut contrôlées par le trigger annonces_statut)

create policy "l'annonceur ou l'admin supprime"
  on public.annonces for delete
  to authenticated
  using (id_annonceur = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------
-- photos : visibles si l'annonce est visible ; gérées par l'annonceur
-- ---------------------------------------------------------------------
create policy "photos visibles avec leur annonce"
  on public.photos for select
  to anon, authenticated
  using (exists (select 1 from public.annonces a where a.id = id_annonce));

create policy "l'annonceur ajoute des photos"
  on public.photos for insert
  to authenticated
  with check (exists (select 1 from public.annonces a
                      where a.id = id_annonce and a.id_annonceur = auth.uid()));

create policy "l'annonceur modifie ses photos"
  on public.photos for update
  to authenticated
  using (exists (select 1 from public.annonces a
                 where a.id = id_annonce and a.id_annonceur = auth.uid()))
  with check (exists (select 1 from public.annonces a
                      where a.id = id_annonce and a.id_annonceur = auth.uid()));

create policy "l'annonceur ou l'admin supprime des photos"
  on public.photos for delete
  to authenticated
  using (public.is_admin() or exists (select 1 from public.annonces a
                 where a.id = id_annonce and a.id_annonceur = auth.uid()));

-- ---------------------------------------------------------------------
-- favoris : chacun les siens
-- ---------------------------------------------------------------------
create policy "favoris : lecture propriétaire"
  on public.favoris for select to authenticated
  using (id_user = auth.uid());

create policy "favoris : ajout propriétaire"
  on public.favoris for insert to authenticated
  with check (id_user = auth.uid());

create policy "favoris : retrait propriétaire"
  on public.favoris for delete to authenticated
  using (id_user = auth.uid());

-- ---------------------------------------------------------------------
-- conversations : uniquement les deux participants
-- (création normale via la fonction ouvrir_conversation)
-- ---------------------------------------------------------------------
create policy "conversations : participants"
  on public.conversations for select to authenticated
  using (auth.uid() in (id_acheteur, id_vendeur));

create policy "conversations : l'acheteur contacte l'annonceur d'une annonce publiée"
  on public.conversations for insert to authenticated
  with check (
    id_acheteur = auth.uid()
    and not public.est_bloque()
    and exists (select 1 from public.annonces a
                where a.id = id_annonce
                  and a.id_annonceur = id_vendeur
                  and a.statut = 'publiee')
  );

-- ---------------------------------------------------------------------
-- messages : lecture et envoi par les participants uniquement
-- (pas de modification directe : voir marquer_conversation_lue)
-- ---------------------------------------------------------------------
create policy "messages : lecture participants"
  on public.messages for select to authenticated
  using (exists (select 1 from public.conversations c
                 where c.id = id_conversation
                   and auth.uid() in (c.id_acheteur, c.id_vendeur)));

create policy "messages : envoi par un participant non bloqué"
  on public.messages for insert to authenticated
  with check (
    id_expediteur = auth.uid()
    and not public.est_bloque()
    and exists (select 1 from public.conversations c
                where c.id = id_conversation
                  and auth.uid() in (c.id_acheteur, c.id_vendeur))
  );

-- ---------------------------------------------------------------------
-- alertes : chacun les siennes
-- ---------------------------------------------------------------------
create policy "alertes : propriétaire"
  on public.alertes for all to authenticated
  using (id_user = auth.uid())
  with check (id_user = auth.uid());

-- ---------------------------------------------------------------------
-- signalements
-- ---------------------------------------------------------------------
create policy "signalements : l'auteur et l'admin lisent"
  on public.signalements for select to authenticated
  using (id_user = auth.uid() or public.is_admin());

create policy "signalements : un utilisateur connecté signale"
  on public.signalements for insert to authenticated
  with check (id_user = auth.uid() and statut = 'en_attente');

create policy "signalements : l'admin traite"
  on public.signalements for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());
