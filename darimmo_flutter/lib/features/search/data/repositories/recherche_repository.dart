// =====================================================================
// DarImmo - [3.1] [3.2] RechercheRepository : annonces publiées + filtres
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Seule classe du module qui parle à Supabase. Elle est créée dans
// core/services.dart ; les tests utilisent un faux repository.
// RLS : un visiteur ne voit que les annonces au statut « publiee » ; le
// filtre statut = publiee est quand même ajouté (un annonceur connecté
// verrait sinon aussi ses propres brouillons).
// =====================================================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/data/models/filtre_recherche.dart';

class RechercheException implements Exception {
  const RechercheException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class RechercheRepository {
  /// Nombre d'annonces par page (chargement progressif).
  static const taillePage = 10;

  /// Page [page] (0 = la première) des annonces publiées, de la plus récente à la plus ancienne.
  Future<List<AnnonceRecherche>> page(FiltreRecherche filtre, int page);

  /// Nombre total de résultats (bouton « Afficher N annonces »).
  Future<int> compter(FiltreRecherche filtre);

  /// Villes des annonces publiées, pour les suggestions du champ Ville.
  Future<List<String>> villes();
}

/// Échappe % et _ : tapés par l'utilisateur, ils doivent être cherchés tels quels.
@visibleForTesting
String motifContient(String texte) {
  final echappe = texte.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
  return '%$echappe%';
}

/// Retire les caractères qui ont un sens dans la syntaxe « or » de PostgREST
/// (virgule, parenthèses, guillemets, jokers) : la recherche reste du texte simple.
@visibleForTesting
String? texteRechercheSur(String? texte) {
  if (texte == null) return null;
  final propre = texte.replaceAll(RegExp(r'[,()"*%_\\:.]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return propre.isEmpty ? null : propre;
}

class SupabaseRechercheRepository implements RechercheRepository {
  SupabaseRechercheRepository(this._client);
  final SupabaseClient _client;

  /// Mêmes filtres pour la liste et pour le compteur.
  PostgrestFilterBuilder<T> _filtrer<T>(PostgrestFilterBuilder<T> q, FiltreRecherche f) {
    q = q.eq('statut', 'publiee');
    if (f.typeOffre != null) q = q.eq('type_offre', f.typeOffre!.name);
    if (f.typeBien != null) q = q.eq('type_bien', f.typeBien!.name);
    if (f.prixMin != null) q = q.gte('prix', f.prixMin!);
    if (f.prixMax != null) q = q.lte('prix', f.prixMax!);
    if (f.nbPiecesMin != null) q = q.gte('nb_pieces', f.nbPiecesMin!);
    if (f.ville != null) q = q.ilike('ville', motifContient(f.ville!));
    final texte = texteRechercheSur(f.texte);
    if (texte != null) q = q.or('titre.ilike.*$texte*,ville.ilike.*$texte*,adresse.ilike.*$texte*');
    return q;
  }

  Future<R> _appel<R>(Future<R> Function() requete) async {
    try {
      return await requete();
    } on PostgrestException catch (e) {
      debugPrint('[3.1] ${e.code} : ${e.message}');
      throw RechercheException('Erreur du serveur (${e.code ?? 'inconnue'}). Réessayez.');
    } catch (e) {
      debugPrint('[3.1] $e');
      throw const RechercheException('Connexion impossible. Vérifiez Internet et réessayez.');
    }
  }

  @override
  Future<List<AnnonceRecherche>> page(FiltreRecherche filtre, int page) => _appel(() async {
        final debut = page * RechercheRepository.taillePage;
        final lignes = await _filtrer(_client.from('annonces').select(AnnonceRecherche.colonnes), filtre)
            .order('date_creation', ascending: false)
            .order('id') // départage les dates égales : aucune annonce sautée ou répétée d'une page à l'autre
            .range(debut, debut + RechercheRepository.taillePage - 1);
        return [for (final l in lignes) AnnonceRecherche.depuisLigne(l)];
      });

  @override
  Future<int> compter(FiltreRecherche filtre) => _appel(() async {
        final reponse = await _filtrer(_client.from('annonces').select('id'), filtre).count(CountOption.exact);
        return reponse.count;
      });

  @override
  Future<List<String>> villes() => _appel(() async {
        final lignes = await _client.from('annonces').select('ville').eq('statut', 'publiee');
        final parCle = <String, String>{};
        for (final l in lignes) {
          final v = (l['ville'] as String?)?.trim();
          if (v != null && v.isNotEmpty) parCle.putIfAbsent(v.toLowerCase(), () => v);
        }
        return parCle.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
}
