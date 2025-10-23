import 'package:flutter/material.dart';
import 'router.dart';

class SafeNotesApp extends StatelessWidget {
  const SafeNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(seedColor: const Color(0xFFC20D00), brightness: Brightness.light);
    final dark  = ColorScheme.fromSeed(seedColor: const Color(0xFFC20D00), brightness: Brightness.dark);

    return MaterialApp.router(
      title: 'Notes', // decoy
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(colorScheme: light, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: dark,  useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
