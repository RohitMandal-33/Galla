import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Applies the app-wide locale to intl's formatters so dates render in the
/// chosen language ("मंगलबार, २५ अगस्ट" instead of English day names).
///
/// Safe to call repeatedly; [initializeDateFormatting] caches after the
/// first load.
Future<void> applyAppLocale(String locale) async {
  final tag = locale == 'ne' ? 'ne' : 'en';
  await initializeDateFormatting(tag);
  Intl.defaultLocale = tag;
}
