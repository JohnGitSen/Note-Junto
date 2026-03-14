import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class NotePdfExporter {
  /// Exports the given [QuillController] document to a PDF.
  /// Shows a preview/share sheet using the [printing] package.
  static Future<void> export({
    required BuildContext context,
    required QuillController controller,
    required String title,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 172, 202, 255),
          ),
        ),
      );

      final pageFormat = PDFPageFormat.all(
        width: PdfPageFormat.a4.width,
        height: PdfPageFormat.a4.height,
        margin: 40,
      );

      final pdfConverter = PDFConverter(
        document: controller.document.toDelta(),
        pageFormat: pageFormat,
        backMatterDelta: null,
        frontMatterDelta: null,
        fallbacks: [],
      );

      final doc = await pdfConverter.createDocument();
      if (doc == null) throw Exception('Failed to create PDF document');
      final bytes = await doc.save();

      if (context.mounted) Navigator.of(context).pop();

      if (!context.mounted) return;

      await Printing.layoutPdf(
        name: title.isNotEmpty ? title : 'note',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
      }
    }
  }
}
