// =====================================================================
// DarImmo - [9.3] Un compte vu par l'administrateur (onglet Comptes)
// Tâche du membre A, réalisée par le membre C.
// =====================================================================
class CompteAdmin {
  const CompteAdmin({
    required this.id,
    required this.nom,
    required this.estAdmin,
    required this.bloque,
    this.email,
    this.photoUrl,
  });

  final String id;
  final String nom;
  final String? email;
  final String? photoUrl;
  final bool estAdmin;
  final bool bloque;

  static const colonnes = 'id, nom, email, photo_url, role, bloque';

  /// Nom affiché : le nom, sinon l'email (certains comptes n'ont pas de nom).
  String get libelle => nom.trim().isNotEmpty ? nom.trim() : (email ?? 'Compte sans nom');

  String get initiales {
    final mots = libelle.split(RegExp(r'[\s@.]+')).where((m) => m.isNotEmpty).take(2);
    final lettres = mots.map((m) => m[0].toUpperCase()).join();
    return lettres.isEmpty ? '?' : lettres;
  }

  CompteAdmin avecBlocage(bool valeur) =>
      CompteAdmin(id: id, nom: nom, email: email, photoUrl: photoUrl, estAdmin: estAdmin, bloque: valeur);

  factory CompteAdmin.depuisLigne(Map<String, dynamic> l) => CompteAdmin(
        id: l['id'] as String,
        nom: l['nom'] as String? ?? '',
        email: l['email'] as String?,
        photoUrl: l['photo_url'] as String?,
        estAdmin: l['role'] == 'admin',
        bloque: l['bloque'] == true,
      );
}
