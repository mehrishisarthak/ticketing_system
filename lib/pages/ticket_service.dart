import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Generates an ID-card-style PDF ticket with student details and a scannable QR code.
  static Future<Uint8List> generateTicket({
    required String studentName,
    required String enrollmentNumber,
    required String seatNumber,
    required String ticketId, // The unique UUID for the QR code
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        // A6 is a standard postcard size, landscape is good for ID cards.
        pageFormat: PdfPageFormat.a6.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                // --- Left Column: QR Code Only ---
                pw.SizedBox(
                  width: 120,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center, // Center the QR code vertically
                    children: [
                      // QR Code
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: ticketId,
                        width: 110, // Slightly larger QR code
                        height: 110,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),
                pw.VerticalDivider(width: 12, thickness: 1, color: PdfColors.grey300),
                // --- Right Column: Details ---
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'AAVEG ORIENTATION',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                      ),
                      pw.Center(
                        child: pw.Text(
                          'Official Entry Pass',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                      pw.Divider(height: 15, color: PdfColors.grey300),
                      pw.SizedBox(height: 15),
                      _buildDetailRow('NAME', studentName),
                      _buildDetailRow('ENROLLMENT NO.', enrollmentNumber),
                      _buildDetailRow('SEAT NO.', seatNumber),
                      pw.Spacer(),
                      pw.Center(
                        child: pw.Text(
                          'Present this pass at the entrance.',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper widget for creating styled detail rows in the PDF.
  static pw.Widget _buildDetailRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey400,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


