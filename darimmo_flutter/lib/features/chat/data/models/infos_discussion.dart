// =====================================================================
// DarImmo - [7.2] En-tête de la discussion (maquette C8)
// Membre C
//
// Interlocuteur (nom, photo) et annonce liée (photo, titre, prix, bouton
// « Voir »). Construit à partir d'une ligne de mes_conversations() et du
// prix de l'annonce.
// =====================================================================
import 'package:darimmo/features/chat/data/models/resume_conversation.dart';

class InfosDiscussion {
  const InfosDiscussion({
    required this.conversation,
    this.prix,
    this.location = false,
    this.ville,
  });

  final ResumeConversation conversation;

  /// null si l'annonce n'est plus visible (supprimée, masquée…).
  final double? prix;

  /// true pour une location : prix affiché en « DT/mois ».
  final bool location;
  final String? ville;

  String get nom => conversation.nomAffiche;
  String get initiales => conversation.initiales;
  String? get photo => conversation.photoInterlocuteur;
  String? get idAnnonce => conversation.idAnnonce;
  String? get photoAnnonce => conversation.photoAnnonce;

  /// « Villa avec piscine · La Marsa », comme sur la maquette.
  String get titreAnnonce {
    final t = conversation.titreAnnonce ?? 'Annonce';
    return ville == null || ville!.trim().isEmpty ? t : '$t · ${ville!.trim()}';
  }
}
