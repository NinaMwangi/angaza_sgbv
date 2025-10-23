import 'package:flutter/material.dart';
import 'router.dart';

class SafeNotesApp extends StatelessWidget {
  const SafeNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Notes', // decoy app title
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC20D00),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
