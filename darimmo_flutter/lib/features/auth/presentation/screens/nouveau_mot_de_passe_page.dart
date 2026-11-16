import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/bandeau_erreur.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/validators_auth.dart';

class NouveauMotDePassePage extends StatefulWidget {
  const NouveauMotDePassePage({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<NouveauMotDePassePage> createState() => _NouveauMotDePassePageState();
}

class _NouveauMotDePassePageState extends State<NouveauMotDePassePage> {
  final _form = GlobalKey<FormState>();
  final _nouveauMotDePasse = TextEditingController();
  final _confirmationMotDePasse = TextEditingController();
  bool _enCours = false;
  bool _motDePasseVisible = false;
  bool _confirmationVisible = false;
  String? _erreur;
  String? _confirmation;

  @override
  void dispose() {
    _nouveauMotDePasse.dispose();
    _confirmationMotDePasse.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _erreur = null;
      _confirmation = null;
    });

    if (!_form.currentState!.validate()) return;

    setState(() => _enCours = true);
    try {
      await widget.auth.changerMotDePasse(nouveauMotDePasse: _nouveauMotDePasse.text);
      if (mounted) {
        setState(() => _confirmation = 'Votre mot de passe a été mis à jour.');
      }
    } on ConnexionException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  String? _validerConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Confirmez votre nouveau mot de passe';
    if (value != _nouveauMotDePasse.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Text(
                'Choisissez un nouveau mot de passe',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: DarColors.text),
              ),
              const SizedBox(height: 10),
              const Text(
                'Utilisez au moins 8 caractères pour sécuriser votre compte.',
                style: TextStyle(fontSize: 15, height: 1.45, color: DarColors.text2),
              ),
              const SizedBox(height: 24),
              if (_erreur != null) ...[
                BandeauErreur(message: _erreur!),
                const SizedBox(height: 18),
              ],
              if (_confirmation != null) ...[
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
                          _confirmation!,
                          style: const TextStyle(color: DarColors.success, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _nouveauMotDePasse,
                obscureText: !_motDePasseVisible,
                autofillHints: const [AutofillHints.newPassword],
                validator: validerMotDePasse,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                    icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _confirmationMotDePasse,
                obscureText: !_confirmationVisible,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validerConfirmation,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _confirmationVisible = !_confirmationVisible),
                    icon: Icon(_confirmationVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _enCours ? null : _enregistrer,
                child: _enCours
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Enregistrement…'),
                        ],
                      )
                    : const Text('Enregistrer le nouveau mot de passe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
