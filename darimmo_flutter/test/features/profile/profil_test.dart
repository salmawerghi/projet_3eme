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

/// Écran de téléphone (390 x 844) : toute la page tient sans défilement inutile.
Future<void> ouvrirProfil(WidgetTester tester, FauxProfilRepository repository) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
}

Future<void> enregistrer(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Enregistrer les modifications'));
  await tester.tap(find.text('Enregistrer les modifications'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('charge et enregistre le nom et le téléphone normalisé', (
    tester,
  ) async {
    final repository = FauxProfilRepository();
    await ouvrirProfil(tester, repository);

    expect(find.text('yasmine@gmail.com'), findsOneWidget);
    // Carte bleue (maquette A5) + champ du formulaire
    expect(find.text('Yasmine Trabelsi'), findsNWidgets(2));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Yasmine Ben Salah',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '55 123 456');
    await enregistrer(tester);

    expect(repository.derniereSauvegarde?.nom, 'Yasmine Ben Salah');
    expect(repository.derniereSauvegarde?.telephone, '+21655123456');
    expect(find.text('Votre profil a été mis à jour.'), findsOneWidget);
  });

  testWidgets('refuse un numéro tunisien invalide sans enregistrer', (
    tester,
  ) async {
    final repository = FauxProfilRepository();
    await ouvrirProfil(tester, repository);

    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await enregistrer(tester);

    expect(
      find.text('Numéro tunisien à 8 chiffres (ex : 22 345 678)'),
      findsOneWidget,
    );
    expect(repository.derniereSauvegarde, isNull);
  });

  testWidgets('maquette A5 : carte d’identité, menu clair, aucune mention de membre ou de tâche', (
    tester,
  ) async {
    await ouvrirProfil(tester, FauxProfilRepository());
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Publier, modifier et suivre la validation'), findsOneWidget);
    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.byTooltip('Changer la photo'), findsOneWidget);
    expect(find.text('Espace administration'), findsNothing, reason: 'pas de compte admin');
    await tester.scrollUntilVisible(find.text('DarImmo · version 1.0'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Se déconnecter'), findsOneWidget);
    for (final texte in tester.widgetList<Text>(find.byType(Text))) {
      final contenu = texte.data ?? '';
      expect(contenu, isNot(matches(RegExp(r'[Mm]embre [ABC]|\d\.\d ·|· \d\.\d'))), reason: contenu);
    }
  });
}
