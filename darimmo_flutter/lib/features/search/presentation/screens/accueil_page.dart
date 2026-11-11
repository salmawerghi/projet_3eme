// =====================================================================
// DarImmo - [3.1] Voir la liste des annonces · [3.2] Filtrer (maquettes B1-B2)
// Membre B (version d'origine), restructuré pour le squelette 1.6
//
// Critères 3.1 : seules les annonces publiées ; photo, titre, prix, ville,
//   surface ; chargement progressif ; indicateur de chargement ; message si vide.
// Critères 3.2 : prix min/max, ville, type, vente/location, pièces minimum ;
//   liste mise à jour après application ; « Aucun bien trouvé » ; Réinitialiser.
// Toucher une annonce ouvre son détail (route /annonces/:id, story 3.3).
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart' show TypeBien, TypeOffre;
import 'package:darimmo/features/search/data/models/annonce_recherche.dart';
import 'package:darimmo/features/search/data/repositories/recherche_repository.dart';
import 'package:darimmo/features/search/presentation/viewmodels/accueil_view_model.dart';
import 'package:darimmo/features/search/presentation/widgets/carte_annonce_recherche.dart';
import 'package:darimmo/features/search/presentation/widgets/feuille_filtres.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({
    super.key,
    required this.repository,
    required this.onOuvrir,
    this.onVoirCarte,
    this.maintenant,
  });

  final RechercheRepository repository;
  final void Function(BuildContext context, AnnonceRecherche annonce) onOuvrir;
  final void Function(BuildContext context)? onVoirCarte;

  /// Heure de référence pour « il y a 2 h » (fixée dans les tests).
  final DateTime Function()? maintenant;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccueilViewModel(repository)..demarrer(),
      child: _Contenu(page: this),
    );
  }
}

class _Contenu extends StatefulWidget {
  const _Contenu({required this.page});
  final AccueilPage page;

  @override
  State<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends State<_Contenu> {
  final _defilement = ScrollController();
  final _recherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _defilement.addListener(() {
      if (_defilement.position.extentAfter < 400) context.read<AccueilViewModel>().chargerSuite();
    });
  }

  @override
  void dispose() {
    _defilement.dispose();
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _ouvrirFiltres(AccueilViewModel vm) async {
    final nouveau = await ouvrirFeuilleFiltres(context, initial: vm.filtre, compter: vm.compter, villes: vm.villes);
    if (nouveau != null) await vm.appliquer(nouveau);
  }

  /// « Tout » efface aussi la barre de recherche, pour que l'écran reste cohérent.
  Future<void> _toutAfficher(AccueilViewModel vm) {
    _recherche.clear();
    return vm.toutAfficher();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccueilViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text('Trouvez votre chez-vous',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DarColors.text)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _recherche,
                  builder: (context, valeur, _) => TextField(
                    controller: _recherche,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Ville, quartier, titre…',
                      prefixIcon: const Icon(Icons.search, color: DarColors.muted),
                      suffixIcon: valeur.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _recherche.clear();
                                vm.chercher('');
                              },
                            ),
                    ),
                    onSubmitted: vm.chercher,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: vm.filtre.nbFiltresFeuille > 0,
                label: Text('${vm.filtre.nbFiltresFeuille}'),
                backgroundColor: DarColors.accent,
                child: IconButton.filled(
                  tooltip: 'Filtres',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _ouvrirFiltres(vm),
                  icon: const Icon(Icons.tune),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _Puces(vm: vm, onTout: () => _toutAfficher(vm)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(children: [
              Expanded(
                child: Text(vm.filtre.estVide ? 'Annonces récentes' : 'Résultats',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DarColors.text)),
              ),
              if (widget.page.onVoirCarte case final voir?)
                TextButton.icon(
                  onPressed: () => voir(context),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Voir la carte'),
                ),
            ]),
          ),
          Expanded(child: _corps(vm)),
        ]),
      ),
    );
  }

  Widget _corps(AccueilViewModel vm) {
    if (vm.premierChargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erreur case final message?) {
      return _Message(
        icone: Icons.wifi_off_rounded,
        titre: 'Impossible de charger les annonces',
        texte: message,
        bouton: 'Réessayer',
        action: vm.recharger,
      );
    }
    if (vm.annonces.isEmpty) {
      return vm.filtre.estVide
          ? const _Message(
              icone: Icons.home_work_outlined,
              titre: 'Aucune annonce pour l’instant',
              texte: 'Les nouvelles annonces apparaîtront ici dès leur publication.',
            )
          : _Message(
              icone: Icons.search_off_rounded,
              titre: 'Aucun bien trouvé',
              texte: 'Essayez d’élargir vos critères.',
              bouton: 'Réinitialiser les filtres',
              action: () => _toutAfficher(vm),
            );
    }

    final maintenant = (widget.page.maintenant ?? DateTime.now)();
    final annonces = vm.annonces;
    final avecPied = vm.aEncore || vm.erreurSuite != null;
    return RefreshIndicator(
      onRefresh: vm.recharger,
      child: ListView.builder(
        controller: _defilement,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: annonces.length + (avecPied ? 1 : 0),
        itemBuilder: (context, i) {
          if (i < annonces.length) {
            return CarteAnnonceRecherche(
              annonce: annonces[i],
              maintenant: maintenant,
              onTap: () => widget.page.onOuvrir(context, annonces[i]),
            );
          }
          if (vm.erreurSuite case final message?) {
            return Column(children: [
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: DarColors.danger)),
              TextButton(onPressed: vm.reessayerSuite, child: const Text('Réessayer')),
            ]);
          }
          // Le pied de liste est visible : on demande la suite (utile aussi quand
          // la première page ne remplit pas l'écran et qu'on ne peut pas défiler).
          if (!vm.chargement) WidgetsBinding.instance.addPostFrameCallback((_) => vm.chargerSuite());
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(width: 10),
              Text('Chargement des annonces suivantes…',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
            ]),
          );
        },
      ),
    );
  }
}

/// Puces rapides de la maquette B1 : toucher une puce active la désactive.
class _Puces extends StatelessWidget {
  const _Puces({required this.vm, required this.onTout});
  final AccueilViewModel vm;
  final VoidCallback onTout;

  @override
  Widget build(BuildContext context) {
    final f = vm.filtre;
    Widget puce(String libelle, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(label: Text(libelle), selected: active, onSelected: (_) => onTap()),
        );
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          puce('Tout', f.estVide, onTout),
          puce('Vente', f.typeOffre == TypeOffre.vente, () => vm.basculerOffre(TypeOffre.vente)),
          puce('Location', f.typeOffre == TypeOffre.location, () => vm.basculerOffre(TypeOffre.location)),
          for (final t in [TypeBien.appartement, TypeBien.villa, TypeBien.terrain])
            puce(t.libelle, f.typeBien == t, () => vm.basculerType(t)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.titre, required this.texte, this.bouton, this.action});
  final IconData icone;
  final String titre;
  final String texte;
  final String? bouton;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      children: [
        Icon(icone, size: 56, color: DarColors.muted),
        const SizedBox(height: 16),
        Text(titre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DarColors.text)),
        const SizedBox(height: 6),
        Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: DarColors.text2)),
        if (bouton != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: action, child: Text(bouton!)),
        ],
      ],
    );
  }
}
