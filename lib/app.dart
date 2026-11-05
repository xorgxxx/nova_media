import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/home/home_shell.dart';

class NovaMediaApp extends StatelessWidget {
  const NovaMediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Media',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
