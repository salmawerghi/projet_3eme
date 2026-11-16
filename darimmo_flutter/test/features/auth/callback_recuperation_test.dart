import 'package:darimmo/features/auth/data/services/callback_recuperation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lit les paramètres d’authentification dans la query et le fragment',
    () {
      final uri = Uri.parse(
        'http://localhost:3000/reset-password?code=abc&type=recovery#access_token=xyz&token_type=bearer',
      );

      expect(parametresCallback(uri), {
        'access_token': 'xyz',
        'token_type': 'bearer',
        'code': 'abc',
        'type': 'recovery',
      });
    },
  );

  test('lit un token_hash de récupération fourni dans la query', () {
    final uri = Uri.parse(
      'http://localhost:3000/reset-password?token_hash=hash123&type=recovery',
    );

    expect(parametresCallback(uri), {
      'token_hash': 'hash123',
      'type': 'recovery',
    });
  });
}
