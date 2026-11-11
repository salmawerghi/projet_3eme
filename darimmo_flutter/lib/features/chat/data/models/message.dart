// =====================================================================
// DarImmo - [7.2] Échanger en temps réel : un message de la discussion
// Membre C
//
// Une ligne de public.messages (01_schema.sql), plus l'état d'envoi côté
// application : un message tapé s'affiche TOUT DE SUITE (« envoi… »), puis
// est remplacé par la ligne enregistrée en base, ou marqué « échec ».
// =====================================================================

enum EtatEnvoi { envoye, enCours, echec }

class Message {
  const Message({
    required this.id,
    required this.idConversation,
    required this.idExpediteur,
    required this.contenu,
    required this.dateEnvoi,
    this.lu = false,
    this.etat = EtatEnvoi.envoye,
    this.cleLocale,
  });

  /// Identifiant en base ; null tant que le message n'est pas enregistré.
  final int? id;
  final String idConversation;
  final String idExpediteur;
  final String contenu;
  final DateTime dateEnvoi;
  final bool lu;
  final EtatEnvoi etat;

  /// Identifiant provisoire d'un message en cours d'envoi (ou en échec).
  final String? cleLocale;

  bool get estLocal => id == null;

  /// Message tapé par l'utilisateur, pas encore enregistré.
  factory Message.local({
    required String cle,
    required String idConversation,
    required String idExpediteur,
    required String contenu,
    required DateTime date,
  }) =>
      Message(
        id: null,
        cleLocale: cle,
        idConversation: idConversation,
        idExpediteur: idExpediteur,
        contenu: contenu,
        dateEnvoi: date,
        etat: EtatEnvoi.enCours,
      );

  Message avecEtat(EtatEnvoi e) => Message(
        id: id,
        cleLocale: cleLocale,
        idConversation: idConversation,
        idExpediteur: idExpediteur,
        contenu: contenu,
        dateEnvoi: dateEnvoi,
        lu: lu,
        etat: e,
      );

  factory Message.depuisLigne(Map<String, dynamic> l) => Message(
        id: (l['id'] as num).toInt(),
        idConversation: l['id_conversation'] as String,
        idExpediteur: l['id_expediteur'] as String,
        contenu: l['contenu'] as String,
        dateEnvoi: DateTime.parse(l['date_envoi'] as String).toLocal(),
        lu: l['lu'] as bool? ?? false,
      );

  /// Ordre d'affichage : date d'envoi, puis id (deux messages à la même
  /// seconde). Les messages locaux passent après les messages enregistrés.
  static int comparer(Message a, Message b) {
    final d = a.dateEnvoi.compareTo(b.dateEnvoi);
    if (d != 0) return d;
    if (a.id != null && b.id != null) return a.id!.compareTo(b.id!);
    return a.id == null ? (b.id == null ? 0 : 1) : -1;
  }
}

/// Limite de la base : check (char_length(contenu) between 1 and 2000).
const longueurMaxMessage = 2000;

/// Heure sous une bulle : « 14:32 ».
String formaterHeure(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
