// =====================================================================
// DarImmo - [6.2] Écran « Photos » (maquette C2, étape 2 de la publication)
// Membre C
//
// Critères d'acceptation :
//   - jusqu'à 10 photos ; aperçu avant envoi (l'image s'affiche tout de suite)
//   - suppression (croix) et changement d'ordre (appui long + glisser)
//   - compression avant envoi (choisir_photos.dart)
//   - fichiers dans annonces-photos/{id_annonce}/ (photos_repository.dart)
//   - échec d'envoi : message clair + bouton « Réessayer » sur la photo
// =====================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/publish/data/services/choisir_photos.dart';
import 'package:darimmo/features/publish/data/repositories/photos_repository.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';
import 'package:darimmo/features/publish/presentation/viewmodels/photos_view_model.dart';

/// Ferme l'écran avec `true` quand le parcours est terminé (voir [onSuivant]),
/// ou `null` si l'utilisateur revient au formulaire.
class PhotosAnnoncePage extends StatelessWidget {
  const PhotosAnnoncePage({
    super.key,
    required this.repository,
    required this.idAnnonce,
    required this.onSuivant,
    this.choisir = choisirDansLaGalerie,
    this.libelleBouton = 'Continuer',
    this.iconeBouton = Icons.arrow_forward_rounded,
  });

  final PhotosRepository repository;
  final String idAnnonce;
  final ChoisirPhotos choisir;
  final String libelleBouton;
  final IconData iconeBouton;

  /// Bouton principal, appelé une fois toutes les photos envoyées (ex : ouvre
  /// l'étape « Emplacement »). true = parcours terminé, l'écran se ferme ;
  /// false = on reste sur les photos (l'utilisateur est revenu en arrière).
  final Future<bool> Function(BuildContext context) onSuivant;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhotosViewModel(repository, idAnnonce, choisir)..charger(),
      child: _Contenu(libelleBouton: libelleBouton, iconeBouton: iconeBouton, onSuivant: onSuivant),
    );
  }
}

class _Contenu extends StatefulWidget {
  const _Contenu({required this.libelleBouton, required this.iconeBouton, required this.onSuivant});
  final String libelleBouton;
  final IconData iconeBouton;
  final Future<bool> Function(BuildContext context) onSuivant;

  @override
  State<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends State<_Contenu> {
  bool _validation = false;

  Future<void> _valider() async {
    final vm = context.read<PhotosViewModel>();
    setState(() => _validation = true);
    await vm.termine; // dernières suppressions / renumérotations
    if (!mounted) return;
    final fini = await widget.onSuivant(context);
    if (!mounted) return;
    if (fini) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _validation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhotosViewModel>();
    final premierEchec = vm.tuiles.where((t) => t.etat == EtatPhoto.echec).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Étape 2 sur 3',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DarColors.muted)),
        ]),
      ),
      body: vm.chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              children: [
                const _Bandeau(
                  icone: Icons.image_outlined,
                  texte: 'Ajoutez jusqu’à $photosMax photos. La première est la photo de couverture. '
                      'Les photos sont compressées avant l’envoi.',
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: Text('Photos (${vm.nombre}/$photosMax)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  TextButton.icon(
                    onPressed: vm.peutAjouter ? vm.ajouter : null,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galerie'),
                  ),
                ]),
                const SizedBox(height: 8),
                _Grille(vm: vm),
                if (premierEchec != null) ...[
                  const SizedBox(height: 16),
                  _Bandeau(
                    icone: Icons.error_outline,
                    danger: true,
                    texte: '${premierEchec.erreur ?? 'Une photo n’a pas pu être envoyée.'} '
                        'Touchez « Réessayer » sur la photo, ou retirez-la.',
                  ),
                ],
                if (vm.erreur != null) ...[
                  const SizedBox(height: 16),
                  _Bandeau(icone: Icons.error_outline, danger: true, texte: vm.erreur!),
                ],
                if (vm.nombre > 1) ...[
                  const SizedBox(height: 16),
                  const Row(children: [
                    Icon(Icons.drag_indicator, size: 16, color: DarColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Maintenez une photo et glissez-la pour changer l’ordre.',
                          style: TextStyle(fontSize: 12, color: DarColors.muted)),
                    ),
                  ]),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: DarColors.surface,
            border: Border(top: BorderSide(color: DarColors.border)),
          ),
          child: Row(children: [
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: _validation ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: (_validation || !vm.pret || vm.chargement) ? null : _valider,
                icon: _validation || vm.envoisEnCours
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Icon(widget.iconeBouton),
                label: Text(vm.envoisEnCours ? 'Envoi des photos…' : widget.libelleBouton,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Grille de 3 colonnes : photos + case « Ajouter ».
class _Grille extends StatelessWidget {
  const _Grille({required this.vm});
  final PhotosViewModel vm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const ecart = 10.0;
      final taille = (c.maxWidth - 2 * ecart) / 3;
      return Wrap(spacing: ecart, runSpacing: ecart, children: [
        for (final (i, t) in vm.tuiles.indexed)
          _CaseDeplacable(key: ValueKey(t.cle), index: i, taille: taille, vm: vm, tuile: t),
        if (vm.peutAjouter) _CaseAjouter(taille: taille, onTap: vm.ajouter),
      ]);
    });
  }
}

