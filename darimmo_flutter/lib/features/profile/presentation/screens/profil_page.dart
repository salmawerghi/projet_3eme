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
    final photoUrl = _donnees?.photoUrl;
    final photoLocale = _photoChoisie;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: DarColors.primarySoft,
                        backgroundImage: photoLocale != null
                            ? MemoryImage(photoLocale.octets)
                            : (photoUrl == null
                                  ? null
                                  : NetworkImage(photoUrl)),
                        child: photoLocale == null && photoUrl == null
                            ? const Icon(
                                Icons.person,
                                color: DarColors.primary,
                                size: 46,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _enregistrement ? null : _choisirPhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Changer la photo'),
                      ),
                      Text(
                        widget.email ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_erreur != null) ...[
                  _BandeauProfil(message: _erreur!, erreur: true),
                  const SizedBox(height: 16),
                ],
                if (_confirmation != null) ...[
                  _BandeauProfil(message: _confirmation!, erreur: false),
                  const SizedBox(height: 16),
                ],
                Form(
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _enregistrement ? null : _enregistrer,
                          icon: _enregistrement
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _enregistrement
                                ? 'Enregistrement…'
                                : 'Enregistrer les modifications',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 12),
                _Lien(
                  icone: Icons.home_work_outlined,
                  titre: 'Mes annonces',
                  sousTitre: '6.3 · 6.5',
                  onTap: () => context.push('/mes-annonces'),
                ),
                _Lien(
                  icone: Icons.map_outlined,
                  titre: 'Carte des annonces',
                  sousTitre: '4.1 · 4.2 (membre B)',
                  onTap: () => context.push('/carte'),
                ),
                if (widget.compte case final compte?)
                  ListenableBuilder(
                    listenable: compte,
                    builder: (context, _) => compte.estAdmin
                        ? _Lien(
                            icone: Icons.shield_outlined,
                            titre: 'Espace administration',
                            sousTitre: 'Annonces en attente, signalements, comptes',
                            onTap: () => context.push('/admin'),
                          )
                        : const SizedBox.shrink(),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onDeconnexion,
                  icon: const Icon(Icons.logout, color: DarColors.danger),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: DarColors.danger),
                  ),
                ),
              ],
            ),
    );
  }
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

class _Lien extends StatelessWidget {
  const _Lien({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: DarColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DarColors.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icone, color: DarColors.primary),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}
