// =====================================================================
// DarImmo - [6.1] Règles de validation du formulaire de publication
// Membre C
//
// Mêmes limites que les contraintes CHECK de public.annonces :
//   titre 3..120 caractères, prix > 0, surface > 0, nb_pieces 0..50,
//   description <= 5000 caractères, ville obligatoire.
// Chaque fonction renvoie null si la valeur est correcte, sinon le message
// d'erreur à afficher sous le champ (format attendu par TextFormField).
// =====================================================================

const titreMin = 3;
const titreMax = 120;
const descriptionMax = 5000;
const piecesMax = 50;
const prixMax = 9999999999.99; // numeric(12, 2)
const surfaceMax = 999999.99; // numeric(8, 2)

/// Transforme « 385 000 », « 385000 » ou « 98,5 » en nombre.
/// Renvoie null si le texte n'est pas un nombre.
double? lireNombre(String? texte) {
  if (texte == null) return null;
  final propre = texte.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');
  if (propre.isEmpty) return null;
  return double.tryParse(propre);
}

String? validerTitre(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Le titre est obligatoire';
  if (t.length < titreMin) return 'Au moins $titreMin caractères';
  if (t.length > titreMax) return 'Au plus $titreMax caractères';
  return null;
}

String? validerPrix(String? v) {
  if (v == null || v.trim().isEmpty) return 'Le prix est obligatoire';
  final n = lireNombre(v);
  if (n == null) return 'Entrez un nombre (ex : 385 000)';
  if (n <= 0) return 'Le prix doit être supérieur à 0';
  if (n > prixMax) return 'Prix trop élevé';
  return null;
}

String? validerSurface(String? v) {
  if (v == null || v.trim().isEmpty) return 'La surface est obligatoire';
  final n = lireNombre(v);
  if (n == null) return 'Entrez un nombre (ex : 120)';
  if (n <= 0) return 'La surface doit être supérieure à 0';
  if (n > surfaceMax) return 'Surface trop grande';
  return null;
}

String? validerVille(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'La ville est obligatoire';
  if (t.length < 2) return 'Nom de ville trop court';
  return null;
}

String? validerDescription(String? v) {
  if ((v ?? '').length > descriptionMax) return 'Au plus $descriptionMax caractères';
  return null;
}

/// nb_pieces : 1 à 50 pour un logement ou un local, 0 pour un terrain.
String? validerPieces(int nb, {required bool aDesPieces}) {
  if (!aDesPieces) return null;
  if (nb < 1) return 'Au moins 1 pièce';
  if (nb > piecesMax) return 'Au plus $piecesMax pièces';
  return null;
}
