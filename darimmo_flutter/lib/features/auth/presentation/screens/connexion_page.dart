// =====================================================================
// DarImmo - Écran de connexion (maquette A2)
// Story [2.2] Se connecter du membre A : email + mot de passe, message
// clair si les identifiants sont faux. Lien « Créer un compte » -> 2.1.
// Story [2.4] Mot de passe oublié : envoie un lien de réinitialisation.
// "Continuer avec Google" reste bonus en 2.5.
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/bandeau_erreur.dart';
import 'package:darimmo/core/widgets/logo_darimmo.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/validators_auth.dart';

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
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailInitial);
  final _motDePasse = TextEditingController();
  bool _enCours = false;
  bool _motDePasseVisible = false;
  String? _erreur;
  String? _messageInfo;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (_enCours) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _erreur = null;
      _messageInfo = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _enCours = true);
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

  Future<void> _reinitialiserMotDePasse() async {
    if (_enCours) return;
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email)) {
      setState(() => _erreur = 'Saisissez une adresse email valide pour recevoir le lien.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enCours = true;
      _erreur = null;
      _messageInfo = null;
    });
    try {
      await widget.auth.reinitialiserMotDePasse(email: email);
      if (mounted) {
        setState(() => _messageInfo = 'Un lien de réinitialisation a été envoyé à $email.');
      }
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
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 4, 24, 24), children: [
            const Align(alignment: Alignment.centerLeft, child: LogoDarImmo(taille: 44)),
            const SizedBox(height: 28),
            const Text('Content de vous revoir',
                style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w800, color: DarColors.text)),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour retrouver vos favoris, vos annonces et vos messages.',
              style: TextStyle(fontSize: 15, height: 1.45, color: DarColors.text2),
            ),
            const SizedBox(height: 28),
            if (_erreur != null) ...[
              BandeauErreur(message: _erreur!),
              const SizedBox(height: 18),
            ],
            if (_messageInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DarColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: DarColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _messageInfo!,
                        style: const TextStyle(color: DarColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: validerEmail,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                hintText: 'nom@exemple.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _motDePasse,
              obscureText: !_motDePasseVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) => _connecter(),
              validator: (v) => (v ?? '').isEmpty ? 'Entrez votre mot de passe' : null,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _motDePasseVisible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                  icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _enCours ? null : _reinitialiserMotDePasse,
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              // Ombre bleutée du bouton principal (shadow: 'md' de la maquette)
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DarColors.primary.withValues(alpha: _enCours ? 0 : 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _enCours ? null : _connecter,
                child: _enCours
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox.square(
                            dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Connexion…'),
                      ])
                    : const Text('Se connecter'),
              ),
            ),
            if (widget.onCreerCompte != null) ...[
              const SizedBox(height: 20),
              Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Pas encore de compte ?', style: TextStyle(fontSize: 14, color: DarColors.text2)),
                TextButton(
                  onPressed: () => widget.onCreerCompte!(context),
                  child: const Text('Créer un compte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
