import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../theme/galla_theme.dart';

/// Single gate for protected actions. Returns `true` if the user is (or
/// becomes) logged in; `false` if they dismiss and keep exploring.
Future<bool> requireAuth(
  BuildContext context,
  WidgetRef ref, {
  String? reason,
}) async {
  final settings = ref.read(settingsProvider).valueOrNull;
  if (settings?.isLoggedIn == true) return true;

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: GallaColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GallaRadius.bottomSheet),
      ),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          GallaSpacing.xl,
          GallaSpacing.sm,
          GallaSpacing.xl,
          GallaSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create an account to continue', style: GallaType.cardTitle),
            const SizedBox(height: GallaSpacing.sm),
            Text(
              reason ?? 'Log in to save an entry',
              style: GallaType.body.copyWith(color: GallaColors.muted),
            ),
            const SizedBox(height: GallaSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'login'),
              child: const Text('Log In'),
            ),
            const SizedBox(height: GallaSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'signup'),
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: GallaSpacing.xs),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'explore'),
              child: Text(
                'Continue Exploring',
                style: GallaType.caption.copyWith(
                  color: GallaColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted) return false;
  if (choice != 'login' && choice != 'signup') return false;

  final from = GoRouterState.of(context).uri.toString();
  await context.push(
    '/login',
    extra: {'from': from, 'mode': choice == 'signup' ? 'signup' : 'login'},
  );
  if (!context.mounted) return false;
  return ref.read(settingsProvider).valueOrNull?.isLoggedIn == true;
}
