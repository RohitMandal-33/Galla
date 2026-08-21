import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../entry/view/entry_sheet.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(stringsLocaleProvider);
    final s = S(locale);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _GallaBottomBar(
        currentIndex: navigationShell.currentIndex,
        s: s,
        onDestinationSelected: (i) {
          if (i == 2) {
            HapticFeedback.lightImpact();
            _showAddEntrySheet(context);
            return;
          }
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            _branchIndex(i),
            initialLocation: i == _visualIndex(navigationShell.currentIndex),
          );
        },
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EntrySheet(),
    );
  }

  int _visualIndex(int branch) => branch >= 2 ? branch + 1 : branch;
  int _branchIndex(int visual) => visual > 2 ? visual - 1 : visual;
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────────

class _GallaBottomBar extends StatelessWidget {
  const _GallaBottomBar({
    required this.currentIndex,
    required this.s,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final S s;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final visualIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: GallaColors.surface,
        border: Border(top: BorderSide(color: GallaColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: GallaSpacing.bottomNavHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: s.gallaTab,
                selected: visualIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: s.ledgerTab,
                selected: visualIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),

              // ── Center FAB ─────────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CenterFab(),
                    ],
                  ),
                ),
              ),

              _NavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                label: s.reportsTab,
                selected: visualIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                selectedIcon: Icons.more_horiz_rounded,
                label: s.businessTab,
                selected: visualIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Center FAB ─────────────────────────────────────────────────────────────────

class _CenterFab extends StatefulWidget {
  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: GallaSpacing.fabSize,
          height: GallaSpacing.fabSize,
          decoration: BoxDecoration(
            color: GallaColors.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: GallaColors.brand.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ── Nav Item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GallaColors.brand : GallaColors.muted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 4 : 0,
              height: selected ? 4 : 0,
              decoration: BoxDecoration(
                color: GallaColors.brand,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
