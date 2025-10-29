import 'package:flutter/material.dart';
import 'core/firebase_initializer.dart';
import 'ui/admin_gate.dart';
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
      // AdminGate renders its own AppBar/Scaffold and the LoginScreen when needed
      home: const AdminGate(child: MapPage()),
    );
  }
}
