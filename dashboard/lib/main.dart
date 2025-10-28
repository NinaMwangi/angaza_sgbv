import 'package:flutter/material.dart';
import 'core/firebase_initializer.dart';
import 'ui/map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInit.init();
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Angaza Dashboard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: Scaffold(
        appBar: AppBar(title: const Text('Angaza — Incidents Map')),
        body: const MapPage(),
      ),
    );
  }
}
