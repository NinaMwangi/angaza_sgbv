import 'package:flutter/material.dart';
import 'router.dart';

class SafeNotesApp extends StatelessWidget {
  const SafeNotesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Notes',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 194, 13, 0),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}

return MaterialApp.router(
  title: 'Notes',   // launcher/OS sees “Notes”
  ...
);
