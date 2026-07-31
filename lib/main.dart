import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  // Fonts ship in assets/fonts/, so nothing should ever be pulled from the
  // Google Fonts CDN. Turning fetching off keeps the app fully offline-capable
  // and makes a missing variant fail loudly instead of silently hitting the
  // network.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const TaskDiceApp());
}

class TaskDiceApp extends StatelessWidget {
  const TaskDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskDice',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
