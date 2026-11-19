import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/auth/presentation/validators_auth.dart';
import 'package:darimmo/features/auth/presentation/viewmodels/etat_compte.dart';
import 'package:darimmo/features/profile/data/repositories/profil_repository.dart';
import 'package:darimmo/features/publish/data/models/photo_annonce.dart';
import 'package:darimmo/features/publish/data/services/choisir_photos.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({
    super.key,
    required this.email,
    required this.repository,
    required this.choisirPhotos,
    required this.onDeconnexion,
    this.compte,
  });

  final String? email;
  final ProfilRepository repository;
  final ChoisirPhotos choisirPhotos;
  final Future<void> Function() onDeconnexion;

  /// [9.1] Rôle du compte : le lien « Espace administration » n'est visible que pour un admin.
  final EtatCompte? compte;

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  DonneesProfil? _donnees;
  PhotoChoisie? _photoChoisie;
  bool _chargement = true;
  bool _enregistrement = false;
  String? _erreur;
  String? _confirmation;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final donnees = await widget.repository.charger();
      if (!mounted) return;
      _donnees = donnees;
      _nom.text = donnees.nom;
      _telephone.text = donnees.telephone ?? '';
    } on ProfilException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _choisirPhoto() async {
    try {
      final photos = await widget.choisirPhotos(1);
      if (photos.isEmpty || !mounted) return;
      setState(() {
        _photoChoisie = photos.first;
        _erreur = null;
        _confirmation = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible d’ouvrir la galerie. Réessayez.');
      }
    }
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _erreur = null;
      _confirmation = null;
    });
    if (!_form.currentState!.validate()) return;

    final telephone = _telephone.text.trim().isEmpty
        ? null
        : normaliserTelephone(_telephone.text);
    setState(() => _enregistrement = true);
    try {
      final donnees = await widget.repository.enregistrer(
        nom: _nom.text.trim(),
        telephone: telephone,
        photo: _photoChoisie,
      );
      if (mounted) {
        setState(() {
          _donnees = donnees;
          _photoChoisie = null;
          _confirmation = 'Votre profil a été mis à jour.';
        });
      }
    } on ProfilException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Text('Mon profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                _CarteIdentite(
                  nom: _donnees?.nom ?? '',
                  email: widget.email,
                  telephone: _donnees?.telephone,
                  photoUrl: _donnees?.photoUrl,
                  photoLocale: _photoChoisie?.octets,
                  onChangerPhoto: _enregistrement ? null : _choisirPhoto,
                ),
                if (_photoChoisie != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Nouvelle photo choisie : touchez « Enregistrer les modifications » pour la garder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: DarColors.text2),
                  ),
                ],
                const SizedBox(height: 22),
                const _TitreSection('Mon espace'),
                _Groupe(children: [
                  _Lien(
                    icone: Icons.home_work_outlined,
                    titre: 'Mes annonces',
                    sousTitre: 'Publier, modifier et suivre la validation',
                    onTap: () => context.push('/mes-annonces'),
                  ),
                  _Lien(
                    icone: Icons.favorite_border,
                    titre: 'Mes favoris',
                    sousTitre: 'Les biens que vous avez gardés',
                    onTap: () => context.go('/favoris'),
                  ),
                  _Lien(
                    icone: Icons.map_outlined,
                    titre: 'Carte des annonces',
                    sousTitre: 'Les biens autour de vous',
                    onTap: () => context.push('/carte'),
                  ),
                ]),
                if (widget.compte case final compte?)
                  ListenableBuilder(
                    listenable: compte,
                    builder: (context, _) => !compte.estAdmin
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _Groupe(children: [
                              _Lien(
                                icone: Icons.shield_outlined,
                                couleur: DarColors.accent,
                                fondIcone: const Color(0xFFF8E9DF),
                                titre: 'Espace administration',
                                sousTitre: 'Annonces en attente, signalements, comptes',
                                onTap: () => context.push('/admin'),
                              ),
                            ]),
                          ),
                  ),
                const SizedBox(height: 22),
                const _TitreSection('Informations personnelles'),
                if (_erreur != null) ...[
                  _BandeauProfil(message: _erreur!, erreur: true),
                  const SizedBox(height: 12),
                ],
                if (_confirmation != null) ...[
                  _BandeauProfil(message: _confirmation!, erreur: false),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DarColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DarColors.border),
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nom,
                          textCapitalization: TextCapitalization.words,
                          validator: validerNom,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _telephone,
                          keyboardType: TextInputType.phone,
                          validator: validerTelephone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone (facultatif)',
                            hintText: '22 345 678',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _enregistrement ? null : _enregistrer,
                            icon: _enregistrement
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_enregistrement ? 'Enregistrement…' : 'Enregistrer les modifications'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _Groupe(children: [
                  _Lien(
                    icone: Icons.logout,
                    couleur: DarColors.danger,
                    fondIcone: DarColors.dangerSoft,
                    titre: 'Se déconnecter',
                    onTap: widget.onDeconnexion,
                    chevron: false,
                  ),
                ]),
                const SizedBox(height: 18),
                const Text(
                  'DarImmo · version 1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: DarColors.muted),
                ),
              ],
            ),
    );
  }
}

