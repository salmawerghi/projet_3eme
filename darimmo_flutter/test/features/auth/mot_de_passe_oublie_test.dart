import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/screens/connexion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthReset extends AuthRepository {
  FakeAuthReset();

  String? emailDemande;
  bool appelleReinitialisation = false;

  @override
  bool get estConnecte => false;

  @override
  String? get idUtilisateur => null;

  @override
  String? get email => null;

  @override
  Future<void> connecter({required String email, required String motDePasse}) async {}

  @override
  Future<void> deconnecter() async {}

  @override
  Future<ResultatInscription> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
    String? telephone,
  }) async {
    return ResultatInscription.confirmationEmail;
  }

  @override
  Future<void> reinitialiserMotDePasse({required String email}) async {
    appelleReinitialisation = true;
    emailDemande = email;
  }

  @override
  Future<void> changerMotDePasse({required String nouveauMotDePasse}) async {}

  @override
  Future<void> renvoyerConfirmation(String email) async {}
}

void main() {
  testWidgets('lien de réinitialisation envoyé avec succès', (tester) async {
    final auth = FakeAuthReset();

    await tester.pumpWidget(MaterialApp(home: ConnexionPage(auth: auth)));
    await tester.enterText(find.byType(TextFormField).at(0), 'yasmine@gmail.com');
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pump();

    expect(auth.appelleReinitialisation, isTrue);
    expect(auth.emailDemande, 'yasmine@gmail.com');
    expect(find.textContaining('Un lien de réinitialisation a été envoyé'), findsOneWidget);
  });
}
