import '../models/course.dart';

class ZfParser {
  /// 解析正方课表返回体中的 kbList
  static List<Course> parseKbList(dynamic data) {
    if (data is! Map) return [];
    final list = (data['kbList'] as List?) ?? [];
    return list.map<Course>((e) {
      final sections = _parseSections(e['jcs']?.toString() ?? '1-1');
      return Course(
        name: e['kcmc']?.toString() ?? '未知课程',
        teacher: e['xm']?.toString() ?? '',
        room: e['cdmc']?.toString() ?? '',
        day: int.tryParse(e['xqj']?.toString() ?? '1') ?? 1,
        startSection: sections[0],
        endSection: sections[1],
        weeks: parseWeeks(e['zcd']?.toString()),
      );
    }).toList();
  }

  /// 解析节次，如 "3-4" / "5"
  static List<int> _parseSections(String jcs) {
    final s = jcs.replaceAll(RegExp(r'[^0-9-]'), '');
    final parts = s.split('-');
    if (parts.length == 1) {
      final v = int.tryParse(parts[0]) ?? 1;
      return [v, v];
    }
    final start = int.tryParse(parts[0]) ?? 1;
    final end = int.tryParse(parts[1]) ?? start;
    return [start, end];
  }

  /// 解析周次字符串
  /// 支持："1-16周"、"1-16周(单)"、"1-8,10-16周"、"1,3,5周"、"3-14"
  static Set<int> parseWeeks(String? zcd) {
    if (zcd == null || zcd.isEmpty) return {};
    final result = <int>{};
    var s = zcd.replaceAll('周', '').trim();

    final isOdd = s.contains('单');
    final isEven = s.contains('双');
    s = s
        .replaceAll('(单)', '')
        .replaceAll('(双)', '')
        .replaceAll('单', '')
        .replaceAll('双', '')
        .trim();

    for (final part in s.split(',')) {
      final p = part.trim();
      if (p.isEmpty) continue;

      if (p.contains('-')) {
        final bounds = p.split('-');
        final start = int.tryParse(bounds[0].trim());
        final end = int.tryParse(bounds[1].trim());
        if (start == null || end == null) continue;
        for (var i = start; i <= end; i++) {
          if (isOdd && i.isEven) continue;
          if (isEven && i.isOdd) continue;
          result.add(i);
        }
      } else {
        final v = int.tryParse(p);
        if (v == null) continue;
        if (isOdd && v.isEven) continue;
        if (isEven && v.isOdd) continue;
        result.add(v);
      }
    }
    return result;
  }
}