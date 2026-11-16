-- DarImmo - Ajoute le choix acheteur/vendeur aux profils existants.
-- À exécuter une fois dans Supabase SQL Editor avant de tester la nouvelle inscription.

alter table public.profiles
  add column type_compte text not null default 'acheteur'
    check (type_compte in ('acheteur', 'vendeur'));

create or replace function public.creer_profil()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, nom, telephone, type_compte)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nom', ''),
    nullif(new.raw_user_meta_data ->> 'telephone', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'type_compte', ''), 'acheteur')
  );
  return new;
end;
$$;