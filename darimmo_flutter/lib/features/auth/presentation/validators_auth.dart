// =====================================================================
// DarImmo - [2.1] Règles de validation de l'inscription (membre A)
//
// Critères d'acceptation : nom, email valide, mot de passe d'au moins
// 8 caractères. Le téléphone (maquette A3) est facultatif.
// Chaque fonction renvoie null si la valeur est correcte, sinon le message
// à afficher sous le champ (format attendu par TextFormField).
// =====================================================================

const motDePasseMin = 8;
const nomMax = 80;

final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

String? validerNom(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Le nom est obligatoire';
  if (t.length < 2) return 'Nom trop court';
  if (t.length > nomMax) return 'Au plus $nomMax caractères';
  return null;
}

String? validerEmail(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'L’adresse email est obligatoire';
  if (!_regexEmail.hasMatch(t)) return 'Adresse email invalide (ex : nom@gmail.com)';
  return null;
}

String? validerMotDePasse(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return 'Le mot de passe est obligatoire';
  if (t.length < motDePasseMin) return 'Au moins $motDePasseMin caractères';
  return null;
}

/// « 22 345 678 » -> « +21622345678 ». null si vide ou invalide.
String? normaliserTelephone(String? v) {
  var chiffres = (v ?? '').replaceAll(RegExp(r'[\s.\-]'), '');
  if (chiffres.startsWith('+216')) chiffres = chiffres.substring(4);
  if (chiffres.startsWith('00216')) chiffres = chiffres.substring(5);
  if (!RegExp(r'^\d{8}$').hasMatch(chiffres)) return null;
  return '+216$chiffres';
}

/// Facultatif : vide = correct.
String? validerTelephone(String? v) {
  if ((v ?? '').trim().isEmpty) return null;
  if (normaliserTelephone(v) == null) return 'Numéro tunisien à 8 chiffres (ex : 22 345 678)';
  return null;
}

/// Indicateur de la maquette A3 (4 barres). Purement informatif :
/// seul le minimum de 8 caractères est obligatoire.
enum ForceMotDePasse {
  vide(0, ''),
  tropCourt(1, 'Trop court'),
  faible(1, 'Mot de passe faible'),
  moyen(2, 'Mot de passe moyen'),
  bon(3, 'Bon mot de passe'),
  solide(4, 'Mot de passe solide');

  const ForceMotDePasse(this.barres, this.libelle);
  final int barres;
  final String libelle;
}

ForceMotDePasse evaluerMotDePasse(String mdp) {
  if (mdp.isEmpty) return ForceMotDePasse.vide;
  if (mdp.length < motDePasseMin) return ForceMotDePasse.tropCourt;
  var points = 0;
  if (RegExp(r'[a-z]').hasMatch(mdp) && RegExp(r'[A-Z]').hasMatch(mdp)) points++;
  if (RegExp(r'\d').hasMatch(mdp)) points++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(mdp) || mdp.length >= 12) points++;
  return switch (points) {
    0 => ForceMotDePasse.faible,
    1 => ForceMotDePasse.moyen,
    2 => ForceMotDePasse.bon,
    _ => ForceMotDePasse.solide,
  };
}
