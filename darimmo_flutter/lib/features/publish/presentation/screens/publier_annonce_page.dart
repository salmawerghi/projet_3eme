// =====================================================================
// DarImmo - [6.1] Écran « Publier une annonce » (maquette C1) — étape 1 sur 2
// Membre C
//
// Critères d'acceptation :
//   - champs : titre, type, offre, prix, surface, pièces, adresse, ville, description
//   - validation des champs obligatoires
//   - statut « en attente de validation » après envoi
//   - id_annonceur = utilisateur connecté
//
// Parcours (avec la 6.2) :
//   1. Informations -> « Continuer » : annonce enregistrée en BROUILLON
//   2. Photos (PhotosAnnoncePage, 6.2) -> « Continuer »
//   3. Emplacement (PositionAnnoncePage, 6.4) -> « Envoyer pour validation » :
//      position enregistrée + EN ATTENTE
//      puis écran « Annonce envoyée ! »
// =====================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/services/choisir_photos.dart';
import 'package:darimmo/features/publish/data/repositories/photos_repository.dart';
import 'package:darimmo/features/publish/presentation/screens/photos_annonce_page.dart';
import 'package:darimmo/core/location/geocodage.dart';
import 'package:darimmo/core/location/localisation.dart';
import 'package:darimmo/features/publish/presentation/screens/position_annonce_page.dart';
import 'package:darimmo/features/publish/data/repositories/annonce_repository.dart';
import 'package:darimmo/features/publish/data/models/annonce.dart';
import 'package:darimmo/features/publish/presentation/viewmodels/publier_annonce_view_model.dart';
import 'package:darimmo/features/publish/presentation/validators.dart';
import 'package:darimmo/features/publish/presentation/screens/annonce_envoyee_page.dart';

/// Sert aussi à MODIFIER une annonce (6.3) quand [edition] est fourni :
/// le formulaire est pré-rempli, et l'écran se ferme en renvoyant l'[Annonce]
/// enregistrée (Navigator.pop) au lieu d'ouvrir l'écran de confirmation.
class PublierAnnoncePage extends StatelessWidget {
  const PublierAnnoncePage({
    super.key,
    required this.repository,
    required this.photosRepository,
    this.choisirPhotos = choisirDansLaGalerie,
    this.geocodage,
    this.localisation = const GeolocatorLocalisation(),
    this.afficherTuiles = true,
    this.edition,
  });
  final AnnonceRepository repository;
  final EditionAnnonce? edition;

  // Étape 2 (6.2)
  final PhotosRepository photosRepository;
  final ChoisirPhotos choisirPhotos;

  // Étape 3 (6.4) ; null = Nominatim (OpenStreetMap)
  final Geocodage? geocodage;
  final Localisation localisation;
  final bool afficherTuiles; // false dans les tests

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PublierAnnonceViewModel(repository, edition: edition),
      child: _Formulaire(page: this),
    );
  }
}

