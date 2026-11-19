// =====================================================================
// DarImmo - [5.1] Mes favoris, partagés par tous les écrans
// Tâche du membre B, réalisée par le membre C.
//
// Un seul objet pour toute l'application (créé dans core/services.dart) :
// un cœur touché sur le détail est aussitôt rempli dans la liste de
// l'accueil et dans l'onglet Favoris.
//   - chargé à la connexion, vidé à la déconnexion ;
//   - ajout / retrait « optimiste » : le cœur change tout de suite, et
//     revient en arrière si le serveur refuse.
// =====================================================================
import 'package:flutter/foundation.dart';

import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/favorites/data/repositories/favoris_repository.dart';

class EtatFavoris extends ChangeNotifier {
  EtatFavoris({required this.repository, required this.auth}) {
    auth.addListener(_surChangementCompte);
    _surChangementCompte();
  }

  final FavorisRepository repository;
  final AuthRepository auth;

  Set<String> _ids = {};
  final _enCours = <String>{};
  String? _utilisateur;

  /// Les favoris du compte ont été lus au moins une fois.
  bool charge = false;

  bool get estConnecte => auth.estConnecte;
  Set<String> get ids => Set.unmodifiable(_ids);
  bool estFavori(String idAnnonce) => _ids.contains(idAnnonce);

  /// Ajout ou retrait envoyé au serveur, réponse pas encore reçue.
  bool enCours(String idAnnonce) => _enCours.contains(idAnnonce);

  void _surChangementCompte() {
    final utilisateur = auth.estConnecte ? auth.idUtilisateur : null;
    if (utilisateur == _utilisateur) return;
    _utilisateur = utilisateur;
    _ids = {};
    charge = false;
    notifyListeners();
    if (utilisateur != null) charger();
  }

  /// Relit les favoris du compte. En cas d'échec, les cœurs restent vides
  /// (rien de grave : l'onglet Favoris affiche l'erreur et « Réessayer »).
  Future<void> charger() async {
    final pour = _utilisateur;
    if (pour == null) return;
    try {
      final ids = await repository.ids();
      if (pour != _utilisateur) return; // compte changé entre-temps
      _ids = {...ids};
      charge = true;
      notifyListeners();
    } on FavorisException catch (e) {
      debugPrint('[5.1] $e');
    }
  }

  /// Ajoute ou retire [idAnnonce]. Renvoie un message d'erreur, ou null si c'est fait.
  Future<String?> basculer(String idAnnonce) async {
    if (_utilisateur == null) return 'Connectez-vous pour gérer vos favoris.';
    if (_enCours.contains(idAnnonce)) return null; // double appui : on ignore
    final ajout = !_ids.contains(idAnnonce);
    _enCours.add(idAnnonce);
    _ids = ajout ? {..._ids, idAnnonce} : ({..._ids}..remove(idAnnonce));
    notifyListeners();
    try {
      ajout ? await repository.ajouter(idAnnonce) : await repository.retirer(idAnnonce);
      return null;
    } on FavorisException catch (e) {
      _ids = ajout ? ({..._ids}..remove(idAnnonce)) : {..._ids, idAnnonce};
      return e.message;
    } finally {
      _enCours.remove(idAnnonce);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    auth.removeListener(_surChangementCompte);
    super.dispose();
  }
}
