-- =====================================================================
-- DarImmo - Stockage des fichiers et temps réel
-- À exécuter après 03_rls.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- Buckets (publics en lecture : les URL des photos s'affichent sans jeton)
--   annonces-photos : fichiers rangés sous "<id_annonce>/<nom>.jpg"
--   avatars         : fichiers rangés sous "<id_user>/<nom>.jpg"
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('annonces-photos', 'annonces-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars',         'avatars',         true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- ----- annonces-photos : seul l'annonceur écrit dans le dossier de son annonce
create policy "photos annonce : envoi par l'annonceur"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'annonces-photos'
    and exists (select 1 from public.annonces a
                where a.id::text = (storage.foldername(name))[1]
                  and a.id_annonceur = auth.uid())
  );

create policy "photos annonce : remplacement par l'annonceur"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'annonces-photos'
    and exists (select 1 from public.annonces a
                where a.id::text = (storage.foldername(name))[1]
                  and a.id_annonceur = auth.uid())
  );

create policy "photos annonce : suppression par l'annonceur ou l'admin"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'annonces-photos'
    and (public.is_admin() or exists (select 1 from public.annonces a
                where a.id::text = (storage.foldername(name))[1]
                  and a.id_annonceur = auth.uid()))
  );

-- [6.3] Lecture des fichiers par l'annonceur (ou l'admin).
-- Nécessaire à l'API Storage pour supprimer (remove = SELECT + DELETE) et
-- pour remplacer un fichier (upsert). L'affichage public des photos passe par
-- l'URL publique du bucket, qui n'utilise pas cette règle.
create policy "photos annonce : lecture par l'annonceur ou l'admin"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'annonces-photos'
    and (public.is_admin() or exists (select 1 from public.annonces a
                where a.id::text = (storage.foldername(name))[1]
                  and a.id_annonceur = auth.uid()))
  );

-- ----- avatars : chacun écrit dans son propre dossier
create policy "avatars : envoi dans son dossier"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars : remplacement dans son dossier"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars : suppression dans son dossier"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
-- Temps réel (story 7.2) : diffuser les nouveaux messages et la mise à
-- jour des conversations. Supabase Realtime applique les règles RLS :
-- un utilisateur ne reçoit que les messages de ses conversations.
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