class _Formulaire extends StatefulWidget {
  const _Formulaire({required this.page});
  final PublierAnnoncePage page;
  @override
  State<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends State<_Formulaire> {
  final _form = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _prix = TextEditingController();
  final _surface = TextEditingController();
  final _adresse = TextEditingController();
  final _ville = TextEditingController();
  final _description = TextEditingController();
  late final Geocodage _geocodage = widget.page.geocodage ?? NominatimGeocodage();

  @override
  void initState() {
    super.initState();
    final v = context.read<PublierAnnonceViewModel>().edition?.valeurs;
    if (v != null) {
      _titre.text = v.titre;
      _prix.text = formaterPrix(v.prix); // « 385 000 » : relu par lireNombre
      _surface.text = formaterPrix(v.surface);
      _adresse.text = v.adresse ?? '';
      _ville.text = v.ville;
      _description.text = v.description ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_titre, _prix, _surface, _adresse, _ville, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    final vm = context.read<PublierAnnonceViewModel>();
    FocusScope.of(context).unfocus();
    final champsOk = _form.currentState!.validate();
    final choixOk = vm.verifierChoix();
    if (!champsOk || !choixOk) return;

    final annonce = await vm.envoyer(NouvelleAnnonce(
      titre: _titre.text,
      typeBien: vm.typeBien!,
      typeOffre: vm.typeOffre,
      prix: lireNombre(_prix.text)!,
      surface: lireNombre(_surface.text)!,
      nbPieces: vm.nbPieces,
      ville: _ville.text,
      adresse: _adresse.text,
      description: _description.text,
    ));
    if (annonce == null || !mounted) return;

    // Étapes 2 (photos) puis 3 (emplacement). `true` = parcours terminé ;
    // null = l'utilisateur est revenu au formulaire.
    final page = widget.page;
    final termine = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PhotosAnnoncePage(
        repository: page.photosRepository,
        idAnnonce: annonce.id,
        choisir: page.choisirPhotos,
        onSuivant: (ctx) async =>
            await Navigator.of(ctx).push<bool>(MaterialPageRoute(
              builder: (_) => PositionAnnoncePage(
                geocodage: _geocodage,
                localisation: page.localisation,
                afficherTuiles: page.afficherTuiles,
                positionInitiale: vm.positionInitiale,
                rechercheInitiale: vm.rechercheInitiale,
                libelleBouton: vm.libelleValidation,
                iconeBouton: vm.libelleValidation == 'Terminer' ? Icons.check_rounded : Icons.send_rounded,
                onValider: vm.finaliser,
              ),
            )) ==
            true,
      ),
    ));
    if (termine != true || !mounted) return;

    final finale = vm.enregistree!;
    if (vm.modification) {
      Navigator.of(context).pop(finale); // retour à « Mes annonces »
    } else {
      // Écran « Annonce envoyée ! » par-dessus le formulaire, puis on ferme les deux.
      // (Pas de pushReplacement : le formulaire est une page go_router, qu'il ne
      // faut pas remplacer par une route Navigator classique.)
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnnonceEnvoyeePage(annonce: finale)));
      if (mounted) Navigator.of(context).pop(finale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PublierAnnonceViewModel>();
    final nombres = [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]'))];
    // Pour une création, l'annonce devient un brouillon après l'étape 1 :
    // on garde quand même les textes de publication.
    final statut = vm.creation ? null : vm.edition?.statut;
    final (titreEcran, bandeau) = switch (statut) {
      null => (
          'Publier une annonce',
          'Votre annonce sera vérifiée par un administrateur avant d’être visible par tous.',
        ),
      StatutAnnonce.rejetee || StatutAnnonce.brouillon => (
          'Modifier l’annonce',
          'Corrigez votre annonce : elle sera de nouveau vérifiée par un administrateur.',
        ),
      StatutAnnonce.publiee => (
          'Modifier l’annonce',
          'Votre annonce est en ligne. Si vous la modifiez, elle sera retirée le temps qu’un administrateur valide les changements.',
        ),
      _ => (
          'Modifier l’annonce',
          'Votre annonce est en cours de vérification par un administrateur.',
        ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titreEcran, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('Étape 1 sur 3 · Informations',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
        ]),
      ),
      // SingleChildScrollView + Column (et non ListView) : une ListView ne construit
      // que les champs visibles, et Form.validate() ignorerait les autres.
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Bandeau(icone: Icons.verified_user_outlined, texte: bandeau),
            const _Titre('Je souhaite'),
            _Selecteur(
              options: TypeOffre.values,
              actif: vm.typeOffre,
              libelle: (o) => o.libelle,
              onChoix: vm.choisirOffre,
            ),
            const _Titre('Type de bien'),
            Row(children: [
              for (final t in TypeBien.values) ...[
                if (t != TypeBien.values.first) const SizedBox(width: 8),
                Expanded(
                  child: _TuileType(
                    type: t,
                    actif: vm.typeBien == t,
                    erreur: vm.typeBienManquant,
                    onTap: () => vm.choisirType(t),
                  ),
                ),
              ],
            ]),
            if (vm.typeBienManquant)
              const _MessageErreur('Choisissez un type de bien'),
            const _Titre('Titre de l’annonce'),
            TextFormField(
              controller: _titre,
              maxLength: titreMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Ex : Appartement S+3 haut standing'),
              validator: validerTitre,
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Titre('Prix', haut: 8),
                  TextFormField(
                    controller: _prix,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: nombres,
                    decoration: InputDecoration(
                      hintText: 'Ex : 385 000',
                      suffixText: vm.typeOffre == TypeOffre.location ? 'DT/mois' : 'DT',
                    ),
                    validator: validerPrix,
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Titre('Surface', haut: 8),
                  TextFormField(
                    controller: _surface,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: nombres,
                    decoration: const InputDecoration(hintText: 'Ex : 120', suffixText: 'm²'),
                    validator: validerSurface,
                  ),
                ]),
              ),
            ]),
            if (vm.typeBien?.aDesPieces ?? true) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Nombre de pièces', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('${libellePieces(vm.nbPieces)} · chambres + salon',
                        style: const TextStyle(fontSize: 12, color: DarColors.muted)),
                  ]),
                ),
                _Compteur(valeur: vm.nbPieces, onChange: vm.changerPieces),
              ]),
            ],
            const _Titre('Adresse (facultatif)'),
            TextFormField(
              controller: _adresse,
              decoration: const InputDecoration(
                hintText: 'Ex : Rue du Lac Léman, Les Berges du Lac',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const _Titre('Ville'),
            TextFormField(
              controller: _ville,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Ex : La Marsa, Tunis'),
              validator: validerVille,
            ),
            const _Titre('Description (facultatif)'),
            TextFormField(
              controller: _description,
              maxLength: descriptionMax,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Étage, ascenseur, chauffage, parking, proximité des écoles…',
              ),
              validator: validerDescription,
            ),
            if (vm.erreur != null) ...[
              const SizedBox(height: 8),
              _Bandeau(icone: Icons.error_outline, texte: vm.erreur!, danger: true),
            ],
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: DarColors.surface,
            border: Border(top: BorderSide(color: DarColors.border)),
          ),
          child: FilledButton.icon(
            onPressed: vm.envoiEnCours ? null : _envoyer,
            icon: vm.envoiEnCours
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(vm.envoiEnCours ? 'Enregistrement…' : 'Continuer'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Petits composants de l'écran (repris de la maquette v3)
// ---------------------------------------------------------------------
class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.haut = 18});
  final String texte;
  final double haut;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: haut, bottom: 8),
        child: Text(texte, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DarColors.text)),
      );
}

