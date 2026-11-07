// =====================================================================
// DarImmo - Application (tâche 1.6) : thème v3 + navigation go_router
// =====================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:darimmo/core/theme/darimmo_theme.dart';

/// Pour afficher un bandeau depuis n'importe où (ex : notification reçue).
final cleMessager = GlobalKey<ScaffoldMessengerState>();

class DarImmoApp extends StatelessWidget {
  const DarImmoApp({super.key, required this.routeur});

  /// Créé par creerRouteur(...) (core/router/app_router.dart).
  final GoRouter routeur;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DarImmo',
      debugShowCheckedModeBanner: false,
      theme: darimmoTheme(),
      scaffoldMessengerKey: cleMessager,
      routerConfig: routeur,
    );
  }
}
