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
import 'features/publish/models/annonce.dart';
import 'features/publish/ui/publier_annonce_page.dart';
import 'features/photos/data/photos_repository.dart';
import 'features/mes_annonces/data/mes_annonces_repository.dart';
import 'features/mes_annonces/ui/mes_annonces_page.dart';
import 'features/conversations/data/conversations_repository.dart';
import 'features/conversations/models/resume_conversation.dart' show formaterJourDiscussion;
import 'features/conversations/ui/conversations_page.dart';

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
            : const AccueilPage(),
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
    } else if (data['type'] == 'statut') {
      // [8.2] « Annonce publiée / rejetée / masquée » -> Mes annonces (6.3 / 6.5)
      navigatorKey.currentState?.push(mesAnnoncesRoute());
    }
  }
}

// =====================================================================
// Routes des modules de C (6.1 Publier + 6.2 Photos, 6.3 Mes annonces)
// =====================================================================
Route<void> publierAnnonceRoute() => MaterialPageRoute(
      builder: (_) => PublierAnnoncePage(
        repository: SupabaseAnnonceRepository(supabase),
        photosRepository: SupabasePhotosRepository(supabase),
      ),
    );

/// [6.3] Même parcours que la 6.1 (informations puis photos), pré-rempli ;
/// renvoie l'annonce enregistrée.
Route<Annonce> modifierAnnonceRoute(EditionAnnonce edition) => MaterialPageRoute(
      builder: (_) => PublierAnnoncePage(
        repository: SupabaseAnnonceRepository(supabase),
        photosRepository: SupabasePhotosRepository(supabase),
        edition: edition,
      ),
    );

Route<void> mesAnnoncesRoute() => MaterialPageRoute(
      builder: (_) => MesAnnoncesPage(
        repository: SupabaseMesAnnoncesRepository(supabase),
        onPublier: (context) => Navigator.push(context, publierAnnonceRoute()),
        onModifier: (context, edition) => Navigator.push(context, modifierAnnonceRoute(edition)),
      ),
    );

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
// Accueil : « Messages » = mes conversations ([7.3], lib/features/conversations/)
// =====================================================================
class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  @override
  void initState() {
    super.initState();
    PushService.register(); // aussi au redémarrage avec une session existante
  }

  Future<void> _logout() async {
    await PushService.unregister();
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ConversationsPage(
      repository: SupabaseConversationsRepository(supabase),
      onOuvrir: (context, c) => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: c.id, title: c.nomAffiche),
      )),
      actions: [
        // [6.3] Mes annonces
        IconButton(
          onPressed: () => Navigator.push(context, mesAnnoncesRoute()),
          icon: const Icon(Icons.home_work_outlined),
          tooltip: 'Mes annonces',
        ),
        IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Déconnexion'),
        const SizedBox(width: 8),
      ],
      // [6.1] Publier une annonce
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, publierAnnonceRoute()),
        icon: const Icon(Icons.add),
        label: const Text('Publier une annonce'),
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
          if (!mounted || _messages.any((x) => x['id'] == m['id'])) return; // déjà affiché
          setState(() => _ajouter([m]));
          _scrollDown();
          if (m['id_expediteur'] != _me) _markRead();
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

  // 2. Historique.
  Future<void> _loadHistory() async {
    final rows = await supabase
        .from('messages')
        .select()
        .eq('id_conversation', widget.conversationId)
        .order('date_envoi')
        .order('id');
    if (!mounted) return;
    setState(() => _ajouter(List<Map<String, dynamic>>.from(rows)));
    _scrollDown();
    _markRead();
  }

  /// [7.3] Remet à zéro les « non lus ». ATTENTION : avec supabase_flutter, une
  /// requête n'est envoyée que si on l'attend (await) ; l'ancien code renvoyait
  /// la requête sans l'attendre, elle ne partait donc jamais.
  Future<void> _markRead() async {
    try {
      await supabase.rpc('marquer_conversation_lue', params: {'p_conversation': widget.conversationId});
    } catch (e) {
      debugPrint('[7.3] marquer_conversation_lue : $e');
    }
  }

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
      if (mounted) setState(() => _ajouter([row]));
      _scrollDown();
    } catch (e) {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    }
  }

  /// La liste est inversée (reverse) : la position 0 est le bas, le dernier message.
  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  /// Messages et séparateurs de jour, du plus RÉCENT au plus ancien (liste inversée).
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
      elements.add(_Bulle(message: m, date: date, mine: m['id_expediteur'] == _me));
    }
    return elements.reversed.toList();
  }

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
          // reverse : la discussion s'ouvre toujours sur le dernier message.
          child: Builder(builder: (context) {
            final elements = _elements();
            return ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: elements.length,
              itemBuilder: (_, i) => elements[i],
            );
          }),
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

/// « AUJOURD’HUI », « HIER », « MARDI 4 NOVEMBRE » (maquette C8).
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
  const _Bulle({required this.message, required this.date, required this.mine});
  final Map<String, dynamic> message;
  final DateTime date;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? DarColors.primary : DarColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message['contenu'] as String, style: TextStyle(color: mine ? Colors.white : DarColors.text)),
          Text('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : DarColors.muted)),
        ]),
      ),
    );
  }
}
