import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/galla_components.dart';

import '../../features/analytics/view/analytics_screen.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/business/view/branches_screen.dart';
import '../../features/business/view/business_profile_screen.dart';
import '../../features/business/view/staff_screen.dart';
import '../../features/business/view/more_screen.dart';
import '../../features/explore/view/explore_screen.dart';
import '../../features/galla/view/galla_screen.dart';
import '../../features/inventory/view/inventory_screen.dart';
import '../../features/invoicing/view/create_invoice_screen.dart';
import '../../features/invoicing/view/invoice_detail_screen.dart';
import '../../features/invoicing/view/invoices_screen.dart';
import '../../features/ledger/view/ledger_screen.dart';
import '../../features/ledger/view/party_detail_screen.dart';
import '../../features/ledger/view/transaction_detail_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/reconciliation/view/reconciliation_screen.dart';
import '../../features/splash/view/splash_screen.dart';
import '../../features/reports/view/reports_screen.dart';
import '../../features/shell/view/app_shell.dart';
import '../providers.dart';
import '../supabase/supabase_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  // Re-evaluate routes on Supabase auth changes (OAuth callback, sign-out).
  ref.listen(authStateChangesProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/explore',
    refreshListenable: refresh,
    observers: [GallaSnackBarClearObserver()],
    redirect: (context, state) {
      final settings = ref.read(settingsProvider).valueOrNull;
      final supabaseUser = ref.read(currentAuthUserProvider);
      final loc = state.matchedLocation;
      final isLoginRoute = loc.startsWith('/login');
      final isExploreRoute = loc.startsWith('/explore');
      final isSplashRoute = loc.startsWith('/splash');
      final isOnboardingRoute = loc.startsWith('/onboarding');
      final isPublicRoute = isLoginRoute || isExploreRoute || isSplashRoute;

      if (settings == null) {
        return isSplashRoute ? null : '/splash';
      }

      // A live Supabase session counts as logged in even before the local
      // DB flag is updated by startup reconciliation in main.dart.
      final isLoggedIn = settings.isLoggedIn || supabaseUser != null;

      if (!isLoggedIn) {
        if (isSplashRoute) return '/explore';
        if (isPublicRoute) return null;
        return '/explore';
      }

      if (isSplashRoute) {
        return settings.onboardingDone ? '/galla' : '/onboarding';
      }
      if (!settings.onboardingDone && !isOnboardingRoute) {
        return '/onboarding';
      }
      if (settings.onboardingDone && isOnboardingRoute) {
        return '/galla';
      }
      if (isLoginRoute || isExploreRoute) return '/galla';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra;
          String? from;
          var signup = false;
          if (extra is Map) {
            from = extra['from'] as String?;
            signup = extra['mode'] == 'signup';
          }
          return LoginScreen(from: from, initialSignUp: signup);
        },
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsScreen()),

      // Business profile & security — reached from More and the home header.
      GoRoute(
        path: '/profile',
        builder: (_, _) => const BusinessProfileScreen(),
      ),

      // ── Invoicing ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/invoices',
        builder: (_, _) => const InvoicesScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, _) => const CreateInvoiceScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
          ),
        ],
      ),

      // ── Ledger detail pages (pushed outside the shell so the FAB and
      // bottom bar never overlap their content) ──────────────────────────────
      GoRoute(
        path: '/ledger/parties/:id',
        builder: (_, state) =>
            PartyDetailScreen(partyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ledger/transaction/:id',
        builder: (_, state) =>
            TransactionDetailScreen(txnId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (_, _) => const ReconciliationScreen(),
      ),

      // ── Secondary navigation ──────────────────────────────────────────────
      GoRoute(
        path: '/business',
        builder: (_, _) => const MoreScreen(),
        routes: [
          GoRoute(path: 'branches', builder: (_, _) => const BranchesScreen()),
          GoRoute(path: 'staff', builder: (_, _) => const StaffScreen()),
        ],
      ),

      // ── Main shell: four persistent destinations ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/galla', builder: (_, _) => const GallaScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ledger', builder: (_, _) => const LedgerScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (_, _) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
