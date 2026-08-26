import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/locale.dart';
import 'core/notifications/reminder_engine.dart';
import 'core/router/app_router.dart';
import 'core/theme/galla_theme.dart';
import 'data/galla_repository.dart';
import 'features/lock/lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load intl date symbols before the first frame so DateFormat calls in
  // build methods never hit uninitialized locale data.
  await applyAppLocale('en');
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
      final settings = await repo.loadSettings();
      await repo.saveSettings(settings);
      // Dates and number formatting follow the chosen language immediately.
      await applyAppLocale(settings.locale);
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
