import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/reconciliation/view/reconciliation_screen.dart';
import '../../features/reports/view/ai_assistant_screen.dart';
import '../../features/reports/view/reports_screen.dart';
import '../../features/shell/view/app_shell.dart';
import '../providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/galla',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings == null) return null;
      final onboardingRoute = state.matchedLocation.startsWith('/onboarding');
      if (!settings.onboardingDone && !onboardingRoute) return '/onboarding';
      if (settings.onboardingDone &&
          onboardingRoute &&
          state.matchedLocation == '/onboarding') {
        return '/galla';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/onboarding/balance',
        builder: (_, _) => const StartingBalanceScreen(),
      ),

      // Business Profile & Settings Route
      GoRoute(
        path: '/profile',
        builder: (_, _) => const BusinessProfileScreen(),
      ),

      // V2 & Secondary Full-Page Routes
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

      // Detail pages pushed OUTSIDE the shell so the floating add button and
      // bottom bar never overlap their content or forms. URLs are unchanged,
      // only their position in the tree moved from inside shell branches.
      GoRoute(path: '/ledger/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/ledger/parties/:id',
        builder: (_, state) =>
            PartyDetailScreen(partyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ledger/transaction/:id',
        builder: (_, state) =>
            TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reports/pnl',
        builder: (_, state) => ReportViewScreen(
          kind: 'pnl',
          range: state.uri.queryParameters['range'] ?? 'month',
        ),
      ),
      GoRoute(
        path: '/reports/cashflow',
        builder: (_, state) => ReportViewScreen(
          kind: 'cashflow',
          range: state.uri.queryParameters['range'] ?? 'month',
        ),
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (_, _) => const ReconciliationScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (_, _) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/business',
        builder: (_, _) => const MoreScreen(),
        routes: [
          GoRoute(path: 'branches', builder: (_, _) => const BranchesScreen()),
          GoRoute(path: 'staff', builder: (_, _) => const StaffScreen()),
        ],
      ),

      // Main App Shell with Bottom Tabs (Pulse, Khata, +, Inventory, Reports)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return AppShell(navigationShell: shell);
        },
        branches: [
          // 0: Pulse / Galla
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/galla',
                builder: (_, _) => const GallaScreen(),
                routes: [
                  GoRoute(
                    path: 'day/:date',
                    builder: (_, state) =>
                        DayScreen(date: state.pathParameters['date']!),
                  ),
                ],
              ),
            ],
          ),

          // 1: Khata / Ledger
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ledger', builder: (_, _) => const LedgerScreen()),
            ],
          ),

          // 2: Inventory
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (_, _) => const InventoryScreen(),
              ),
            ],
          ),

          // 3: Reports
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
