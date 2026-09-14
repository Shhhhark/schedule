import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SectionTime {
  final int hour;
  final int minute;
  const SectionTime(this.hour, this.minute);

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'h': hour, 'm': minute};
  factory SectionTime.fromJson(Map<String, dynamic> j) =>
      SectionTime(j['h'] as int, j['m'] as int);
}

class Settings {
  static const _kSectionTimes = 'section_times';

  static const List<SectionTime> defaultSectionTimes = [
    SectionTime(8, 0),
    SectionTime(8, 55),
    SectionTime(10, 0),
    SectionTime(10, 55),
    SectionTime(14, 0),
    SectionTime(14, 55),
    SectionTime(16, 0),
    SectionTime(16, 55),
    SectionTime(19, 0),
    SectionTime(19, 55),
    SectionTime(20, 50),
    SectionTime(21, 45),
  ];

  static Future<List<SectionTime>> loadSectionTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kSectionTimes);
    if (str == null) return List.of(defaultSectionTimes);
    final list = (jsonDecode(str) as List)
        .map((e) => SectionTime.fromJson(e as Map<String, dynamic>))
        .toList();
    while (list.length < 12) {
      list.add(defaultSectionTimes[list.length]);
    }
    return list;
  }

  static Future<void> saveSectionTimes(List<SectionTime> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSectionTimes,
      jsonEncode(times.map((e) => e.toJson()).toList()),
    );
  }
}