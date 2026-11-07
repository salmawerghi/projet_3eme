// =====================================================================
// DarImmo - [6.2] Choix des photos dans la galerie + compression
// Membre C
//
// image_picker redimensionne (1600 px maximum) et recompresse (qualité 80)
// AVANT l'envoi : une photo de téléphone de 4 à 8 Mo tombe à ~200-400 Ko.
// Android 13+ utilise le sélecteur de photos du système : aucune
// permission à demander. Sur le web, l'image est redimensionnée dans le navigateur.
// =====================================================================
import 'package:image_picker/image_picker.dart';

import 'models/photo_annonce.dart';

/// Ouvre la galerie et renvoie au plus [maximum] photos (liste vide si annulé).
/// Remplacé par une fausse fonction dans les tests.
typedef ChoisirPhotos = Future<List<PhotoChoisie>> Function(int maximum);

Future<List<PhotoChoisie>> choisirDansLaGalerie(int maximum) async {
  if (maximum < 1) return const [];
  final fichiers = await ImagePicker().pickMultiImage(
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
    limit: maximum,
  );
  return [
    // take : sur le web, « limit » n'est pas appliqué par le navigateur.
    for (final f in fichiers.take(maximum)) PhotoChoisie(octets: await f.readAsBytes(), nom: f.name),
  ];
}
