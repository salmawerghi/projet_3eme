-- =====================================================================
-- DarImmo - Remise à zéro (ATTENTION : supprime toutes les données)
-- À utiliser uniquement sur un projet de TEST, avant de ré-exécuter 01 à 05.
-- Les comptes de auth.users ne sont pas supprimés.
-- =====================================================================

-- (les tables supprimées quittent automatiquement la publication Realtime)

drop policy if exists "photos annonce : envoi par l'annonceur"                  on storage.objects;
drop policy if exists "photos annonce : remplacement par l'annonceur"           on storage.objects;
drop policy if exists "photos annonce : suppression par l'annonceur ou l'admin" on storage.objects;
drop policy if exists "avatars : envoi dans son dossier"                        on storage.objects;
drop policy if exists "avatars : remplacement dans son dossier"                 on storage.objects;
drop policy if exists "avatars : suppression dans son dossier"                  on storage.objects;

drop trigger if exists on_auth_user_created on auth.users;

drop table if exists public.signalements, public.alertes, public.messages, public.conversations,
                     public.favoris, public.photos, public.annonces, public.device_tokens,
                     public.profiles cascade;

drop function if exists public.is_admin(), public.est_bloque(), public.creer_profil(),
  public.proteger_profil(), public.calculer_position(), public.controler_statut_annonce(),
  public.maj_dernier_message(), public.ouvrir_conversation(uuid), public.mes_conversations(),
  public.marquer_conversation_lue(uuid), public.reordonner_photos(uuid, uuid[]),
  public.annonces_autour(double precision, double precision, integer) cascade;

drop type if exists public.role_utilisateur, public.type_bien, public.type_offre,
  public.statut_annonce, public.statut_signalement, public.plateforme cascade;

-- Les buckets ne peuvent pas être supprimés en SQL s'ils contiennent des fichiers :
-- les vider depuis Storage dans le tableau de bord si nécessaire.
