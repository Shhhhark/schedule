class Course {
  final String name;
  final String teacher;
  final String room;
  final int day; // 1-7
  final int startSection;
  final int endSection;
  final Set<int> weeks;

  Course({
    required this.name,
    required this.teacher,
    required this.room,
    required this.day,
    required this.startSection,
    required this.endSection,
    required this.weeks,
  });

  bool inWeek(int week) => weeks.contains(week);

  Map<String, dynamic> toJson() => {
        'name': name,
        'teacher': teacher,
        'room': room,
        'day': day,
        'startSection': startSection,
        'endSection': endSection,
        'weeks': weeks.toList(),
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        name: json['name'] ?? '',
        teacher: json['teacher'] ?? '',
        room: json['room'] ?? '',
        day: json['day'] ?? 1,
        startSection: json['startSection'] ?? 1,
        endSection: json['endSection'] ?? 1,
        weeks: (json['weeks'] as List? ?? []).cast<int>().toSet(),
      );
}