
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/database_helper.dart';
import '../models/examination.dart';

class RosterPdfScreen extends StatefulWidget {
  const RosterPdfScreen({super.key});

  @override
  State<RosterPdfScreen> createState() => _RosterPdfScreenState();
}

class _RosterPdfScreenState extends State<RosterPdfScreen> {
  bool isLoading = false;

  Future<void> generateRosterPdf() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Retrieve all examinations.
      final examRecords =
          await DatabaseHelper.instance.getAllExaminations();

      if (examRecords.isEmpty) {
        throw Exception(
          'No examinations found. Please add examinations first.',
        );
      }

      final examinations = examRecords
          .map((item) => Examination.fromMap(item))
          .toList();

      // Retrieve saved duty allocations for every examination.
      final List<List<String>> tableRows = [];

      for (int i = 0; i < examinations.length; i++) {
        final exam = examinations[i];

        final assigned = await DatabaseHelper.instance
            .getAllocationsForExamination(exam.id!);

        if (assigned.length != 5) {
          throw Exception(
            'Duties are not fully allocated for '
            '${exam.courseName}. Please allocate exactly '
            'five people before generating the PDF.',
          );
        }

        final parsedDate = DateTime.tryParse(exam.examDate);

        final dateText = parsedDate == null
            ? exam.examDate
            : '${parsedDate.day.toString().padLeft(2, '0')}-'
              '${parsedDate.month.toString().padLeft(2, '0')}-'
              '${parsedDate.year}';

        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        final dayText = parsedDate == null
            ? ''
            : weekdays[parsedDate.weekday - 1];

        final dutyText = assigned.map((person) {
          return '${person['personnelName']} '
              '(${person['role']})';
        }).join('\n');

        tableRows.add([
          '${i + 1}',
          '$dateText\n$dayText',
          '${exam.courseName}\n(${exam.courseCode})',
          exam.facultyName,
          exam.venue,
          dutyText,
        ]);
      }

      // Load the NIT Srinagar logo.
      final logoData =
          await rootBundle.load('assets/images/nit_logo.jpg');

      final logo = pw.MemoryImage(
        logoData.buffer.asUint8List(),
      );

      // Create the PDF document.
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(25),
          build: (context) {
            return [
              // Institute heading.
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(
                    logo,
                    width: 65,
                    height: 65,
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'NATIONAL INSTITUTE OF TECHNOLOGY SRINAGAR',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Department of Information Technology',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 80),
                ],
              ),

              pw.SizedBox(height: 18),

              pw.Center(
                child: pw.Text(
                  'DATE SHEET FOR LABORATORY EXAMINATIONS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  'B.Tech 6th Semester (I.T.)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  'Examination Time: 10:00 AM',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),

              pw.SizedBox(height: 18),

              // Examination table.
              pw.TableHelper.fromTextArray(
                headers: [
                  'S. No.',
                  'Date / Day',
                  'Course Name / Code',
                  'Associated Faculty',
                  'Venue',
                  'Allocated Duty Personnel',
                ],
                data: tableRows,
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.7,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 8,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.8),
                  3: const pw.FlexColumnWidth(1.3),
                  4: const pw.FlexColumnWidth(1.1),
                  5: const pw.FlexColumnWidth(2.7),
                },
              ),

              pw.SizedBox(height: 35),

              // Coordinator signature.
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 25),
                    pw.Text(
                      '________________________',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Examination Coordinator',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Department of Information Technology',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Divider(),

              pw.Text(
                'Copy to:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text(
                '1. Head, Department of Information Technology.\n'
                '2. Examination Cell.\n'
                '3. Notice Board.\n'
                '4. Office Copy.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ];
          },
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      if (!mounted) return;

      // Open the native print/share interface.
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'NIT_Srinagar_Exam_Duty_Roster.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Roster PDF'),
        backgroundColor: const Color(0xFF173B63),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 85,
                color: Color(0xFF173B63),
              ),
              const SizedBox(height: 20),
              const Text(
                'Consolidated Examination Duty Roster',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Generate one PDF containing all examinations '
                'and their saved duty allocations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : generateRosterPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(
                    isLoading
                        ? 'Generating PDF...'
                        : 'Generate and Print PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173B63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
