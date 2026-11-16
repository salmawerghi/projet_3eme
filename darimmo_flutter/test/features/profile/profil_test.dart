import 'package:darimmo/features/profile/data/repositories/profil_repository.dart';
import 'package:darimmo/features/profile/presentation/screens/profil_page.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FauxProfilRepository implements ProfilRepository {
  DonneesProfil donnees = const DonneesProfil(
    nom: 'Yasmine Trabelsi',
    telephone: '+21622345678',
  );
  DonneesProfil? derniereSauvegarde;

  @override
  Future<DonneesProfil> charger() async => donnees;

  @override
  Future<DonneesProfil> enregistrer({
    required String nom,
    required String? telephone,
    PhotoChoisie? photo,
  }) async {
    derniereSauvegarde = DonneesProfil(
      nom: nom,
      telephone: telephone,
      photoUrl: donnees.photoUrl,
    );
    donnees = derniereSauvegarde!;
    return donnees;
  }
}

void main() {
  testWidgets('charge et enregistre le nom et le téléphone normalisé', (
    tester,
  ) async {
    final repository = FauxProfilRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilPage(
          email: 'yasmine@gmail.com',
          repository: repository,
          choisirPhotos: (_) async => const [],
          onDeconnexion: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('yasmine@gmail.com'), findsOneWidget);
    expect(find.text('Yasmine Trabelsi'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Yasmine Ben Salah',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '55 123 456');
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();

    expect(repository.derniereSauvegarde?.nom, 'Yasmine Ben Salah');
    expect(repository.derniereSauvegarde?.telephone, '+21655123456');
    expect(find.text('Votre profil a été mis à jour.'), findsOneWidget);
  });

  testWidgets('refuse un numéro tunisien invalide sans enregistrer', (
    tester,
  ) async {
    final repository = FauxProfilRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilPage(
          email: 'yasmine@gmail.com',
          repository: repository,
          choisirPhotos: (_) async => const [],
          onDeconnexion: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();

    expect(
      find.text('Numéro tunisien à 8 chiffres (ex : 22 345 678)'),
      findsOneWidget,
    );
    expect(repository.derniereSauvegarde, isNull);
  });
}
