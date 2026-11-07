// =====================================================================
// DarImmo - [6.2] Ajouter des photos : modèles
// Membre C
//
// PhotoChoisie     : image prise dans la galerie (déjà compressée), pas encore envoyée
// PhotoEnregistree : ligne de public.photos (fichier dans le bucket annonces-photos)
// TuilePhoto       : une case de la grille de l'écran (maquette C2), avec son état
// =====================================================================
import 'dart:typed_data';

/// Nombre maximum de photos par annonce (contrainte CHECK ordre 0..9).
const photosMax = 10;

/// Taille maximum d'un fichier (file_size_limit du bucket : 5 Mo).
const tailleMaxOctets = 5 * 1024 * 1024;

class PhotoChoisie {
  const PhotoChoisie({required this.octets, required this.nom});
  final Uint8List octets;
  final String nom;

  String get extension {
    final n = nom.toLowerCase();
    if (n.endsWith('.png')) return 'png';
    if (n.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  /// Types acceptés par le bucket : image/jpeg, image/png, image/webp.
  String get typeMime => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}

class PhotoEnregistree {
  const PhotoEnregistree({
    required this.id,
    required this.idAnnonce,
    required this.chemin,
    required this.url,
    required this.ordre,
  });

  final String id;
  final String idAnnonce;

  /// « `<id_annonce>/<nom>.jpg` » dans le bucket (« seed/... » pour les photos de démo).
  final String chemin;
  final String url;
  final int ordre;

  static const colonnes = 'id, id_annonce, chemin_storage, url, ordre';

  factory PhotoEnregistree.depuisLigne(Map<String, dynamic> l) => PhotoEnregistree(
        id: l['id'] as String,
        idAnnonce: l['id_annonce'] as String,
        chemin: l['chemin_storage'] as String,
        url: l['url'] as String,
        ordre: l['ordre'] as int,
      );

  PhotoEnregistree avecOrdre(int o) =>
      PhotoEnregistree(id: id, idAnnonce: idAnnonce, chemin: chemin, url: url, ordre: o);

  /// Le fichier est-il dans le dossier de l'annonce (donc à effacer du stockage) ?
  bool get dansLeBucket => chemin.startsWith('$idAnnonce/');
}

enum EtatPhoto { envoi, envoyee, echec }

/// Une case de la grille. Mutable : seul le ViewModel la modifie.
class TuilePhoto {
  TuilePhoto.locale(PhotoChoisie this.choisie)
      : cle = 'locale-${_compteur++}',
        etat = EtatPhoto.envoi;

  TuilePhoto.enregistree(PhotoEnregistree this.enregistree)
      : cle = enregistree.id,
        choisie = null,
        etat = EtatPhoto.envoyee;

  static int _compteur = 0;

  /// Identifiant stable pour Flutter (Key), même avant l'envoi.
  final String cle;

  /// Image choisie dans la galerie (aperçu avant / pendant l'envoi). Null pour
  /// une photo déjà en ligne quand l'écran s'ouvre.
  final PhotoChoisie? choisie;

  /// Ligne de public.photos, une fois l'envoi réussi.
  PhotoEnregistree? enregistree;

  EtatPhoto etat;
  String? erreur;

  /// L'utilisateur a retiré la case pendant que son envoi était en cours.
  bool retiree = false;
}
