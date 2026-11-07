// =====================================================================
// DarImmo - Discussion en temps réel (story 7.2, membre C)
// Repris tel quel du PoC (tâche 1.7) avec les correctifs du 2026-11-07.
// À FAIRE (7.2) : passer par un ChatRepository + ViewModel comme les
// autres modules, et suivre la maquette C8 (annonce liée en haut…).
// =====================================================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';
import 'package:darimmo/features/chat/data/models/resume_conversation.dart' show formaterJourDiscussion;

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key, required this.client, required this.idConversation, this.titre});
  final SupabaseClient client;
  final String idConversation;

  /// Nom de l'interlocuteur (inconnu quand on arrive par une notification).
  final String? titre;

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final _messages = <Map<String, dynamic>>[];
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  RealtimeChannel? _canal;

  SupabaseClient get _client => widget.client;
  String get _moi => _client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
    // Nouveaux messages de CETTE conversation (RLS : seulement les participants).
    _canal = _client.channel('conv-${widget.idConversation}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id_conversation',
          value: widget.idConversation,
        ),
        callback: (payload) {
          final m = payload.newRecord;
          if (!mounted || _messages.any((x) => x['id'] == m['id'])) return;
          setState(() => _ajouter([m]));
          _descendre();
          if (m['id_expediteur'] != _moi) _marquerLu();
        },
      )
      ..subscribe();
  }

  /// Ajoute puis trie par date d'envoi (puis id) : un message reçu par Realtime
  /// et la réponse de l'INSERT peuvent arriver dans n'importe quel ordre.
  void _ajouter(Iterable<Map<String, dynamic>> nouveaux) {
    for (final m in nouveaux) {
      if (!_messages.any((x) => x['id'] == m['id'])) _messages.add(m);
    }
    _messages.sort((a, b) {
      final d = DateTime.parse(a['date_envoi']).compareTo(DateTime.parse(b['date_envoi']));
      return d != 0 ? d : (a['id'] as num).compareTo(b['id'] as num);
    });
  }

  Future<void> _chargerHistorique() async {
    final lignes = await _client
        .from('messages')
        .select()
        .eq('id_conversation', widget.idConversation)
        .order('date_envoi')
        .order('id');
    if (!mounted) return;
    setState(() => _ajouter(List<Map<String, dynamic>>.from(lignes)));
    _descendre();
    _marquerLu();
  }

  /// [7.3] Remet à zéro les « non lus ». Avec supabase_flutter, une requête
  /// n'est envoyée que si on l'attend (await).
  Future<void> _marquerLu() async {
    try {
      await _client.rpc('marquer_conversation_lue', params: {'p_conversation': widget.idConversation});
    } catch (e) {
      debugPrint('[7.3] marquer_conversation_lue : $e');
    }
  }

  /// Envoi : un simple INSERT. Le destinataire le reçoit par Realtime, et le
  /// webhook push_messages déclenche la notification (8.1).
  Future<void> _envoyer() async {
    final texte = _saisie.text.trim();
    if (texte.isEmpty) return;
    _saisie.clear();
    try {
      final ligne = await _client
          .from('messages')
          .insert({'id_conversation': widget.idConversation, 'id_expediteur': _moi, 'contenu': texte})
          .select()
          .single();
      if (mounted) setState(() => _ajouter([ligne]));
      _descendre();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
      }
    }
  }

  /// La liste est inversée (reverse) : la position 0 est le dernier message.
  void _descendre() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_defilement.hasClients) {
          _defilement.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  /// Messages et séparateurs de jour, du plus RÉCENT au plus ancien.
  List<Widget> _elements() {
    final maintenant = DateTime.now();
    final elements = <Widget>[];
    DateTime? jourPrecedent;
    for (final m in _messages) {
      final date = DateTime.parse(m['date_envoi']).toLocal();
      final jour = DateTime(date.year, date.month, date.day);
      if (jour != jourPrecedent) {
        elements.add(_SeparateurJour(formaterJourDiscussion(date, maintenant)));
        jourPrecedent = jour;
      }
      elements.add(_Bulle(message: m, date: date, moi: m['id_expediteur'] == _moi));
    }
    return elements.reversed.toList();
  }

  @override
  void dispose() {
    if (_canal != null) _client.removeChannel(_canal!);
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elements = _elements();
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? 'Discussion')),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _defilement,
            reverse: true, // s'ouvre toujours sur le dernier message
            padding: const EdgeInsets.all(12),
            itemCount: elements.length,
            itemBuilder: (_, i) => elements[i],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _saisie,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Votre message…'),
                  onSubmitted: (_) => _envoyer(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _envoyer, icon: const Icon(Icons.send_rounded), tooltip: 'Envoyer'),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// « AUJOURD’HUI », « HIER », « MERCREDI 4 NOVEMBRE » (maquette C8).
class _SeparateurJour extends StatelessWidget {
  const _SeparateurJour(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: DarColors.surface2, borderRadius: BorderRadius.circular(8)),
          child: Text(texte.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DarColors.muted)),
        ),
      );
}

class _Bulle extends StatelessWidget {
  const _Bulle({required this.message, required this.date, required this.moi});
  final Map<String, dynamic> message;
  final DateTime date;
  final bool moi;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: moi ? DarColors.primary : DarColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message['contenu'] as String, style: TextStyle(color: moi ? Colors.white : DarColors.text)),
          Text('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: moi ? Colors.white70 : DarColors.muted)),
        ]),
      ),
    );
  }
}
