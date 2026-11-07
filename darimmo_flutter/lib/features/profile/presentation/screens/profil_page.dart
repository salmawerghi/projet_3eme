// =====================================================================
// DarImmo - Onglet « Profil » (squelette 1.6)
// Membre A : [2.3] Modifier mon profil et ma photo (maquette A5), lien
// vers l'administration si rôle admin (9.1). Les liens vers les modules
// des autres membres (Mes annonces…) sont déjà branchés.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key, required this.email, required this.onDeconnexion});
  final String? email;
  final Future<void> Function() onDeconnexion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Text('Profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        Row(children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: DarColors.primarySoft,
            child: Icon(Icons.person, color: DarColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(email ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Text('Modifier le profil : story 2.3 (membre A)',
                  style: TextStyle(fontSize: 12, color: DarColors.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        _Lien(icone: Icons.home_work_outlined, titre: 'Mes annonces', sousTitre: '6.3 · 6.5', onTap: () => context.push('/mes-annonces')),
        _Lien(icone: Icons.map_outlined, titre: 'Carte des annonces', sousTitre: '4.1 · 4.2 (membre B)', onTap: () => context.push('/carte')),
        _Lien(icone: Icons.shield_outlined, titre: 'Espace administration', sousTitre: '9.x (membre A)', onTap: () => context.push('/admin')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDeconnexion,
          icon: const Icon(Icons.logout, color: DarColors.danger),
          label: const Text('Se déconnecter', style: TextStyle(color: DarColors.danger)),
        ),
      ]),
    );
  }
}

class _Lien extends StatelessWidget {
  const _Lien({required this.icone, required this.titre, required this.sousTitre, required this.onTap});
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: DarColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), side: const BorderSide(color: DarColors.border)),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(icone, color: DarColors.primary),
            title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(sousTitre),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      );
}
