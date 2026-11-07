// =====================================================================
// DarImmo - [1.7] Preuve de concept : chat temps réel + notifications push
// Membre C
//
// Application jetable (hors dépôt officiel) qui vérifie que :
//   1. un message inséré dans Supabase arrive en direct sur un autre appareil ;
//   2. une notification FCM envoyée par l'Edge Function send-push est reçue,
//      et que la toucher ouvre la bonne conversation.
//
// Sert aussi de banc d'essai pour les stories de C en attendant le squelette
// officiel (tâche 1.6) : le module lib/features/publish/ ([6.1]) est
// indépendant de ce fichier et pourra être copié tel quel dans le squelette.
//
// Lancement :
//   flutter run --dart-define-from-file=env.json
// =====================================================================
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/darimmo_theme.dart';
import 'features/publish/data/annonce_repository.dart';
import 'features/publish/ui/publier_annonce_page.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

SupabaseClient get supabase => Supabase.instance.client;
final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Appelé par Android quand une notification arrive alors que l'application
/// est fermée ou en arrière-plan. La notification est affichée par le système ;
/// ici on ne fait rien de plus. Doit être une fonction de haut niveau.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty,
      'Lancer avec --dart-define-from-file=env.json');

  // Firebase (push) seulement sur Android : dans Chrome, on teste uniquement le chat.
  if (!kIsWeb) {
    await Firebase.initializeApp(); // lit android/app/google-services.json
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  runApp(const PocApp());
}

class PocApp extends StatelessWidget {
  const PocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarImmo PoC',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: darimmoTheme(),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, _) => supabase.auth.currentSession == null
            ? const LoginPage()
            : const ConversationsPage(),
      ),
    );
  }
}

// =====================================================================
// Notifications : enregistrement du jeton et réaction aux push
// =====================================================================
class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static StreamSubscription<String>? _refreshSub;
  static bool _listenersReady = false;
  static String? token;

  /// Après la connexion : demande l'autorisation (Android 13+), récupère le
  /// jeton FCM et l'enregistre dans la table device_tokens.
  // getToken / onTokenRefresh sont dépréciés dans firebase_messaging 17 au profit
  // de register() / onRegistered (identifiant d'installation). On garde le jeton
  // FCM classique, que l'API d'envoi FCM v1 de l'Edge Function utilise.
  // ignore_for_file: deprecated_member_use
  static Future<void> register() async {
    if (kIsWeb) return; // pas de push dans le navigateur pour cette preuve de concept
    await _fcm.requestPermission();
    token = await _fcm.getToken();
    if (token != null) await _saveToken(token!);

    _refreshSub ??= _fcm.onTokenRefresh.listen((t) {
      token = t;
      _saveToken(t);
    });

    if (!_listenersReady) {
      _listenersReady = true;
      // Application ouverte : Android n'affiche pas la notification, on montre un bandeau.
      FirebaseMessaging.onMessage.listen((m) {
        messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text('${m.notification?.title ?? 'Notification'}\n${m.notification?.body ?? ''}'),
          action: SnackBarAction(label: 'Ouvrir', onPressed: () => _open(m.data)),
        ));
      });
      // Notification touchée alors que l'application était en arrière-plan.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      // Notification touchée alors que l'application était fermée.
      final initial = await _fcm.getInitialMessage();
      if (initial != null) _open(initial.data);
    }
  }

  static Future<void> _saveToken(String t) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('device_tokens').upsert(
      {'id_user': user.id, 'token': t, 'plateforme': 'android', 'date_maj': DateTime.now().toIso8601String()},
      onConflict: 'token',
    );
  }

  /// À la déconnexion : l'appareil ne doit plus recevoir les push de ce compte.
  static Future<void> unregister() async {
    if (token != null) {
      await supabase.from('device_tokens').delete().eq('token', token!);
    }
  }

  static void _open(Map<String, dynamic> data) {
    if (data['type'] == 'message' && data['id_conversation'] != null) {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: data['id_conversation'] as String, title: 'Conversation'),
      ));
    }
  }
}

