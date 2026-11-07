// =====================================================================
// DarImmo - [7.3] Voir mes conversations : modèle d'une ligne de la liste
// Membre C
//
// Une ligne renvoyée par la fonction SQL public.mes_conversations()
// (02_fonctions.sql) : interlocuteur, annonce, dernier message, non-lus.
// =====================================================================

class ResumeConversation {
  const ResumeConversation({
    required this.id,
    required this.idInterlocuteur,
    required this.nomInterlocuteur,
    required this.dateDernierMessage,
    required this.nonLus,
    this.idAnnonce,
    this.titreAnnonce,
    this.photoAnnonce,
    this.photoInterlocuteur,
    this.dernierMessage,
  });

  final String id;
  final String idInterlocuteur;
  final String nomInterlocuteur;
  final String? photoInterlocuteur;

  /// null si l'annonce a été supprimée (la conversation est conservée).
  final String? idAnnonce;
  final String? titreAnnonce;
  final String? photoAnnonce;

  /// null tant qu'aucun message n'a été envoyé.
  final String? dernierMessage;
  final DateTime dateDernierMessage;

  /// Messages reçus pas encore lus.
  final int nonLus;

  bool get aDesNonLus => nonLus > 0;
  bool get annonceSupprimee => idAnnonce == null;

  /// Nom affiché (le profil peut avoir un nom vide).
  String get nomAffiche => nomInterlocuteur.trim().isEmpty ? 'Utilisateur DarImmo' : nomInterlocuteur.trim();

  /// Initiales pour l'avatar sans photo : « Karim Jaziri » -> « KJ ».
  String get initiales {
    final mots = nomAffiche.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.length >= 2) return (mots[0][0] + mots[1][0]).toUpperCase();
    return nomAffiche.substring(0, nomAffiche.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Recherche « une personne ou un bien » (maquette C7), sans accents ni casse.
  bool correspond(String recherche) {
    final q = sansAccents(recherche.trim().toLowerCase());
    if (q.isEmpty) return true;
    return sansAccents('$nomAffiche ${titreAnnonce ?? ''}'.toLowerCase()).contains(q);
  }

  factory ResumeConversation.depuisLigne(Map<String, dynamic> l) => ResumeConversation(
        id: l['id'] as String,
        idAnnonce: l['id_annonce'] as String?,
        titreAnnonce: l['titre_annonce'] as String?,
        photoAnnonce: l['photo_annonce'] as String?,
        idInterlocuteur: l['id_interlocuteur'] as String,
        nomInterlocuteur: l['nom_interlocuteur'] as String? ?? '',
        photoInterlocuteur: l['photo_interlocuteur'] as String?,
        dernierMessage: l['dernier_message'] as String?,
        dateDernierMessage: DateTime.parse(l['date_dernier_message'] as String).toLocal(),
        nonLus: (l['non_lus'] as num?)?.toInt() ?? 0,
      );
}

String sansAccents(String s) {
  const de = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
  const vers = 'aaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = de.indexOf(c);
    b.write(i < 0 ? c : vers[i]);
  }
  return b.toString();
}

/// Heure de la liste (maquette C7) : « 14:32 » aujourd'hui, « Hier »,
/// « Lun. » cette semaine, sinon « 03/11 » (et « 03/11/25 » une autre année).
String formaterDateConversation(DateTime date, DateTime maintenant) {
  final jour = DateTime(date.year, date.month, date.day);
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final ecart = aujourdhui.difference(jour).inDays;
  String deux(int n) => n.toString().padLeft(2, '0');

  if (ecart <= 0) return '${deux(date.hour)}:${deux(date.minute)}';
  if (ecart == 1) return 'Hier';
  if (ecart < 7) return const ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'][date.weekday - 1];
  final jj = '${deux(date.day)}/${deux(date.month)}';
  return date.year == maintenant.year ? jj : '$jj/${deux(date.year % 100)}';
}

/// Séparateur de jour dans une discussion (maquette C8) : « Aujourd’hui »,
/// « Hier », « Mardi 4 novembre » (+ l'année si ce n'est pas l'année en cours).
/// Sans lui, des messages de jours différents semblent dans le désordre
/// (« 22:32 » puis « 00:18 »…).
String formaterJourDiscussion(DateTime date, DateTime maintenant) {
  final ecart = DateTime(maintenant.year, maintenant.month, maintenant.day)
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (ecart <= 0) return 'Aujourd’hui';
  if (ecart == 1) return 'Hier';
  const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
  final texte = '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
  return date.year == maintenant.year ? texte : '$texte ${date.year}';
}
