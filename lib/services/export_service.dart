import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';

class ExportService {
  static final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );
  static final dateFormat = DateFormat('dd/MM/yyyy');

  Future<String?> exportToExcel({
    required String title,
    required List<Invoice> invoices,
    required double totalOutstanding,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(title);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue(
      'Total Outstanding: ${currencyFormat.format(totalOutstanding)}',
    );

    // Table Headers
    final headers = [
      'SR No',
      'Date',
      'Bill/Challan No',
      'Party Name',
      'Outstanding Amount',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Data
    for (var i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      final row = i + 4;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(
        i + 1,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        dateFormat.format(inv.invoiceDate),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        inv.invoiceNumber,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        inv.partyName,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(
        inv.outstandingAmount,
      );
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await _getExportDirectory();
      final filePath = '${directory.path}/${title.replaceAll(' ', '_')}.xlsx';
      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      return filePath;
    }
    return null;
  }

  Future<String?> exportToPDF({
    required String title,
    required List<Invoice> invoices,
    required double totalOutstanding,
  }) async {
    final pdf = pw.Document();

    // Fallback font (Helvetica) doesn't support Rupee symbol.
    // We'll use "Rs." for PDF output to ensure readability across all devices.
    final pdfCurrencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
    );
    final font = pw.Font.helvetica();
    final pw.TextStyle headerStyle = pw.TextStyle(
      font: font,
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );
    final pw.TextStyle baseStyle = pw.TextStyle(font: font, fontSize: 11);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: baseStyle,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total Outstanding: ${pdfCurrencyFormat.format(totalOutstanding)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            headerStyle: headerStyle,
            cellStyle: baseStyle,
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // SR No
              1: const pw.FixedColumnWidth(100), // Date
              2: const pw.FixedColumnWidth(110), // Bill No
              3: const pw.FlexColumnWidth(), // Party Name (Wide)
              4: const pw.FixedColumnWidth(120), // Amount
            },
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['SR No', 'Date', 'Bill No', 'Party Name', 'Amount'],
            data: List<List<String>>.generate(invoices.length, (index) {
              final inv = invoices[index];
              return [
                (index + 1).toString(),
                dateFormat.format(inv.invoiceDate),
                inv.invoiceNumber,
                inv.partyName,
                pdfCurrencyFormat.format(inv.outstandingAmount),
              ];
            }),
          ),
        ],
      ),
    );

    final directory = await _getExportDirectory();
    final filePath = '${directory.path}/${title.replaceAll(' ', '_')}.pdf';
    await File(filePath).writeAsBytes(await pdf.save());

    return filePath;
  }

  Future<Directory> _getExportDirectory() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        // Attempt to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }
    } catch (_) {
      directory = await getTemporaryDirectory();
    }
    return directory ?? await getTemporaryDirectory();
  }
}
