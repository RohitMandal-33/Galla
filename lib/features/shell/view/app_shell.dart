import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/galla_theme.dart';
import '../../entry/view/entry_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Keyboard-aware action container: while the IME is open the quick-add
    // button animates out of the way so it can never overlap the keyboard or
    // cover the entry form behind it. Placement/appearance are untouched
    // whenever the keyboard is closed.
    final imeVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _ImeAwareFabSlot(
        imeVisible: imeVisible,
        child: _QuickAddFab(
          onTap: () {
            HapticFeedback.lightImpact();
            showQuickAddSheet(context);
          },
        ),
      ),
      bottomNavigationBar: _GallaBottomBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ── Keyboard-aware FAB slot ───────────────────────────────────────────────────

class _ImeAwareFabSlot extends StatelessWidget {
  const _ImeAwareFabSlot({required this.imeVisible, required this.child});
  final bool imeVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: imeVisible,
      child: AnimatedOpacity(
        opacity: imeVisible ? 0 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: imeVisible ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────────

class _GallaBottomBar extends StatelessWidget {
  const _GallaBottomBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: GallaColors.surface,
      elevation: 12,
      shadowColor: GallaColors.brand.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: GallaSpacing.bottomNavHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights_rounded,
                label: 'Pulse',
                selected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: 'Khata',
                selected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              const SizedBox(width: 72),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'Stock',
                selected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                label: 'Reports',
                selected: currentIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Add FAB ──────────────────────────────────────────────────────────────

class _QuickAddFab extends StatefulWidget {
  const _QuickAddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<_QuickAddFab>
    with TickerProviderStateMixin {
  late final AnimationController _press;
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _press.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _pulse]),
        builder: (_, _) {
          final glow = 0.28 + (_pulse.value * 0.18);
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GallaColors.gold.withValues(alpha: glow),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: GallaColors.brand.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          GallaColors.goldLight,
                          GallaColors.gold,
                          GallaColors.goldDark,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [GallaColors.brandMid, GallaColors.brand],
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GallaType.captionSm.copyWith(fontSize: 10, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