class _MessageErreur extends StatelessWidget {
  const _MessageErreur(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Row(children: [
          const Icon(Icons.error_outline, size: 15, color: DarColors.danger),
          const SizedBox(width: 6),
          Text(texte, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DarColors.danger)),
        ]),
      );
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.texte, this.danger = false});
  final IconData icone;
  final String texte;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final couleur = danger ? DarColors.danger : DarColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: danger ? DarColors.dangerSoft : DarColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 18, color: danger ? DarColors.danger : DarColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texte,
              style: TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: couleur)),
        ),
      ]),
    );
  }
}

/// Sélecteur à deux options (Vendre / Louer).
class _Selecteur<T> extends StatelessWidget {
  const _Selecteur({required this.options, required this.actif, required this.libelle, required this.onChoix});
  final List<T> options;
  final T actif;
  final String Function(T) libelle;
  final void Function(T) onChoix;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: o == actif,
              child: GestureDetector(
                onTap: () => onChoix(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o == actif ? DarColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: o == actif
                        ? const [BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Text(libelle(o),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: o == actif ? FontWeight.w800 : FontWeight.w600,
                        color: o == actif ? DarColors.text : DarColors.muted,
                      )),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _TuileType extends StatelessWidget {
  const _TuileType({required this.type, required this.actif, required this.erreur, required this.onTap});
  final TypeBien type;
  final bool actif;
  final bool erreur;
  final VoidCallback onTap;

  static const _icones = {
    TypeBien.appartement: Icons.apartment_rounded,
    TypeBien.villa: Icons.villa_outlined,
    TypeBien.terrain: Icons.landscape_outlined,
    TypeBien.local: Icons.storefront_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? DarColors.primary : DarColors.text2;
    return Material(
      color: actif ? DarColors.primarySoft : DarColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: actif ? DarColors.primary : (erreur ? DarColors.danger : DarColors.border),
          width: actif || erreur ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_icones[type], size: 24, color: couleur),
            const SizedBox(height: 8),
            Text(type.libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: actif ? FontWeight.w800 : FontWeight.w600, color: couleur)),
          ]),
        ),
      ),
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({required this.valeur, required this.onChange});
  final int valeur;
  final void Function(int delta) onChange;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarColors.surface,
        border: Border.all(color: DarColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        IconButton(
          tooltip: 'Une pièce de moins',
          onPressed: valeur > 1 ? () => onChange(-1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 30,
          child: Text('$valeur',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        IconButton(
          tooltip: 'Une pièce de plus',
          onPressed: valeur < piecesMax ? () => onChange(1) : null,
          icon: const Icon(Icons.add, size: 18, color: DarColors.primary),
        ),
      ]),
    );
  }
}
