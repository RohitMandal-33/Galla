import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n/locale.dart';
import 'core/notifications/reminder_engine.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/galla_theme.dart';
import 'data/galla_repository.dart';
import 'data/supabase_sync_service.dart';
import 'domain/models.dart';
import 'features/lock/lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

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
      var settings = await repo.loadSettings();
      await applyAppLocale(settings.locale);

      // ── Supabase session reconciliation ──────────────────────────────────
      // On a new install (or after the local DB is wiped) the local
      // `isLoggedIn` flag starts as false even though Supabase may hold a
      // valid session token for a previously-authenticated user.  Recover it
      // here so the router never incorrectly redirects them to /explore.
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null && !settings.isLoggedIn) {
        settings = settings.copyWith(
          isLoggedIn: true,
          authEmail: supabaseUser.email ?? settings.authEmail,
          authIsDemo: false,
          // Returning users have already completed onboarding.
          onboardingDone: true,
        );
        await repo.saveSettings(settings);
      }

      // ── Background sync for cloud users ──────────────────────────────────
      // Pull the latest Supabase data on every cold start so real data
      // appears immediately rather than only after an explicit action.
      if (settings.isLoggedIn && !settings.authIsDemo) {
        ref.read(syncServiceProvider).init();
      }

      // ── Reminder evaluation ───────────────────────────────────────────────
      await repo.saveSettings(settings);
      final engine = ReminderEngine(repo);
      await engine.evaluate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final themeMode = switch (settings?.themeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Galla',
      debugShowCheckedModeBanner: false,
      theme: buildGallaLightTheme(),
      darkTheme: buildGallaDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        GallaColors.currentBrightness = Theme.of(context).brightness;
        return LockGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
