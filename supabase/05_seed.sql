-- =====================================================================
-- DarImmo - Données de test (seed)
--
-- AVANT d'exécuter ce fichier, créer 3 comptes dans Supabase :
--   Authentication > Users > Add user > Create new user
--   (cocher « Auto Confirm User »)
--     admin@darimmo.test    mot de passe : Test1234!
--     vendeur@darimmo.test  mot de passe : Test1234!
--     acheteur@darimmo.test mot de passe : Test1234!
-- Leurs profils sont créés automatiquement par le trigger on_auth_user_created.
--
-- Ensuite exécuter ce fichier dans le SQL Editor.
-- =====================================================================

do $$
declare
  v_admin    uuid := (select id from auth.users where email = 'admin@darimmo.test');
  v_vendeur  uuid := (select id from auth.users where email = 'vendeur@darimmo.test');
  v_acheteur uuid := (select id from auth.users where email = 'acheteur@darimmo.test');
  v_annonce  uuid;
  v_conv     uuid;
begin
  if v_admin is null or v_vendeur is null or v_acheteur is null then
    raise exception 'Créer d''abord les 3 comptes de test (voir l''en-tête du fichier)';
  end if;

  -- Profils
  update public.profiles set nom = 'Admin DarImmo', role = 'admin'                  where id = v_admin;
  update public.profiles set nom = 'Sami Vendeur',  telephone = '+216 20 000 001'  where id = v_vendeur;
  update public.profiles set nom = 'Lina Acheteuse', telephone = '+216 20 000 002' where id = v_acheteur;

  -- 20 annonces (18 publiées, 1 en attente, 1 rejetée) appartenant au vendeur
  insert into public.annonces
    (titre, description, type_bien, type_offre, prix, surface, nb_pieces, adresse, ville, latitude, longitude, statut, motif_rejet, id_annonceur)
  values
    ('Appartement S+2 lumineux',      'Proche du centre, 2e étage avec ascenseur.',    'appartement', 'location',    950, 95, 3, 'Rue de Marseille',          'Tunis',     36.8008, 10.1815, 'publiee', null, v_vendeur),
    ('Appartement S+3 vue mer',       'Grande terrasse, parking sous-sol.',            'appartement', 'vente',    420000, 140, 4, 'Avenue Habib Bourguiba',  'La Marsa',  36.8782, 10.3247, 'publiee', null, v_vendeur),
    ('Villa avec piscine',            'Jardin de 500 m², 4 chambres.',                 'villa',       'vente',    950000, 320, 6, 'Route de la Corniche',    'Hammamet',  36.4000, 10.6167, 'publiee', null, v_vendeur),
    ('Studio meublé étudiant',        'Idéal étudiant, proche faculté.',               'appartement', 'location',    450, 35, 1, 'Route de l''Aéroport',     'Sfax',      34.7406, 10.7603, 'publiee', null, v_vendeur),
    ('Terrain constructible',         'Terrain plat, titre bleu.',                     'terrain',     'vente',    120000, 400, 0, 'Zone Chotrana',           'Ariana',    36.8665, 10.1647, 'publiee', null, v_vendeur),
    ('Local commercial centre-ville', 'Vitrine sur rue passante.',                     'local',       'location',   1800, 80, 1, 'Avenue Farhat Hached',    'Sousse',    35.8256, 10.6084, 'publiee', null, v_vendeur),
    ('Appartement S+1 neuf',          'Résidence sécurisée, cuisine équipée.',         'appartement', 'vente',    185000, 70, 2, 'Cité El Khadra',          'Tunis',     36.8325, 10.1830, 'publiee', null, v_vendeur),
    ('Villa familiale',               'Quartier calme, garage double.',                'villa',       'location',   2500, 250, 5, 'El Menzah 6',             'Ariana',    36.8480, 10.1700, 'publiee', null, v_vendeur),
    ('Appartement S+2 Monastir',      'À 5 minutes de la plage.',                      'appartement', 'location',    800, 90, 3, 'Route de la Falaise',     'Monastir',  35.7643, 10.8113, 'publiee', null, v_vendeur),
    ('Terrain agricole',              'Oliviers, accès route goudronnée.',             'terrain',     'vente',     65000, 5000, 0, 'Route de Gremda',        'Sfax',      34.7800, 10.7000, 'publiee', null, v_vendeur),
    ('Local bureau',                  'Open space climatisé, 1er étage.',              'local',       'vente',    310000, 120, 3, 'Centre Urbain Nord',      'Tunis',     36.8460, 10.1960, 'publiee', null, v_vendeur),
    ('Appartement S+3 Nabeul',        'Proche marché, balcon.',                        'appartement', 'vente',    230000, 120, 4, 'Avenue Taieb Mhiri',      'Nabeul',    36.4561, 10.7376, 'publiee', null, v_vendeur),
    ('Duplex moderne',                'Duplex avec mezzanine et terrasse.',            'appartement', 'vente',    540000, 180, 5, 'Les Berges du Lac',       'Tunis',     36.8380, 10.2400, 'publiee', null, v_vendeur),
    ('Villa bord de mer',             'Accès direct à la plage.',                      'villa',       'location',   4000, 280, 6, 'Corniche',                'Bizerte',   37.2744,  9.8739, 'publiee', null, v_vendeur),
    ('Studio centre Sousse',          'Rénové, proche médina.',                        'appartement', 'location',    500, 40, 1, 'Rue de Paris',            'Sousse',    35.8280, 10.6380, 'publiee', null, v_vendeur),
    ('Local commercial Gabès',        'Angle de rue, grande surface.',                 'local',       'location',   1200, 150, 2, 'Avenue Habib Bourguiba',  'Gabès',     33.8815, 10.0982, 'publiee', null, v_vendeur),
    ('Terrain zone touristique',      'Proche hôtels, 1 km de la plage.',              'terrain',     'vente',    480000, 1200, 0, 'Yasmine Hammamet',       'Hammamet',  36.3700, 10.5400, 'publiee', null, v_vendeur),
    ('Appartement S+2 Bizerte',       'Vue sur le vieux port.',                        'appartement', 'vente',    160000, 85, 3, 'Vieux Port',              'Bizerte',   37.2720,  9.8700, 'publiee', null, v_vendeur),
    ('Appartement en attente',        'Annonce à valider par l''administrateur.',      'appartement', 'vente',    200000, 100, 3, 'Rue de Rome',             'Tunis',     36.7990, 10.1800, 'en_attente', null, v_vendeur),
    ('Annonce rejetée (test)',        'Exemple d''annonce rejetée.',                   'villa',       'vente',       1000, 200, 5, 'Adresse inconnue',        'Sfax',      34.7400, 10.7600, 'rejetee', 'Prix incohérent, merci de corriger.', v_vendeur);

  -- Une photo d'illustration par annonce (images publiques de démonstration)
  insert into public.photos (id_annonce, chemin_storage, url, ordre)
  select a.id, 'seed/' || a.id || '.jpg',
         'https://picsum.photos/seed/' || a.id || '/800/600', 0
    from public.annonces a
   where a.id_annonceur = v_vendeur;

  -- Une conversation de démonstration entre l'acheteuse et le vendeur
  select id into v_annonce from public.annonces where titre = 'Appartement S+2 lumineux';
  insert into public.conversations (id_annonce, id_acheteur, id_vendeur)
  values (v_annonce, v_acheteur, v_vendeur)
  returning id into v_conv;

  insert into public.messages (id_conversation, id_expediteur, contenu, date_envoi, lu) values
    (v_conv, v_acheteur, 'Bonjour, l''appartement est-il toujours disponible ?', now() - interval '2 hours', true),
    (v_conv, v_vendeur,  'Bonjour, oui il est disponible. Voulez-vous le visiter ?', now() - interval '1 hour', false);

  -- Un favori et un signalement de démonstration
  insert into public.favoris (id_user, id_annonce) values (v_acheteur, v_annonce);
  insert into public.signalements (id_annonce, id_user, motif)
  select id, v_acheteur, 'Photos ne correspondant pas au bien'
    from public.annonces where titre = 'Studio meublé étudiant';
end;
$$;
