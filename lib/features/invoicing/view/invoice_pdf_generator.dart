import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/money/money.dart';
import '../../../domain/models.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generateBytes({
    required InvoiceWithItems invoiceWithItems,
    required String businessName,
    required String currency,
  }) async {
    final doc = pw.Document();
    final inv = invoiceWithItems.invoice;
    final items = invoiceWithItems.items;
    String m(int v) => Money(v, currency: currency).format();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName.isEmpty ? 'Galla Business' : businessName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Tax Invoice / Bill',
                        style: const pw.TextStyle(color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        inv.invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateFormat.yMMMd().format(inv.issueDate)}',
                      ),
                      if (inv.dueDate != null)
                        pw.Text(
                          'Due: ${DateFormat.yMMMd().format(inv.dueDate!)}',
                          style: const pw.TextStyle(color: PdfColors.red800),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Bill To
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                inv.partyName ?? 'Valued Customer',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Description', 'Qty', 'Unit Price', 'Total'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                data: items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return [
                    '$idx',
                    item.description,
                    item.quantity == item.quantity.toInt()
                        ? '${item.quantity.toInt()}'
                        : '${item.quantity}',
                    m(item.unitPriceMinor),
                    m(item.totalMinor),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 16),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal', m(inv.subtotalMinor)),
                        if (inv.taxRatePct > 0)
                          _summaryRow(
                            'Tax (${inv.taxRatePct}%)',
                            m(inv.taxMinor),
                          ),
                        pw.Divider(color: PdfColors.grey400),
                        _summaryRow(
                          'Total Amount',
                          m(inv.totalMinor),
                          isBold: true,
                        ),
                        _summaryRow(
                          'Paid',
                          m(inv.paidAmountMinor),
                          color: PdfColors.green800,
                        ),
                        _summaryRow(
                          'Balance Due',
                          m(inv.dueAmountMinor),
                          isBold: true,
                          color: inv.dueAmountMinor > 0
                              ? PdfColors.red800
                              : PdfColors.grey700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (inv.notes != null && inv.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  inv.notes!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Galla — Digital Business Ledger',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Thank you for your business!',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> shareInvoice({
    required InvoiceWithItems invoiceWithItems,
    required String businessName,
    required String currency,
  }) async {
    final bytes = await generateBytes(
      invoiceWithItems: invoiceWithItems,
      businessName: businessName,
      currency: currency,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${invoiceWithItems.invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
