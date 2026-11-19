// =====================================================================
// DarImmo - [5.2] Consulter mes favoris (onglet Favoris, maquette B6)
// Tâche du membre B, réalisée par le membre C.
//
// Critères : écran dédié aux favoris ; retrait possible depuis la liste
// (avec « Annuler ») ; message si aucun favori.
// L'onglet est réservé aux comptes (le routeur renvoie un visiteur vers
// la page de bienvenue).
// =====================================================================
import 'package:flutter/material.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/favorites/data/repositories/favoris_repository.dart';
import 'package:darimmo/features/favorites/presentation/viewmodels/etat_favoris.dart';
import 'package:darimmo/features/favorites/presentation/viewmodels/favoris_view_model.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/presentation/widgets/carte_annonce_recherche.dart' show formaterPrixAnnonce;

/// « 1 bien sauvegardé », « 4 biens sauvegardés ».
String resumeFavoris(int n) => switch (n) {
      0 => 'Aucun bien sauvegardé',
      1 => '1 bien sauvegardé',
      _ => '$n biens sauvegardés',
    };

class FavorisPage extends StatefulWidget {
  const FavorisPage({
    super.key,
    required this.repository,
    required this.etat,
    required this.onOuvrir,
    required this.onParcourir,
  });

  final FavorisRepository repository;
  final EtatFavoris etat;
  final void Function(BuildContext context, String idAnnonce) onOuvrir;

  /// Bouton « Parcourir les annonces » de la liste vide.
  final void Function(BuildContext context) onParcourir;

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  late final _vm = FavorisViewModel(repository: widget.repository, etat: widget.etat)..charger();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _retirer(AnnonceRecherche a) async {
    final messager = ScaffoldMessenger.of(context);
    final erreur = await widget.etat.basculer(a.id);
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(erreur != null
          ? SnackBar(content: Text(erreur))
          : SnackBar(
              content: Text('« ${a.titre} » retiré des favoris'),
              action: SnackBarAction(
                label: 'Annuler',
                onPressed: () async {
                  final e = await widget.etat.basculer(a.id);
                  if (e != null) messager.showSnackBar(SnackBar(content: Text(e)));
                },
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final total = _vm.nombre(null);
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mes favoris', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text(_vm.chargement && total == 0 ? 'Chargement…' : resumeFavoris(total),
                  key: const Key('resume-favoris'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
            ]),
          ),
          body: Column(children: [
            if (total > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(children: [
                  for (final (offre, libelle) in [(null, 'Tous'), (TypeOffre.vente, 'Vente'), (TypeOffre.location, 'Location')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$libelle · ${_vm.nombre(offre)}'),
                        selected: _vm.filtre == offre,
                        showCheckmark: false,
                        onSelected: (_) => _vm.choisirFiltre(offre),
                      ),
                    ),
                ]),
              ),
            Expanded(child: _corps()),
          ]),
        );
      },
    );
  }

  Widget _corps() {
    final annonces = _vm.affiches;
    if (_vm.erreur != null && _vm.nombre(null) == 0) {
      return _Message(
        icone: Icons.wifi_off,
        titre: 'Favoris indisponibles',
        texte: _vm.erreur!,
        bouton: FilledButton.icon(onPressed: _vm.charger, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      );
    }
    if (_vm.chargement && _vm.nombre(null) == 0) return const Center(child: CircularProgressIndicator());
    if (_vm.nombre(null) == 0) {
      return _Message(
        icone: Icons.favorite_border,
        titre: 'Aucun favori pour l’instant',
        texte: 'Touchez le cœur d’une annonce pour la garder ici et la retrouver plus tard.',
        bouton: FilledButton.icon(
          onPressed: () => widget.onParcourir(context),
          icon: const Icon(Icons.search),
          label: const Text('Parcourir les annonces'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _vm.charger,
      child: annonces.isEmpty
          ? ListView(children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('Aucun favori dans cette catégorie.',
                    textAlign: TextAlign.center, style: TextStyle(color: DarColors.muted)),
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: annonces.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _LigneFavori(
                annonce: annonces[i],
                onOuvrir: () => widget.onOuvrir(context, annonces[i].id),
                onRetirer: () => _retirer(annonces[i]),
              ),
            ),
    );
  }
}

/// Une ligne de la maquette B6 : photo, type, titre, ville, prix, cœur plein.
class _LigneFavori extends StatelessWidget {
  const _LigneFavori({required this.annonce, required this.onOuvrir, required this.onRetirer});
  final AnnonceRecherche annonce;
  final VoidCallback onOuvrir;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final a = annonce;
    final offre = a.typeOffre == TypeOffre.vente ? 'VENTE' : 'LOCATION';
    return Material(
      color: DarColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: DarColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 96, height: 96, child: _Photo(url: a.photoCouverture, type: a.typeBien)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${a.typeBien.libelle.toUpperCase()} · $offre',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DarColors.accent, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(a.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DarColors.text)),
                if (a.ville != null) ...[
                  const SizedBox(height: 3),
                  Text(a.ville!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: DarColors.muted)),
                ],
                const SizedBox(height: 6),
                Text(formaterPrixAnnonce(a),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DarColors.primary)),
              ]),
            ),
            IconButton(
              key: Key('retirer-${a.id}'),
              tooltip: 'Retirer des favoris',
              onPressed: onRetirer,
              icon: const Icon(Icons.favorite, color: DarColors.danger),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.type});
  final String? url;
  final TypeBien type;

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        switch (type) {
          TypeBien.villa => Icons.home_outlined,
          TypeBien.terrain => Icons.landscape_outlined,
          TypeBien.local => Icons.storefront_outlined,
          TypeBien.appartement => Icons.apartment_outlined,
        },
        size: 32,
        color: DarColors.primary,
      ),
    );
    if (url == null) return remplacement;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => remplacement,
      loadingBuilder: (_, enfant, progression) => progression == null ? enfant : Container(color: DarColors.surface2),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.titre, required this.texte, required this.bouton});
  final IconData icone;
  final String titre;
  final String texte;
  final Widget bouton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: DarColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icone, size: 32, color: DarColors.primary),
          ),
          const SizedBox(height: 16),
          Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.45, color: DarColors.text2)),
          const SizedBox(height: 20),
          bouton,
        ]),
      ),
    );
  }
}
