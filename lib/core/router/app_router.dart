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
import '../../features/reports/view/reports_screen.dart';
import '../../features/shell/view/app_shell.dart';
import '../providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/galla',
    refreshListenable: refresh,
    observers: [GallaSnackBarClearObserver()],
    redirect: (context, state) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) return null;
      final loc = state.matchedLocation;
      final isLoginRoute = loc.startsWith('/login');
      final isOnboardingRoute = loc.startsWith('/onboarding');

      // Auth gate — demo account required before anything else.
      if (!settings.isLoggedIn && !isLoginRoute) return '/login';
      if (settings.isLoggedIn && isLoginRoute) return '/galla';

      // Onboarding gate — demo login auto-completes onboarding, but keep for fresh installs.
      if (settings.isLoggedIn &&
          !settings.onboardingDone &&
          !isOnboardingRoute &&
          !isLoginRoute) {
        return '/onboarding';
      }
      if (settings.isLoggedIn &&
          settings.onboardingDone &&
          isOnboardingRoute &&
          loc == '/onboarding') {
        return '/galla';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
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
