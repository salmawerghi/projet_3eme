// =====================================================================
// DarImmo - Configuration (tâche 1.6)
//
// Les clés ne sont JAMAIS écrites dans le code ni versionnées : elles
// viennent du fichier env.json (ignoré par Git), passé au lancement :
//   flutter run --dart-define-from-file=env.json
// Modèle du fichier : env.example.json (à copier en env.json).
// =====================================================================

class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clé publique (« publishable ») : protégée par les règles RLS de la base.
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static bool get complet => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
