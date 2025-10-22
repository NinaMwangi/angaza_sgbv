import 'package:flutter/material.dart';
import 'router.dart';

class SafeNotesApp extends StatelessWidget {
  const SafeNotesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Notes',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
