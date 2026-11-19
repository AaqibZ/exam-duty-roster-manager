
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/examination_screen.dart';
import 'screens/duty_allocation_screen.dart';
import 'screens/roster_pdf_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const ExamDutyApp());
}

class ExamDutyApp extends StatelessWidget {
  const ExamDutyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exam Duty Roster Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF173B63),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: Builder(
        builder: (context) => WelcomeScreen(
          onContinue: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// PERSONNEL DATA MODEL
class PersonnelMember {
  final int? id;
  final String name;
  final String role;
  final String section;
  final String joiningDate;

  PersonnelMember({
    this.id,
    required this.name,
    required this.role,
    required this.section,
    required this.joiningDate,
  });

  factory PersonnelMember.fromMap(Map<String, dynamic> map) {
    return PersonnelMember(
      id: map['id'] as int,
      name: map['name'] as String,
      role: map['role'] as String,
      section: map['section'] as String,
      joiningDate: map['joiningDate'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'section': section,
      'joiningDate': joiningDate,
    };
  }
}

// MAIN DASHBOARD
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section module is coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF173B63),
        foregroundColor: Colors.white,
        title: const Text(
          'Exam Duty Roster Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/nit_logo.jpg',
                      width: 75,
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NATIONAL INSTITUTE OF TECHNOLOGY SRINAGAR',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF173B63),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Department of Information Technology',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage examination schedules and allocate duties fairly.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth > 600 ? 2 : 1;

                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          columns == 2 ? 2.1 : 2.5,
                      children: [
                        DashboardCard(
                          icon: Icons.people,
                          title: 'Personnel Management',
                          description:
                              'Manage faculty, research scholars and office staff.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PersonnelScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.calendar_month,
                          title: 'Examination Management',
                          description:
                              'Add examination dates, courses and venues.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ExaminationScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.assignment_ind,
                          title: 'Duty Allocation',
                          description:
                              'Allocate duties automatically and fairly.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DutyAllocationScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.picture_as_pdf,
                          title: 'Generate Roster PDF',
                          description:
                              'Create and print the official duty roster.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RosterPdfScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duty Allocation Structure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('2 Associated Faculty'),
                      Text('2 Research Scholars'),
                      Text('1 Office Staff'),
                      Divider(height: 24),
                      Text(
                        'Total: 5 people per examination',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF173B63),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// REUSABLE DASHBOARD CARD
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 38,
                color: const Color(0xFF173B63),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PERSONNEL MANAGEMENT SCREEN
class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() =>
      _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  final List<PersonnelMember> members = [];

  final List<String> roles = [
    'Associated Faculty',
    'Research Scholar',
    'Office Staff',
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPersonnel();
  }

  Future<void> loadPersonnel() async {
    try {
      final records =
          await DatabaseHelper.instance.getAllPersonnel();

      final loadedMembers = records
          .map((record) => PersonnelMember.fromMap(record))
          .toList();

      if (!mounted) return;

      setState(() {
        members
          ..clear()
          ..addAll(loadedMembers);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load personnel: $e'),
        ),
      );
    }
  }

  Future<void> addPersonnel() async {
    final result = await showDialog<PersonnelMember>(
      context: context,
      builder: (dialogContext) {
        return AddPersonnelDialog(roles: roles);
      },
    );

    if (!mounted) return;

    if (result != null) {
      try {
        final newId = await DatabaseHelper.instance
            .insertPersonnel(result.toMap());

        if (!mounted) return;

        setState(() {
          members.insert(
            0,
            PersonnelMember(
              id: newId,
              name: result.name,
              role: result.role,
              section: result.section,
              joiningDate: result.joiningDate,
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnel saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save personnel: $e'),
          ),
        );
      }
    }
  }

  Future<void> deletePersonnel(int index) async {
    final member = members[index];

    if (member.id == null) return;

    try {
      await DatabaseHelper.instance.deletePersonnel(
        member.id!,
      );

      if (!mounted) return;

      setState(() {
        members.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personnel deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete personnel: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF173B63),
        foregroundColor: Colors.white,
        title: const Text('Personnel Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPersonnel,
        backgroundColor: const Color(0xFF173B63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Personnel'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personnel Directory',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173B63),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add and manage faculty, research scholars and office staff.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : members.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 65,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No personnel added yet.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Use Add Personnel to get started.',
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];

                                return Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFFE5ECF5),
                                      child: Icon(
                                        member.role ==
                                                'Associated Faculty'
                                            ? Icons.school
                                            : member.role ==
                                                    'Research Scholar'
                                                ? Icons.science
                                                : Icons.work,
                                        color: const Color(
                                            0xFF173B63),
                                      ),
                                    ),
                                    title: Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${member.role}\n'
                                      'Section: ${member.section}\n'
                                      'Joining Date: ${member.joiningDate}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete personnel',
                                      onPressed: () =>
                                          deletePersonnel(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ADD PERSONNEL DIALOG
class AddPersonnelDialog extends StatefulWidget {
  final List<String> roles;

  const AddPersonnelDialog({
    super.key,
    required this.roles,
  });

  @override
  State<AddPersonnelDialog> createState() =>
      _AddPersonnelDialogState();
}

class _AddPersonnelDialogState
    extends State<AddPersonnelDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController sectionController;
  late final TextEditingController dateController;

  late String selectedRole;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    sectionController = TextEditingController();
    dateController = TextEditingController();

    selectedRole = widget.roles.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    sectionController.dispose();
    dateController.dispose();

    super.dispose();
  }

  void savePersonnel() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final member = PersonnelMember(
      name: nameController.text.trim(),
      role: selectedRole,
      section: sectionController.text.trim(),
      joiningDate: dateController.text.trim(),
    );

    Navigator.pop(context, member);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Personnel'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Personnel Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: widget.roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    hintText: 'e.g. Information Technology',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_tree),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter the section';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Joining Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter joining date';
                    }

                    final parsed =
                        DateTime.tryParse(value.trim());

                    if (parsed == null) {
                      return 'Use YYYY-MM-DD format';
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
        FilledButton(
          onPressed: savePersonnel,
          child: const Text('Save Personnel'),
        ),
      ],
    );
  }
}
