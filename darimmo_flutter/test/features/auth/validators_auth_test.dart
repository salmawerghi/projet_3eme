// Tests des règles de validation de l'inscription (2.1).
import 'package:darimmo/features/auth/presentation/validators_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nom obligatoire', () {
    expect(validerNom(''), 'Le nom est obligatoire');
    expect(validerNom('   '), 'Le nom est obligatoire');
    expect(validerNom('A'), 'Nom trop court');
    expect(validerNom('Yasmine Trabelsi'), isNull);
    expect(validerNom('x' * 81), isNotNull);
  });

  test('email valide', () {
    expect(validerEmail(''), isNotNull);
    expect(validerEmail('yasmine'), isNotNull);
    expect(validerEmail('yasmine@gmail'), isNotNull);
    expect(validerEmail('yas mine@gmail.com'), isNotNull);
    expect(validerEmail('yasmine.t@gmail.com'), isNull);
    expect(validerEmail('  yasmine.t@gmail.com  '), isNull, reason: 'les espaces autour sont ignorés');
  });

  test('mot de passe : 8 caractères minimum', () {
    expect(validerMotDePasse(''), 'Le mot de passe est obligatoire');
    expect(validerMotDePasse('1234567'), 'Au moins 8 caractères');
    expect(validerMotDePasse('12345678'), isNull);
  });

  test('téléphone facultatif, 8 chiffres tunisiens', () {
    expect(validerTelephone(''), isNull);
    expect(validerTelephone(null), isNull);
    expect(validerTelephone('22 345 678'), isNull);
    expect(validerTelephone('2234567'), isNotNull);
    expect(validerTelephone('abc'), isNotNull);
    expect(normaliserTelephone('22 345 678'), '+21622345678');
    expect(normaliserTelephone('+216 22.345.678'), '+21622345678');
    expect(normaliserTelephone('0021622345678'), '+21622345678');
    expect(normaliserTelephone(''), isNull);
  });

  test('force du mot de passe', () {
    expect(evaluerMotDePasse(''), ForceMotDePasse.vide);
    expect(evaluerMotDePasse('abc'), ForceMotDePasse.tropCourt);
    expect(evaluerMotDePasse('abcdefgh'), ForceMotDePasse.faible);
    expect(evaluerMotDePasse('abcdefg1'), ForceMotDePasse.moyen);
    expect(evaluerMotDePasse('Abcdefg1'), ForceMotDePasse.bon);
    expect(evaluerMotDePasse('Abcdefg1!'), ForceMotDePasse.solide);
    expect(ForceMotDePasse.solide.barres, 4);
  });
}
