
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/examination.dart';

class ExaminationScreen extends StatefulWidget {
  const ExaminationScreen({super.key});

  @override
  State<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends State<ExaminationScreen> {
  List<Examination> examinations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExaminations();
  }

  // Load examinations from SQLite
  Future<void> loadExaminations() async {
    try {
      final data =
          await DatabaseHelper.instance.getAllExaminations();

      if (!mounted) return;

      setState(() {
        examinations = data
            .map((item) => Examination.fromMap(item))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading examinations: $e')),
      );
    }
  }

  // Add examination
  Future<void> addExamination() async {
    try {
      final personnel =
          await DatabaseHelper.instance.getAllPersonnel();

      final faculty = personnel.where((person) {
        return person['role'] == 'Associated Faculty';
      }).toList();

      if (!mounted) return;

      if (faculty.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add Associated Faculty in Personnel Management first.',
            ),
          ),
        );
        return;
      }

      final result = await showDialog<Examination>(
        context: context,
        builder: (context) {
          return AddExaminationDialog(faculty: faculty);
        },
      );

      if (result == null) return;

      final id = await DatabaseHelper.instance.insertExamination(
        result.toMap()..remove('id'),
      );

      final savedExamination = Examination(
        id: id,
        examDate: result.examDate,
        courseName: result.courseName,
        courseCode: result.courseCode,
        facultyId: result.facultyId,
        facultyName: result.facultyName,
        venue: result.venue,
      );

      if (!mounted) return;

      setState(() {
        examinations.add(savedExamination);
        examinations.sort(
          (a, b) => a.examDate.compareTo(b.examDate),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examination saved successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving examination: $e')),
      );
    }
  }

  // Delete examination
  Future<void> deleteExamination(Examination examination) async {
    if (examination.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Examination'),
          content: const Text(
            'Are you sure you want to delete this examination?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await DatabaseHelper.instance.deleteExamination(
        examination.id!,
      );

      if (!mounted) return;

      setState(() {
        examinations.removeWhere(
          (item) => item.id == examination.id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examination deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting examination: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Management'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : examinations.isEmpty
              ? const Center(
                  child: Text(
                    'No examinations added yet.\nTap + to add an examination.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: examinations.length,
                  itemBuilder: (context, index) {
                    final exam = examinations[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          exam.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Course Code: ${exam.courseCode}'),
                              Text('Date: ${exam.examDate}'),
                              Text('Faculty: ${exam.facultyName}'),
                              Text('Venue: ${exam.venue}'),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => deleteExamination(exam),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: addExamination,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Dialog for adding an examination
class AddExaminationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> faculty;

  const AddExaminationDialog({
    super.key,
    required this.faculty,
  });

  @override
  State<AddExaminationDialog> createState() =>
      _AddExaminationDialogState();
}

class _AddExaminationDialogState
    extends State<AddExaminationDialog> {
  final _formKey = GlobalKey<FormState>();

  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();
  final venueController = TextEditingController();
  final dateController = TextEditingController();

  int? selectedFacultyId;
  String? selectedFacultyName;

  @override
  void dispose() {
    courseNameController.dispose();
    courseCodeController.dispose();
    venueController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      dateController.text =
          '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';
    }
  }

  void saveExamination() {
    if (!_formKey.currentState!.validate()) return;

    final examination = Examination(
      examDate: dateController.text.trim(),
      courseName: courseNameController.text.trim(),
      courseCode: courseCodeController.text.trim(),
      facultyId: selectedFacultyId!,
      facultyName: selectedFacultyName!,
      venue: venueController.text.trim(),
    );

    Navigator.pop(context, examination);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Examination'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Examination Date',
                    hintText: 'Select date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select examination date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: courseCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<int>(
                  initialValue: selectedFacultyId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Associated Faculty',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.faculty.map((person) {
                    return DropdownMenuItem<int>(
                      value: person['id'] as int,
                      child: Text(person['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFacultyId = value;

                      final selected = widget.faculty.firstWhere(
                        (person) => person['id'] == value,
                      );

                      selectedFacultyName =
                          selected['name'] as String;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select faculty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: venueController,
                  decoration: const InputDecoration(
                    labelText: 'Examination Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter examination venue';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saveExamination,
          child: const Text('Save Examination'),
        ),
      ],
    );
  }
}