/// Appui long pour soulever la photo, puis la lâcher sur une autre case.
class _CaseDeplacable extends StatelessWidget {
  const _CaseDeplacable({super.key, required this.index, required this.taille, required this.vm, required this.tuile});
  final int index;
  final double taille;
  final PhotosViewModel vm;
  final TuilePhoto tuile;

  @override
  Widget build(BuildContext context) {
    final photo = _CasePhoto(tuile: tuile, taille: taille, couverture: index == 0, vm: vm);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => vm.deplacer(d.data, index),
      builder: (context, candidats, _) => LongPressDraggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.85, child: _CasePhoto(tuile: tuile, taille: taille, couverture: false, vm: vm)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: photo),
        // foregroundDecoration : la bordure est dessinée PAR-DESSUS, sans
        // agrandir la case (sinon la grille de 3 colonnes passe à 2).
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: candidats.isEmpty ? Colors.transparent : DarColors.primary, width: 2),
          ),
          child: photo,
        ),
      ),
    );
  }
}

class _CasePhoto extends StatelessWidget {
  const _CasePhoto({required this.tuile, required this.taille, required this.couverture, required this.vm});
  final TuilePhoto tuile;
  final double taille;
  final bool couverture;
  final PhotosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = tuile;
    final secours = Container(
      color: DarColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: DarColors.primary),
    );
    final image = t.choisie != null
        ? Image.memory(t.choisie!.octets, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => secours)
        : Image.network(t.enregistree!.url, fit: BoxFit.cover, errorBuilder: (_, _, _) => secours);

    return SizedBox(
      width: taille,
      height: taille,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          image,
          if (t.etat == EtatPhoto.envoi)
            Container(
              color: const Color(0x990B1220),
              alignment: Alignment.center,
              child: const SizedBox(
                  width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
            ),
          if (t.etat == EtatPhoto.echec)
            Material(
              color: DarColors.danger.withValues(alpha: 0.8),
              child: InkWell(
                onTap: () => vm.reessayer(t),
                child: const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 24, color: Colors.white),
                    SizedBox(height: 4),
                    Text('Réessayer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          // Haut : « COUVERTURE » + croix
          Positioned(
            left: 6,
            right: 6,
            top: 6,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Flexible + FittedBox : la pastille rétrécit sur les petites cases.
              if (couverture && t.etat == EtatPhoto.envoyee)
                const Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _Pastille('COUVERTURE')),
                ),
              const Spacer(),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Retirer la photo',
                child: GestureDetector(
                  onTap: () => vm.retirer(t),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: Color(0x8C0B1220), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
          // Bas : état
          if (t.etat != EtatPhoto.envoyee)
            Positioned(
              left: 8,
              bottom: 6,
              child: Text(t.etat == EtatPhoto.envoi ? 'Envoi…' : 'Échec',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            )
          else
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: const Color(0x8C0B1220), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.drag_indicator, size: 15, color: Colors.white),
              ),
            ),
        ]),
      ),
    );
  }
}

class _CaseAjouter extends StatelessWidget {
  const _CaseAjouter({required this.taille, required this.onTap});
  final double taille;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: taille,
      height: taille,
      child: Material(
        color: DarColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DarColors.primary, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, size: 26, color: DarColors.primary),
            SizedBox(height: 6),
            Text('Ajouter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DarColors.primary)),
          ]),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: DarColors.primary, borderRadius: BorderRadius.circular(8)),
        child: Text(texte, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.texte, this.danger = false});
  final IconData icone;
  final String texte;
  final bool danger;
  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: danger ? DarColors.danger : DarColors.primaryDark)),
        ),
      ]),
    );
  }
}
