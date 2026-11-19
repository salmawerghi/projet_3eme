// =====================================================================
// DarImmo - [9.1] [9.3] Rôle et blocage du compte connecté
// Tâches du membre A, réalisées par le membre C.
//
// Lit profiles.role (utilisateur | admin) et profiles.bloque.
// La sécurité reste dans la base (RLS, is_admin(), est_bloque()) : l'appli
// s'en sert seulement pour afficher ou cacher les écrans.
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfosCompte {
  const InfosCompte({this.estAdmin = false, this.estBloque = false});
  final bool estAdmin;
  final bool estBloque;
}

class CompteException implements Exception {
  const CompteException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class CompteRepository {
  /// Rôle et blocage du compte connecté (valeurs par défaut si personne n'est connecté).
  Future<InfosCompte> lire();
}

class SupabaseCompteRepository implements CompteRepository {
  SupabaseCompteRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<InfosCompte> lire() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return const InfosCompte();
    try {
      final ligne = await _client.from('profiles').select('role, bloque').eq('id', id).maybeSingle();
      if (ligne == null) return const InfosCompte();
      return InfosCompte(estAdmin: ligne['role'] == 'admin', estBloque: ligne['bloque'] == true);
    } catch (e) {
      debugPrint('[9.1] $e');
      throw const CompteException('Impossible de lire votre compte. Vérifiez Internet.');
    }
  }
}
