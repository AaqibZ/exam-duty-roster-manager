
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/examination.dart';

class DutyAllocationScreen extends StatefulWidget {
  const DutyAllocationScreen({super.key});

  @override
  State<DutyAllocationScreen> createState() =>
      _DutyAllocationScreenState();
}

class _DutyAllocationScreenState
    extends State<DutyAllocationScreen> {
  List<Examination> examinations = [];
  List<Map<String, dynamic>> personnel = [];
  List<Map<String, dynamic>> allocations = [];

  bool isLoading = true;
  bool isAllocating = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final examData =
          await DatabaseHelper.instance.getAllExaminations();

      final personnelData =
          await DatabaseHelper.instance.getAllPersonnel();

      final allocationData =
          await DatabaseHelper.instance.getAllDutyAllocations();

      if (!mounted) return;

      setState(() {
        examinations = examData
            .map((item) => Examination.fromMap(item))
            .toList();

        personnel = personnelData;
        allocations = allocationData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  List<Map<String, dynamic>> allocationsForExam(
    int examinationId,
  ) {
    return allocations.where((item) {
      return item['examinationId'] == examinationId;
    }).toList();
  }

  int dutyCountFor(
    int personnelId,
    Map<int, int> dutyCounts,
  ) {
    return dutyCounts[personnelId] ?? 0;
  }

  List<Map<String, dynamic>> sortCandidates(
    List<Map<String, dynamic>> candidates,
    Map<int, int> dutyCounts,
  ) {
    candidates.sort((a, b) {
      final aId = a['id'] as int;
      final bId = b['id'] as int;

      final countComparison = dutyCountFor(
        aId,
        dutyCounts,
      ).compareTo(
        dutyCountFor(bId, dutyCounts),
      );

      if (countComparison != 0) {
        return countComparison;
      }

      // Junior person first: later joining date.
      final aDate = a['joiningDate'] as String;
      final bDate = b['joiningDate'] as String;

      final seniorityComparison =
          bDate.compareTo(aDate);

      if (seniorityComparison != 0) {
        return seniorityComparison;
      }

      return aId.compareTo(bId);
    });

    return candidates;
  }

  Future<void> allocateDuties(
    Examination examination,
  ) async {
    if (examination.id == null) return;

    if (isAllocating) return;

    final existing =
        allocationsForExam(examination.id!);

    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Duties have already been allocated for this examination.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isAllocating = true;
    });

    try {
      // Refresh records before allocating.
      final personnelData =
          await DatabaseHelper.instance.getAllPersonnel();

      final allAllocations =
          await DatabaseHelper.instance.getAllDutyAllocations();

      final examData =
          await DatabaseHelper.instance.getAllExaminations();

      final allExams = examData
          .map((item) => Examination.fromMap(item))
          .toList();

      // Get existing duty counts.
      final countData =
          await DatabaseHelper.instance.getDutyCounts();

      final Map<int, int> dutyCounts = {};

      for (final item in countData) {
        dutyCounts[item['personnelId'] as int] =
            item['dutyCount'] as int;
      }

      // Identify people already assigned to another
      // examination on the same date.
      final unavailableIds = <int>{};

      for (final allocation in allAllocations) {
        final allocatedExamId =
            allocation['examinationId'] as int;

        if (allocatedExamId == examination.id) {
          continue;
        }

        final otherExam = allExams.where(
          (exam) => exam.id == allocatedExamId,
        ).toList();

        if (otherExam.isNotEmpty &&
            otherExam.first.examDate ==
                examination.examDate) {
          unavailableIds.add(
            allocation['personnelId'] as int,
          );
        }
      }

      // Identify the faculty linked to this examination.
      final linkedFaculty = personnelData.where((person) {
        return person['id'] == examination.facultyId &&
            person['role'] == 'Associated Faculty';
      }).toList();

      if (linkedFaculty.isEmpty) {
        throw Exception(
          'The faculty linked to this examination '
          'is not available in Personnel Management.',
        );
      }

      final facultyMember = linkedFaculty.first;

      if (unavailableIds.contains(examination.facultyId)) {
        throw Exception(
          'The linked faculty member already has a duty '
          'on ${examination.examDate}.',
        );
      }

      // Select eligible candidates independently.
      final facultyCandidates = personnelData.where((person) {
        return person['role'] == 'Associated Faculty' &&
            person['id'] != examination.facultyId &&
            !unavailableIds.contains(person['id']);
      }).toList();

      final scholarCandidates = personnelData.where((person) {
        return person['role'] == 'Research Scholar' &&
            !unavailableIds.contains(person['id']);
      }).toList();

      final staffCandidates = personnelData.where((person) {
        return person['role'] == 'Office Staff' &&
            !unavailableIds.contains(person['id']);
      }).toList();

      // Apply fairness and junior-first selection.
      sortCandidates(facultyCandidates, dutyCounts);
      sortCandidates(scholarCandidates, dutyCounts);
      sortCandidates(staffCandidates, dutyCounts);

      // Check availability in every independent category.
      if (facultyCandidates.isEmpty) {
        throw Exception(
          'A second Associated Faculty member is required.',
        );
      }

      if (scholarCandidates.length < 2) {
        throw Exception(
          'Two available Research Scholars are required.',
        );
      }

      if (staffCandidates.isEmpty) {
        throw Exception(
          'One available Office Staff member is required.',
        );
      }

      // Final selection: exactly five people.
      final selectedPeople = [
        facultyMember,
        facultyCandidates.first,
        scholarCandidates[0],
        scholarCandidates[1],
        staffCandidates.first,
      ];

      final allocatedAt = DateTime.now().toIso8601String();

      final records = selectedPeople.map((person) {
        return {
          'examinationId': examination.id,
          'personnelId': person['id'],
          'personnelName': person['name'],
          'role': person['role'],
          'allocatedAt': allocatedAt,
        };
      }).toList();

      // Save all five assignments together.
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        for (final record in records) {
          await txn.insert('duty_allocations', record);
        }
      });

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Five duties allocated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Allocation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAllocating = false;
        });
      }
    }
  }

  Widget buildAllocationDetails(int examinationId) {
    final assigned = allocationsForExam(examinationId);

    if (assigned.isEmpty) {
      return const Text(
        'Duties not allocated yet.',
        style: TextStyle(color: Colors.orange),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Allocated Personnel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...assigned.map((person) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${person['personnelName']} '
                    '(${person['role']})',
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automatic Duty Allocation'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : examinations.isEmpty
              ? const Center(
                  child: Text(
                    'No examinations available.\n'
                    'Please add examinations first.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: examinations.length,
                  itemBuilder: (context, index) {
                    final exam = examinations[index];

                    final assigned =
                        allocationsForExam(exam.id!);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.courseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Course Code: ${exam.courseCode}'),
                            Text('Date: ${exam.examDate}'),
                            Text('Linked Faculty: ${exam.facultyName}'),
                            Text('Venue: ${exam.venue}'),
                            const SizedBox(height: 12),
                            buildAllocationDetails(exam.id!),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    assigned.isNotEmpty ||
                                            isAllocating
                                        ? null
                                        : () => allocateDuties(exam),
                                icon: const Icon(
                                  Icons.assignment_turned_in,
                                ),
                                label: Text(
                                  assigned.isNotEmpty
                                      ? 'Duties Allocated'
                                      : 'Allocate Duties',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