// =====================================================================
// Connexion (comptes de test créés pour le seed)
// =====================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'acheteur@darimmo.test');
  final _password = TextEditingController(text: 'Test1234!');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await supabase.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      await PushService.register();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DarImmo – PoC temps réel')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Compte de test :'),
        Wrap(spacing: 8, children: [
          for (final e in ['acheteur@darimmo.test', 'vendeur@darimmo.test'])
            ActionChip(label: Text(e.split('@').first), onPressed: () => _email.text = e),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
        const SizedBox(height: 20),
        FilledButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Connexion…' : 'Se connecter')),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      ]),
    );
  }
}

// =====================================================================
// Liste des conversations (fonction SQL mes_conversations)
// =====================================================================
class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});
  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  RealtimeChannel? _channel;

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase.rpc('mes_conversations');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  void initState() {
    super.initState();
    PushService.register(); // aussi au redémarrage avec une session existante
    // Toute nouvelle activité dans mes conversations rafraîchit la liste.
    _channel = supabase.channel('mes-conversations')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'conversations',
        callback: (_) => setState(() => _future = _load()),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _logout() async {
    await PushService.unregister();
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(supabase.auth.currentUser?.email ?? ''),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Déconnexion')],
      ),
      // [6.1] Publier une annonce
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PublierAnnoncePage(repository: SupabaseAnnonceRepository(supabase)),
        )),
        icon: const Icon(Icons.add),
        label: const Text('Publier une annonce'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return ListView(children: [ListTile(title: Text('Erreur : ${snap.error}'))]);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final convs = snap.data!;
            return ListView(children: [
              ListTile(
                dense: true,
                title: const Text('Jeton FCM de cet appareil'),
                subtitle: SelectableText(PushService.token ?? 'pas encore reçu'),
              ),
              const Divider(),
              if (convs.isEmpty) const ListTile(title: Text('Aucune conversation')),
              for (final c in convs)
                ListTile(
                  leading: CircleAvatar(child: Text((c['nom_interlocuteur'] as String? ?? '?').characters.first)),
                  title: Text('${c['nom_interlocuteur']} · ${c['titre_annonce'] ?? 'annonce supprimée'}'),
                  subtitle: Text(c['dernier_message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: (c['non_lus'] as int) > 0
                      ? Badge(label: Text('${c['non_lus']}'))
                      : null,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatPage(conversationId: c['id'], title: c['nom_interlocuteur']),
                    ));
                    setState(() => _future = _load());
                  },
                ),
            ]);
          },
        ),
      ),
    );
  }
}

// =====================================================================
// Chat temps réel (story 7.2)
// =====================================================================
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId, required this.title});
  final String conversationId;
  final String title;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messages = <Map<String, dynamic>>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  RealtimeChannel? _channel;
  String get _me => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // 1. Abonnement aux nouveaux messages de CETTE conversation.
    _channel = supabase.channel('conv-${widget.conversationId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id_conversation',
          value: widget.conversationId,
        ),
        callback: (payload) {
          final m = payload.newRecord;
          if (_messages.any((x) => x['id'] == m['id'])) return; // déjà affiché
          setState(() => _messages.add(m));
          _scrollDown();
          if (m['id_expediteur'] != _me) _markRead();
        },
      )
      ..subscribe();
  }

  // 2. Historique.
  Future<void> _loadHistory() async {
    final rows = await supabase
        .from('messages')
        .select()
        .eq('id_conversation', widget.conversationId)
        .order('date_envoi');
    setState(() => _messages
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(rows)));
    _scrollDown();
    _markRead();
  }

  Future<void> _markRead() =>
      supabase.rpc('marquer_conversation_lue', params: {'p_conversation': widget.conversationId});

  // 3. Envoi : un simple INSERT. Le destinataire le reçoit par Realtime,
  //    et le webhook déclenche la notification push.
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      final row = await supabase
          .from('messages')
          .insert({'id_conversation': widget.conversationId, 'id_expediteur': _me, 'contenu': text})
          .select()
          .single();
      if (!_messages.any((x) => x['id'] == row['id'])) setState(() => _messages.add(row));
      _scrollDown();
    } catch (e) {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final mine = m['id_expediteur'] == _me;
              final date = DateTime.parse(m['date_envoi']).toLocal();
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF1F3A5F) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(m['contenu'], style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                    Text('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : Colors.black45)),
                  ]),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(hintText: 'Votre message…', border: OutlineInputBorder()),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
