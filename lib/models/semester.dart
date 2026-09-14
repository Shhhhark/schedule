import 'course.dart';

class Semester {
  final String name;
  final DateTime startDate; // 第一周周一
  final List<Course> courses;

  Semester({
    required this.name,
    required this.startDate,
    required this.courses,
  });

  /// 今天是本学期的第几周；不在学期内返回 null
  int? currentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = today.difference(start).inDays;
    if (diff < 0) return null;
    return (diff ~/ 7) + 1;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate.toIso8601String(),
        'courses': courses.map((e) => e.toJson()).toList(),
      };

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        name: json['name'] ?? '',
        startDate: DateTime.parse(json['startDate']),
        courses: (json['courses'] as List)
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}