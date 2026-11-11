// =====================================================================
// DarImmo - [3.2] Filtres de la recherche
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// null = « pas de filtre » sur ce critère.
// =====================================================================
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;

class FiltreRecherche {
  const FiltreRecherche({
    this.texte,
    this.typeOffre,
    this.typeBien,
    this.prixMin,
    this.prixMax,
    this.ville,
    this.sPlusMin,
  });

  static const vide = FiltreRecherche();

  /// Barre de recherche de l'accueil : cherché dans le titre, la ville et l'adresse.
  final String? texte;

  /// null = vente ET location.
  final TypeOffre? typeOffre;
  final TypeBien? typeBien;
  final double? prixMin;
  final double? prixMax;
  final String? ville;

  /// « S+n minimum » (S+2 = 2 chambres + 1 salon = 3 pièces).
  final int? sPlusMin;

  /// Valeur à comparer à la colonne nb_pieces (nombre TOTAL de pièces).
  int? get nbPiecesMin => sPlusMin == null ? null : sPlusMin! + 1;

  bool get estVide => this == vide;

  /// Les filtres de la feuille (tout sauf le texte de la barre de recherche).
  int get nbFiltresFeuille => [typeOffre, typeBien, prixMin, prixMax, ville, sPlusMin].where((v) => v != null).length;

  /// Pour mettre un champ à null, passer une fonction qui renvoie null : copie(ville: () => null).
  FiltreRecherche copie({
    String? Function()? texte,
    TypeOffre? Function()? typeOffre,
    TypeBien? Function()? typeBien,
    double? Function()? prixMin,
    double? Function()? prixMax,
    String? Function()? ville,
    int? Function()? sPlusMin,
  }) =>
      FiltreRecherche(
        texte: texte != null ? _propre(texte()) : this.texte,
        typeOffre: typeOffre != null ? typeOffre() : this.typeOffre,
        typeBien: typeBien != null ? typeBien() : this.typeBien,
        prixMin: prixMin != null ? prixMin() : this.prixMin,
        prixMax: prixMax != null ? prixMax() : this.prixMax,
        ville: ville != null ? _propre(ville()) : this.ville,
        sPlusMin: sPlusMin != null ? sPlusMin() : this.sPlusMin,
      );

  static String? _propre(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

  @override
  bool operator ==(Object other) =>
      other is FiltreRecherche &&
      other.texte == texte &&
      other.typeOffre == typeOffre &&
      other.typeBien == typeBien &&
      other.prixMin == prixMin &&
      other.prixMax == prixMax &&
      other.ville == ville &&
      other.sPlusMin == sPlusMin;

  @override
  int get hashCode => Object.hash(texte, typeOffre, typeBien, prixMin, prixMax, ville, sPlusMin);

  @override
  String toString() =>
      'FiltreRecherche(texte: $texte, offre: ${typeOffre?.name}, type: ${typeBien?.name}, prix: $prixMin-$prixMax, ville: $ville, S+$sPlusMin)';
}