/// Carte bleue en haut du profil (maquette A5) : photo, nom, email, téléphone.
class _CarteIdentite extends StatelessWidget {
  const _CarteIdentite({
    required this.nom,
    required this.email,
    required this.telephone,
    required this.photoUrl,
    required this.photoLocale,
    required this.onChangerPhoto,
  });

  final String nom;
  final String? email;
  final String? telephone;
  final String? photoUrl;
  final Uint8List? photoLocale;
  final VoidCallback? onChangerPhoto;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = photoLocale != null
        ? MemoryImage(photoLocale!)
        : (photoUrl == null ? null : NetworkImage(photoUrl!));
    const blancDoux = Color(0xD9FFFFFF);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DarColors.primary, DarColors.primaryDark],
        ),
      ),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: DarColors.primarySoft,
              backgroundImage: image,
              child: image == null ? const Icon(Icons.person, color: DarColors.primary, size: 36) : null,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Material(
              color: DarColors.accent,
              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
              child: IconButton(
                tooltip: 'Changer la photo',
                onPressed: onChangerPhoto,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              nom.trim().isEmpty ? 'Votre nom' : nom.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            if ((email ?? '').isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(email!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: blancDoux)),
            ],
            if ((telephone ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(telephone!, style: const TextStyle(fontSize: 13, color: blancDoux)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(texte.toUpperCase(),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: DarColors.muted, letterSpacing: 0.8)),
      );
}

class _BandeauProfil extends StatelessWidget {
  const _BandeauProfil({required this.message, required this.erreur});

  final String message;
  final bool erreur;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: erreur ? DarColors.dangerSoft : DarColors.successSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              erreur ? Icons.error_outline : Icons.check_circle_outline,
              color: erreur ? DarColors.danger : DarColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      );
}

/// Carte blanche qui regroupe des lignes de menu, séparées par un trait.
class _Groupe extends StatelessWidget {
  const _Groupe({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: DarColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DarColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final (i, enfant) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 68, color: DarColors.border),
            enfant,
          ],
        ]),
      );
}

class _Lien extends StatelessWidget {
  const _Lien({
    required this.icone,
    required this.titre,
    required this.onTap,
    this.sousTitre,
    this.couleur = DarColors.primary,
    this.fondIcone = DarColors.primarySoft,
    this.chevron = true,
  });
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final VoidCallback onTap;
  final Color couleur;
  final Color fondIcone;
  final bool chevron;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: fondIcone, borderRadius: BorderRadius.circular(12)),
          child: Icon(icone, color: couleur, size: 21),
        ),
        title: Text(
          titre,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: couleur == DarColors.danger ? DarColors.danger : DarColors.text,
          ),
        ),
        subtitle: sousTitre == null
            ? null
            : Text(sousTitre!, style: const TextStyle(fontSize: 13, color: DarColors.muted)),
        trailing: chevron ? const Icon(Icons.chevron_right, color: DarColors.muted) : null,
        onTap: onTap,
      );
}
