// Tests unitaires [6.1] : règles de validation et conversion vers la table annonces.
import 'package:flutter_test/flutter_test.dart';
import 'package:poc_temps_reel/features/publish/models/annonce.dart';
import 'package:poc_temps_reel/features/publish/validators.dart';

void main() {
  group('lireNombre', () {
    test('accepte les espaces et la virgule', () {
      expect(lireNombre('385 000'), 385000);
      expect(lireNombre('1 250 000'), 1250000);
      expect(lireNombre('98,5'), 98.5);
    });
    test('refuse le texte', () {
      expect(lireNombre('abc'), isNull);
      expect(lireNombre(''), isNull);
      expect(lireNombre('1,2,3'), isNull);
    });
  });

  test('titre : obligatoire, 3 à 120 caractères', () {
    expect(validerTitre(''), isNotNull);
    expect(validerTitre('  ab  '), isNotNull);
    expect(validerTitre('Villa'), isNull);
    expect(validerTitre('a' * 121), isNotNull);
  });

  test('prix et surface : obligatoires et > 0', () {
    expect(validerPrix(''), 'Le prix est obligatoire');
    expect(validerPrix('0'), isNotNull);
    expect(validerPrix('-5'), isNotNull);
    expect(validerPrix('385 000'), isNull);
    expect(validerSurface(null), isNotNull);
    expect(validerSurface('12x'), isNotNull);
    expect(validerSurface('120'), isNull);
  });

  test('ville obligatoire, description limitée à 5000', () {
    expect(validerVille('   '), isNotNull);
    expect(validerVille('Sousse'), isNull);
    expect(validerDescription(null), isNull);
    expect(validerDescription('x' * 5001), isNotNull);
  });

  test('pièces : 1 à 50, ignoré pour un terrain', () {
    expect(validerPieces(0, aDesPieces: true), isNotNull);
    expect(validerPieces(4, aDesPieces: true), isNull);
    expect(validerPieces(0, aDesPieces: false), isNull);
  });

  test('libellé S+n', () {
    expect(libellePieces(4), 'S+3');
    expect(libellePieces(1), 'S+0 (studio)');
  });

  group('NouvelleAnnonce.versLigne', () {
    const base = NouvelleAnnonce(
      titre: '  Appartement S+3  ',
      typeBien: TypeBien.appartement,
      typeOffre: TypeOffre.vente,
      prix: 385000,
      surface: 145,
      nbPieces: 4,
      ville: ' Ariana ',
      adresse: '   ',
      description: 'Lumineux',
    );

    // Créée en brouillon (étape 1) ; « en attente » après l'étape photos (6.2).
    test('valeurs SQL, statut brouillon et annonceur connecté', () {
      final l = base.versLigne('user-123');
      expect(l['titre'], 'Appartement S+3');
      expect(l['type_bien'], 'appartement');
      expect(l['type_offre'], 'vente');
      expect(l['nb_pieces'], 4);
      expect(l['ville'], 'Ariana');
      expect(l['adresse'], isNull); // champ vide -> NULL
      expect(l['description'], 'Lumineux');
      expect(l['statut'], 'brouillon');
      expect(l['id_annonceur'], 'user-123');
    });

    test('un terrain a 0 pièce', () {
      const terrain = NouvelleAnnonce(
          titre: 'Terrain', typeBien: TypeBien.terrain, typeOffre: TypeOffre.vente,
          prix: 96000, surface: 600, nbPieces: 3, ville: 'Nabeul');
      expect(terrain.versLigne('u')['nb_pieces'], 0);
    });
  });

  test('Annonce.depuisLigne lit la réponse de la base', () {
    final a = Annonce.depuisLigne({
      'id': 'a1', 'titre': 'Villa', 'type_bien': 'villa', 'type_offre': 'location',
      'prix': 1400, 'ville': 'Sousse', 'statut': 'en_attente', 'date_creation': '2026-11-06T10:42:00Z',
    });
    expect(a.statut, StatutAnnonce.enAttente);
    expect(a.typeOffre, TypeOffre.location);
    expect(a.prix, 1400.0);
  });
}
