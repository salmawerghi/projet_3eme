// Faux SignalementRepository (en mémoire) pour les tests de la 3.4.
// Comme la base : un seul signalement par annonce (contrainte unique).
import 'package:darimmo/features/report/data/repositories/signalement_repository.dart';

class FauxSignalements implements SignalementRepository {
  FauxSignalements({Set<String>? dejaSignalees}) : envoyes = {for (final id in dejaSignalees ?? <String>{}) id: '…'};

  /// id de l'annonce -> motif enregistré.
  final Map<String, String> envoyes;

  /// Prochaine erreur à l'envoi (une seule fois).
  SignalementException? erreur;

  @override
  Future<bool> dejaSignale(String idAnnonce) async => envoyes.containsKey(idAnnonce);

  @override
  Future<void> signaler(String idAnnonce, String motif) async {
    final e = erreur;
    if (e != null) {
      erreur = null;
      throw e;
    }
    if (envoyes.containsKey(idAnnonce)) {
      throw const SignalementException(SignalementException.messageDejaSignale, dejaSignale: true);
    }
    envoyes[idAnnonce] = motif;
  }
}
