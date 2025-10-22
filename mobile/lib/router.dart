import 'package:go_router/go_router.dart';
import 'features/decoy_notes/presentation/notes_screen.dart';
import 'features/sos/presentation/sos_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const NotesScreen()),
    GoRoute(path: '/sos', builder: (_, __) => const SosScreen()),
  ],
);
