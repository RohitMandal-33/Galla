import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the global Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Stream provider for current Supabase auth state changes.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Provider for the currently signed-in Supabase user.
final currentAuthUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ?? ref.watch(supabaseClientProvider).auth.currentUser;
});
