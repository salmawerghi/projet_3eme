// =====================================================================
// DarImmo - [2.1] S'inscrire par email (maquette A3) - membre A
//
// Champs : nom, email, mot de passe (8 caractères minimum, indicateur de
// force), téléphone facultatif, conditions d'utilisation.
// Le projet Supabase exige la confirmation de l'email : une fois le compte
// créé, l'écran affiche « Vérifiez votre boîte mail ». Si la confirmation
// est désactivée, la session s'ouvre et le routeur affiche l'accueil.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/core/widgets/bandeau_erreur.dart';
import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/validators_auth.dart';
import 'package:darimmo/features/auth/presentation/viewmodels/inscription_view_model.dart';

class InscriptionPage extends StatelessWidget {
  const InscriptionPage({super.key, required this.auth, required this.onSeConnecter, this.apresConnexion});
  final AuthRepository auth;

  /// Ouvre l'écran de connexion ([email] pré-rempli s'il est connu).
  final void Function(BuildContext context, String? email) onSeConnecter;

  /// Ex : enregistrer le jeton de notifications (si la session s'ouvre tout de suite).
  final Future<void> Function()? apresConnexion;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InscriptionViewModel(auth),
      child: _Inscription(onSeConnecter: onSeConnecter, apresConnexion: apresConnexion),
    );
  }
}

class _Inscription extends StatefulWidget {
  const _Inscription({required this.onSeConnecter, this.apresConnexion});
  final void Function(BuildContext context, String? email) onSeConnecter;
  final Future<void> Function()? apresConnexion;

  @override
  State<_Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<_Inscription> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  final _telephone = TextEditingController();

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    _motDePasse.dispose();
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _envoyer(InscriptionViewModel vm) async {
    FocusScope.of(context).unfocus();
    final resultat = await vm.inscrire(
      formulaireValide: _form.currentState!.validate(),
      nom: _nom.text,
      email: _email.text,
      motDePasse: _motDePasse.text,
      telephone: _telephone.text,
    );
    // Session ouverte : le routeur affiche l'accueil tout seul.
    if (resultat == ResultatInscription.connecte) await widget.apresConnexion?.call();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscriptionViewModel>();
    final email = vm.emailAConfirmer;
    if (email != null) {
      return _ConfirmationEmail(
        email: email,
        onSeConnecter: () => widget.onSeConnecter(context, email),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créer un compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Gratuit · moins d’une minute', style: TextStyle(fontSize: 13, color: DarColors.muted)),
        ]),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            if (vm.erreurGenerale != null) ...[
              BandeauErreur(message: vm.erreurGenerale!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nom,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: validerNom,
              decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onChanged: (_) => vm.emailModifie(),
              validator: validerEmail,
              forceErrorText: vm.erreurEmail,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: Icon(Icons.mail_outline),
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motDePasse,
              obscureText: !vm.motDePasseVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => vm.motDePasseModifie(),
              validator: validerMotDePasse,
              forceErrorText: vm.erreurMotDePasse,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: vm.motDePasseVisible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                  icon: Icon(vm.motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: vm.basculerVisibilite,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: _motDePasse,
              builder: (_, valeur, _) => _IndicateurForce(motDePasse: valeur.text),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              validator: validerTelephone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (facultatif)',
                prefixIcon: Icon(Icons.phone_outlined),
                prefixText: '+216 ',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => vm.basculerCgu(!vm.cguAcceptees),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: vm.cguAcceptees, onChanged: vm.basculerCgu),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'J’accepte les conditions d’utilisation et la politique de confidentialité de DarImmo.',
                      style: TextStyle(fontSize: 13, color: DarColors.text2, height: 1.45),
                    ),
                  ),
                ),
              ]),
            ),
            if (vm.cguManquantes)
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 2),
                child: Text('Acceptez les conditions pour créer votre compte',
                    style: TextStyle(color: DarColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: vm.envoiEnCours ? null : () => _envoyer(vm),
              child: Text(vm.envoiEnCours ? 'Création du compte…' : 'Créer mon compte'),
            ),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('Déjà inscrit ?', style: TextStyle(fontSize: 14, color: DarColors.text2)),
              TextButton(
                onPressed: () => widget.onSeConnecter(context, null),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Les 4 barres de la maquette A3 + « 10 caractères · 8 minimum ».
class _IndicateurForce extends StatelessWidget {
  const _IndicateurForce({required this.motDePasse});
  final String motDePasse;

  @override
  Widget build(BuildContext context) {
    final force = evaluerMotDePasse(motDePasse);
    final couleur = switch (force) {
      ForceMotDePasse.vide => DarColors.border,
      ForceMotDePasse.tropCourt || ForceMotDePasse.faible => DarColors.danger,
      ForceMotDePasse.moyen => DarColors.warning,
      ForceMotDePasse.bon || ForceMotDePasse.solide => DarColors.success,
    };
    final n = motDePasse.length;
    return Column(children: [
      Row(children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < force.barres ? couleur : DarColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, children: [
        Text(force == ForceMotDePasse.vide ? 'Au moins $motDePasseMin caractères' : force.libelle,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: force == ForceMotDePasse.vide ? DarColors.muted : couleur)),
        Text(n == 0 ? '' : '$n caractère${n > 1 ? 's' : ''} · $motDePasseMin minimum',
            style: const TextStyle(fontSize: 12, color: DarColors.muted)),
      ]),
    ]);
  }
}

/// Compte créé : l'utilisateur doit cliquer sur le lien reçu par email.
class _ConfirmationEmail extends StatelessWidget {
  const _ConfirmationEmail({required this.email, required this.onSeConnecter});
  final String email;
  final VoidCallback onSeConnecter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscriptionViewModel>();
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          Center(
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(color: DarColors.primarySoft, shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: DarColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Vérifiez votre boîte mail',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Votre compte est créé. Nous avons envoyé un lien de confirmation à '),
              TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w800, color: DarColors.text)),
              const TextSpan(text: '. Ouvrez-le pour activer votre compte, puis connectez-vous.'),
            ]),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: DarColors.text2, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DarColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DarColors.border),
            ),
            child: const Column(children: [
              _Etape(numero: null, texte: 'Compte créé, lien envoyé'),
              SizedBox(height: 14),
              _Etape(numero: 2, texte: 'Ouvrez le lien reçu par email'),
              SizedBox(height: 14),
              _Etape(numero: 3, texte: 'Revenez ici et connectez-vous'),
            ]),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onSeConnecter, child: const Text('Se connecter')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: vm.renvoiEnCours ? null : vm.renvoyerEmail,
            child: Text(vm.renvoiEnCours ? 'Envoi…' : 'Je n’ai rien reçu : renvoyer l’email'),
          ),
          if (vm.infoRenvoi != null)
            Text(vm.infoRenvoi!,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: DarColors.text2)),
        ]),
      ),
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({required this.numero, required this.texte});

  /// null = étape terminée (coche verte).
  final int? numero;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final fait = numero == null;
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: fait ? DarColors.successSoft : DarColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: fait
              ? const Icon(Icons.check, size: 16, color: DarColors.success)
              : Text('$numero',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DarColors.primary)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(texte,
            style: TextStyle(
                fontSize: 14,
                fontWeight: fait ? FontWeight.w700 : FontWeight.w600,
                color: fait ? DarColors.text : DarColors.text2)),
      ),
    ]);
  }
}
