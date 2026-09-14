import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester.dart';

class Storage {
  static const _kSemesters = 'semesters';
  static const _kCurrent = 'current_semester';

  static Future<List<Semester>> loadSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kSemesters);
    if (str == null) return [];
    return (jsonDecode(str) as List)
        .map((e) => Semester.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSemesters(List<Semester> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSemesters,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> loadCurrentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrent);
  }

  static Future<void> saveCurrentName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrent, name);
  }
}