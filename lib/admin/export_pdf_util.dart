import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';

class ExportPDFUtil {
  static Future<void> exportListingsToPDF(BuildContext context) async {
    final pdf = pw.Document();
    final listings = await FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .get();

    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('🏡 HomeRentalUiTM - Listings Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Exported: $date\n\n', style: const pw.TextStyle(fontSize: 12)),
          pw.Table.fromTextArray(
            headers: ['Title', 'Price (RM)', 'Category', 'Email', 'Date'],
            data: listings.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['title'] ?? '',
                data['price']?.toString() ?? '',
                data['category'] ?? '',
                data['email'] ?? '',
                (data['createdAt'] as Timestamp?)?.toDate().toString().split('.')[0] ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await _saveAndOpenPDF(context, pdf, 'Listings_Report.pdf');
  }

  static Future<void> exportUsersToPDF(BuildContext context) async {
    final pdf = pw.Document();
    final users = await FirebaseFirestore.instance.collection('users').get();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('👤 HomeRentalUiTM - Users Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Exported: $date\n\n', style: const pw.TextStyle(fontSize: 12)),
          pw.Table.fromTextArray(
            headers: ['Email', 'Phone'],
            data: users.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['email'] ?? '',
                data['phone'] ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await _saveAndOpenPDF(context, pdf, 'Users_Report.pdf');
  }

  static Future<void> _saveAndOpenPDF(BuildContext context, pw.Document pdf, String filename) async {
    try {
      final output = await getExternalStorageDirectory();
      final path = "${output!.path}/$filename";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ PDF saved: $filename')),
      );

      await OpenFile.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save PDF: $e')),
      );
    }
  }
}
