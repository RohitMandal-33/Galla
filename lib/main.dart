import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/reminder_engine.dart';
import 'core/router/app_router.dart';
import 'core/theme/galla_theme.dart';
import 'data/galla_repository.dart';
import 'features/lock/lock_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: GallaApp()));
}

class GallaApp extends ConsumerStatefulWidget {
  const GallaApp({super.key});

  @override
  ConsumerState<GallaApp> createState() => _GallaAppState();
}

class _GallaAppState extends ConsumerState<GallaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(repositoryProvider);
      await repo.saveSettings(await repo.loadSettings());
      final engine = ReminderEngine(repo);
      await engine.evaluate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Galla',
      debugShowCheckedModeBanner: false,
      theme: buildGallaTheme(),
      routerConfig: router,
      builder: (context, child) =>
          LockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
