// ================= FILE 14: invoice_generator_service.dart =================
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class InvoiceGeneratorService {
  static Future<void> generateAndOpenInvoice({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String address,
    required List<dynamic> items,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('VIZIAG MART ENTERPRISE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                  pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ग्राहक का नाम: $customerName', style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('मोबाइल: $customerPhone', style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('पता: $address', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ऑर्डर आईडी: $orderId', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('दिनांक: ${DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['उत्पाद (Item)', 'मात्रा (Qty)', 'रेट (Price)', 'कुल (Total)'],
                data: items.map((item) {
                  double price = (item['price'] as num).toDouble();
                  double qty = (item['qty'] as num).toDouble();
                  return [
                    item['name'].toString(),
                    '$qty ${item['unit'] ?? 'Kg'}',
                    'Rs. $price',
                    'Rs. ${(price * qty).toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('कुल भुगतान राशि (Grand Total): Rs. ${totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('धन्यवाद! आपका व्यापार हमारे लिए महत्वपूर्ण है। - Viziag Mart Faridabad',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Invoice_$orderId.pdf');
    await file.writeAsBytes(await pdf.save());

    // ऑटोमैटिक पीडीएफ ओपन या शेयर करें
    await OpenFile.open(file.path);
  }
}
