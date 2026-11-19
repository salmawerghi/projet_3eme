// =====================================================================
// DarImmo - [9.1] Rôle du compte connecté, partagé par toute l'application
// Tâche du membre A, réalisée par le membre C.
//
// Relu à chaque connexion, remis à zéro à la déconnexion. Le routeur
// l'écoute : l'écran /admin n'est ouvert qu'à un administrateur, et le
// lien « Espace administration » du profil n'est visible que pour lui.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/data/repositories/compte_repository.dart';

class EtatCompte extends ChangeNotifier {
  EtatCompte({required this.repository, required this.auth}) {
    auth.addListener(_surChangementCompte);
    _surChangementCompte();
  }

  final CompteRepository repository;
  final AuthRepository auth;

  InfosCompte _infos = const InfosCompte();
  String? _utilisateur;

  bool get estAdmin => _infos.estAdmin;
  bool get estBloque => _infos.estBloque;

  void _surChangementCompte() {
    final utilisateur = auth.estConnecte ? auth.idUtilisateur : null;
    if (utilisateur == _utilisateur) return;
    _utilisateur = utilisateur;
    _infos = const InfosCompte();
    notifyListeners();
    if (utilisateur != null) charger();
  }

  Future<void> charger() async {
    final pour = _utilisateur;
    if (pour == null) return;
    try {
      final infos = await repository.lire();
      if (pour != _utilisateur) return; // compte changé entre-temps
      _infos = infos;
      notifyListeners();
    } on CompteException catch (e) {
      debugPrint('[9.1] $e'); // on garde « utilisateur » : rien d'admin n'est affiché
    }
  }

  @override
  void dispose() {
    auth.removeListener(_surChangementCompte);
    super.dispose();
  }
}
