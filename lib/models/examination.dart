
class Examination {
  final int? id;
  final String examDate;
  final String courseName;
  final String courseCode;
  final int facultyId;
  final String facultyName;
  final String venue;

  Examination({
    this.id,
    required this.examDate,
    required this.courseName,
    required this.courseCode,
    required this.facultyId,
    required this.facultyName,
    required this.venue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examDate': examDate,
      'courseName': courseName,
      'courseCode': courseCode,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'venue': venue,
    };
  }

  factory Examination.fromMap(Map<String, dynamic> map) {
    return Examination(
      id: map['id'] as int?,
      examDate: map['examDate'] as String,
      courseName: map['courseName'] as String,
      courseCode: map['courseCode'] as String,
      facultyId: map['facultyId'] as int,
      facultyName: map['facultyName'] as String,
      venue: map['venue'] as String,
    );
  }
}
