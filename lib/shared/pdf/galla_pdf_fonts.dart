import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared fonts for every generated document. Nepali (Devanagari) names are
/// a first-class part of this app's data, so PDFs must render them instead
/// of dropping glyphs the way base-14 Helvetica does.
///
/// Loads Google Fonts at share time (cached by the printing package) and
/// degrades gracefully to the built-in font when offline — an English-only
/// PDF beats a crashed share sheet.
class GallaPdfFonts {
  static Future<pw.Document> createDocument() async {
    pw.Font? base;
    pw.Font? bold;
    pw.Font? devanagari;
    try {
      base = await PdfGoogleFonts.notoSansRegular();
      bold = await PdfGoogleFonts.notoSansBold();
      devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
    } catch (_) {
      // Offline / download failed — fall back to defaults below.
    }

    if (base == null) return pw.Document();

    return pw.Document(
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold ?? base,
        fontFallback: [if (devanagari != null) devanagari],
      ),
    );
  }
}
