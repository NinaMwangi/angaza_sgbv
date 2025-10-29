import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/decoy_notes/presentation/notes_screen.dart';
import 'features/sos/presentation/sos_screen.dart';
import 'features/contacts/presentation/contacts_screen.dart';
import 'features/incidents/presentation/recording_incidents_screen.dart';
import 'features/auth/login_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

//final appRouter = GoRouter(
  //routes: [
    //GoRoute(path: '/', builder: (_, __) => const NotesScreen()),
    //GoRoute(path: '/sos', builder: (_, __) => const SosScreen()),
  //],
//);

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  routes: [
    GoRoute(path: '/',     name: 'notes',    builder: (_, __) => const NotesScreen()),
    GoRoute(path: '/sos',  name: 'sos',      builder: (_, __) => const SosScreen()),
    GoRoute(path: '/contacts', name: 'contacts', builder: (_, __) => const ContactsScreen()),
    GoRoute(path: '/history',  name: 'history',  builder: (_, __) => const RecordingsIncidentsScreen()),
    GoRoute(path: '/login', builder: (_, __)=> const LoginScreen()),
  ],
);
