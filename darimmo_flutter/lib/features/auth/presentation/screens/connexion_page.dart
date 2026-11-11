// =====================================================================
// DarImmo - Écran de connexion PROVISOIRE (squelette 1.6)
// À remplacer par le membre A : [2.2] Se connecter (maquette A2),
// [2.4] Mot de passe oublié. Le lien « Créer un compte » ouvre la 2.1.
// Les comptes de test du seed (05_seed.sql) sont proposés pour la démo.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key, required this.auth, this.apresConnexion, this.onCreerCompte, this.emailInitial});
  final AuthRepository auth;

  /// Ex : enregistrer le jeton de notifications.
  final Future<void> Function()? apresConnexion;

  /// [2.1] Ouvre l'écran d'inscription.
  final void Function(BuildContext context)? onCreerCompte;

  /// Email pré-rempli (retour de l'inscription).
  final String? emailInitial;

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  late final _email = TextEditingController(text: widget.emailInitial ?? 'vendeur@darimmo.test');
  late final _motDePasse = TextEditingController(text: widget.emailInitial == null ? 'Test1234!' : '');
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await widget.auth.connecter(email: _email.text, motDePasse: _motDePasse.text);
      await widget.apresConnexion?.call();
      // Le routeur affiche l'accueil tout seul (il écoute AuthRepository).
    } on ConnexionException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // flèche retour vers la bienvenue (maquette A2)
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: DarColors.primary, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.home_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Dar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const Text('Immo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: DarColors.primary)),
          ]),
          const SizedBox(height: 28),
          const Text('Connexion', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Écran provisoire : le membre A le remplacera (2.1 / 2.2).',
              style: TextStyle(fontSize: 13, color: DarColors.muted)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            for (final e in ['vendeur@darimmo.test', 'acheteur@darimmo.test'])
              ActionChip(label: Text(e.split('@').first), onPressed: () => _email.text = e),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motDePasse,
            obscureText: true,
            onSubmitted: (_) => _connecter(),
            decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: DarColors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enCours ? null : _connecter,
            child: Text(_enCours ? 'Connexion…' : 'Se connecter'),
          ),
          if (widget.onCreerCompte != null) ...[
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Pas encore de compte ?', style: TextStyle(fontSize: 14, color: DarColors.text2)),
              TextButton(
                onPressed: () => widget.onCreerCompte!(context),
                child: const Text('Créer un compte', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
