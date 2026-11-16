import 'package:darimmo/features/auth/data/repositories/auth_repository.dart';
import 'package:darimmo/features/auth/presentation/screens/nouveau_mot_de_passe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthPasswordUpdate extends AuthRepository {
  FakeAuthPasswordUpdate();

  bool aChangePassword = false;
  String? nouveauMotDePasse;

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
  Future<void> reinitialiserMotDePasse({required String email}) async {}

  @override
  Future<void> renvoyerConfirmation(String email) async {}

  @override
  Future<void> changerMotDePasse({required String nouveauMotDePasse}) async {
    aChangePassword = true;
    this.nouveauMotDePasse = nouveauMotDePasse;
  }
}

void main() {
  testWidgets('nouveau mot de passe valide : confirmation visible', (tester) async {
    final auth = FakeAuthPasswordUpdate();

    await tester.pumpWidget(MaterialApp(home: NouveauMotDePassePage(auth: auth)));

    await tester.enterText(find.widgetWithText(TextFormField, 'Nouveau mot de passe'), 'NouveauMotDePasse123!');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'), 'NouveauMotDePasse123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer le nouveau mot de passe'));
    await tester.pumpAndSettle();

    expect(auth.aChangePassword, isTrue);
    expect(auth.nouveauMotDePasse, 'NouveauMotDePasse123!');
    expect(find.text('Votre mot de passe a été mis à jour.'), findsOneWidget);
  });
}
