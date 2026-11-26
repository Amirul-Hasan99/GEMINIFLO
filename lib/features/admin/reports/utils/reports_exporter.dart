import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../booking/domain/entities/booking.dart';
import 'reports_file_downloader.dart';

class ReportsExporter {
  /// Export real booking orders to a professional PDF document
  static Future<void> exportToPdf({
    required List<Booking> bookings,
    required double totalOmzet,
    required Map<String, int> categoryCounts,
    required String filterTitle,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
    final shortDateFormatter = DateFormat('dd/MM/yyyy', 'id_ID');
    final now = DateTime.now();

    // Table data rows
    final tableHeaders = [
      'No',
      'Kode Booking',
      'Pelanggan',
      'Produk Papan Bunga',
      'Tgl Acara',
      'Status',
      'Total',
    ];

    final tableData = bookings.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final b = entry.value;
      return [
        '$idx',
        b.bookingCode,
        b.customerName,
        b.productName,
        shortDateFormatter.format(b.startDate),
        b.status.label,
        currencyFormatter.format(b.total),
      ];
    }).toList();

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GEMINIFLO FLORIST',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0A2B1F'),
                      ),
                    ),
                    pw.Text(
                      'Sewa & Pesan Papan Bunga Berkualitas Pontianak',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'LAPORAN TRANSAKSI REAL',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0A2B1F'),
                      ),
                    ),
                    pw.Text(
                      'Dicetak: ${dateFormatter.format(now)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColor.fromHex('#0A2B1F'), thickness: 1.5),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Laporan resmi data riil pemesanan Geminiflo Florist',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          // Filter & Summary block
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      'Total Omzet Riil',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currencyFormatter.format(totalOmzet),
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0A2B1F'),
                      ),
                    ),
                  ],
                ),
                pw.Container(height: 30, width: 1, color: PdfColors.grey300),
                pw.Column(
                  children: [
                    pw.Text(
                      'Total Pesanan',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${bookings.length} Pesanan',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                pw.Container(height: 30, width: 1, color: PdfColors.grey300),
                pw.Column(
                  children: [
                    pw.Text(
                      'Rata-rata Order (AOV)',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currencyFormatter.format(
                        bookings.isEmpty ? 0 : totalOmzet / bookings.length,
                      ),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Daftar Rincian Orderan ($filterTitle)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'Total: ${bookings.length} data',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Orders Table
          if (bookings.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 24),
              child: pw.Center(
                child: pw.Text(
                  'Belum ada transaksi pemesanan pada kategori ini.',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0A2B1F'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
            ),
          pw.SizedBox(height: 16),

          // Category distribution
          if (categoryCounts.isNotEmpty) ...[
            pw.Text(
              'Distribusi Kategori Pesanan Riil',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Kategori', 'Jumlah Order', 'Persentase'],
              data: categoryCounts.entries.map((e) {
                final pct = bookings.isEmpty
                    ? 0
                    : ((e.value / bookings.length) * 100).toStringAsFixed(1);
                return [e.key, '${e.value} Pesanan', '$pct%'];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#154D39'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
            ),
          ],
        ],
      ),
    );

    // Preview and Print / Save PDF via printing package
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Geminiflo_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  /// Export real booking orders to Excel-compatible CSV with UTF-8 BOM
  static Future<String?> exportToExcelCsv({
    required List<Booking> bookings,
    required double totalOmzet,
    required String filterTitle,
  }) async {
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final shortDateFormatter = DateFormat('yyyy-MM-dd');

    // UTF-8 BOM so Excel opens with proper character encoding and formatting.
    final buffer = StringBuffer('\uFEFF');
    void writeRow(Iterable<String> cells) {
      buffer.write('${cells.join(',')}\r\n');
    }

    String csvCell(String value) {
      final safeValue = RegExp(r'^\s*[=+@\-\t\r]').hasMatch(value)
          ? "'$value"
          : value;
      return '"${safeValue.replaceAll('"', '""')}"';
    }

    // Header metadata
    writeRow([csvCell('LAPORAN PENJUALAN & PEMESANAN GEMINIFLO FLORIST')]);
    writeRow([csvCell('Tanggal Ekspor'), csvCell(dateFormatter.format(now))]);
    writeRow([csvCell('Filter Laporan'), csvCell(filterTitle)]);
    writeRow([
      csvCell('Total Omzet'),
      csvCell('Rp ${totalOmzet.toStringAsFixed(0)}'),
    ]);
    writeRow([csvCell('Total Orderan'), bookings.length.toString()]);
    buffer.write('\r\n');

    // Table columns
    writeRow(
      [
        'No',
        'Kode Booking',
        'Nama Pelanggan',
        'No Telepon',
        'Produk Papan Bunga',
        'Alamat Acara',
        'Pesan di Pita',
        'Tanggal Mulai',
        'Tanggal Selesai',
        'Layanan Antar',
        'Subtotal (Rp)',
        'Biaya Antar (Rp)',
        'Biaya Pasang (Rp)',
        'Total (Rp)',
        'Status',
      ].map(csvCell),
    );

    for (var i = 0; i < bookings.length; i++) {
      final b = bookings[i];
      writeRow([
        '${i + 1}',
        csvCell(b.bookingCode),
        csvCell(b.customerName),
        csvCell(b.customerPhone),
        csvCell(b.productName),
        csvCell(b.eventAddress),
        csvCell(b.eventMessage),
        csvCell(shortDateFormatter.format(b.startDate)),
        csvCell(shortDateFormatter.format(b.endDate)),
        csvCell(b.withDelivery ? 'Antar & Pasang' : 'Ambil Sendiri'),
        b.subtotal.toStringAsFixed(0),
        b.deliveryFee.toStringAsFixed(0),
        b.installationFee.toStringAsFixed(0),
        b.total.toStringAsFixed(0),
        csvCell(b.status.label),
      ]);
    }

    try {
      final fileName =
          'Laporan_Order_Geminiflo_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
      await downloadReportFile(
        bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
        fileName: fileName,
        mimeType: 'text/csv;charset=utf-8',
        subject: 'Laporan Penjualan Geminiflo Florist',
        text:
            'Laporan Penjualan Geminiflo ($filterTitle) - ${DateFormat('dd MMMM yyyy').format(now)}',
      );

      return fileName;
    } catch (_) {
      return null;
    }
  }
}
