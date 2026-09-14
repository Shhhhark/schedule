import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../services/settings.dart';
import '../theme/app_theme.dart';
import 'settings_page.dart';

const double _cellHeight = 74;
const double _timeColWidth = 52;
const double _headerHeight = 56;
const int _maxSections = 12;

class TimetablePage extends StatefulWidget {
  final Semester semester;
  const TimetablePage({super.key, required this.semester});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int _week = 1;
  List<SectionTime> _times = Settings.defaultSectionTimes;

  @override
  void initState() {
    super.initState();
    _week = widget.semester.currentWeek() ?? 1;
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final t = await Settings.loadSectionTimes();
    if (mounted) setState(() => _times = t);
  }

  int? _todayWeek() => widget.semester.currentWeek();
  int _todayDay() => DateTime.now().weekday;

  void _gotoToday() {
    final w = _todayWeek();
    if (w == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天不在本学期的上课周内')),
      );
      return;
    }
    setState(() => _week = w);
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.semester.courses;
    final courses = all.where((c) => c.inWeek(_week)).toList();
    final conflicts = _detectConflicts(courses);

    final isThisWeek = _week == _todayWeek();
    final todayDay = _todayDay();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semester.name),
        actions: [
          _circleAction(
            icon: Icons.today_rounded,
            tooltip: '回到今天',
            onTap: _gotoToday,
          ),
          const SizedBox(width: 4),
          _circleAction(
            icon: Icons.tune_rounded,
            tooltip: '设置',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              await _loadTimes();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _weekSelector(isThisWeek),
          if (conflicts.isNotEmpty) _conflictBanner(conflicts.length),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow(),
              ),
              clipBehavior: Clip.antiAlias,
              child: _grid(
                courses,
                highlightDay: isThisWeek ? todayDay : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.primarySoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _weekSelector(bool isThisWeek) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow(opacity: 0.04, blur: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _week > 1 ? () => setState(() => _week--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.textPrimary,
          ),
          GestureDetector(
            onTap: _pickWeek,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '第 $_week 周',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (isThisWeek)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '本周',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _week < 30 ? () => setState(() => _week++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _conflictBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF57C00), size: 18),
          const SizedBox(width: 8),
          Text(
            '本周有 $count 处课程时间冲突',
            style: const TextStyle(
              color: Color(0xFFB45309),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWeek() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _WeekPickerSheet(current: _week),
    );
    if (picked != null) setState(() => _week = picked);
  }

  Widget _grid(List<Course> courses, {int? highlightDay}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth = (constraints.maxWidth - _timeColWidth) / 7;

        return SingleChildScrollView(
          child: SizedBox(
            width: constraints.maxWidth,
            height: _headerHeight + _maxSections * _cellHeight,
            child: Stack(
              children: [
                // 今天整列高亮
                if (highlightDay != null)
                  Positioned(
                    left: _timeColWidth + (highlightDay - 1) * dayWidth,
                    top: 0,
                    width: dayWidth,
                    height: _headerHeight + _maxSections * _cellHeight,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.045),
                          border: Border(
                            left: BorderSide(
                              color: AppTheme.primary.withOpacity(0.12),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: AppTheme.primary.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 星期表头
                Positioned(
                  left: _timeColWidth,
                  top: 0,
                  right: 0,
                  height: _headerHeight,
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isToday = highlightDay == day;
                      return SizedBox(
                        width: dayWidth,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '周${'一二三四五六日'[i]}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isToday
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isToday ? 18 : 0,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 横向分隔线
                for (var i = 1; i <= _maxSections; i++)
                  Positioned(
                    left: _timeColWidth,
                    right: 0,
                    top: _headerHeight + i * _cellHeight,
                    child: Container(height: 1, color: AppTheme.divider),
                  ),

                // 纵向分隔线
                for (var d = 1; d <= 7; d++)
                  Positioned(
                    left: _timeColWidth + d * dayWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: AppTheme.divider),
                  ),

                // 时间列
                Positioned(
                  left: 0,
                  top: 0,
                  width: _timeColWidth,
                  height: _headerHeight + _maxSections * _cellHeight,
                  child: Column(
                    children: List.generate(_maxSections, (i) {
                      final label = i < _times.length ? _times[i].label : '';
                      final isPast = _isPastSection(i + 1);
                      return Container(
                        height: _cellHeight,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isPast
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: isPast
                                    ? AppTheme.textMuted
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // 课程块
                ...courses.map((c) => _courseBlock(c, dayWidth)),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isPastSection(int section) {
    final todayWeek = _todayWeek();
    if (todayWeek == null || todayWeek != _week) return false;
    final now = DateTime.now();
    if (section - 1 >= _times.length) return false;
    final t = _times[section - 1];
    return now.hour * 60 + now.minute > t.hour * 60 + t.minute;
  }

  Widget _courseBlock(Course c, double dayWidth) {
    final base = AppTheme.colorFor(c.name);
    return Positioned(
      left: _timeColWidth + (c.day - 1) * dayWidth + 3,
      top: _headerHeight + (c.startSection - 1) * _cellHeight + 3,
      width: dayWidth - 6,
      height: (c.endSection - c.startSection + 1) * _cellHeight - 6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showCourseDetail(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.courseGradient(base),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: base.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const Spacer(),
                if (c.room.isNotEmpty) _smallLine('@${c.room}'),
                if (c.teacher.isNotEmpty) _smallLine(c.teacher),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallLine(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        color: Colors.white.withOpacity(0.88),
        height: 1.25,
      ),
    );
  }

  void _showCourseDetail(Course c) {
    final weeks = (c.weeks.toList()..sort());
    final weekText = _formatWeeks(weeks);
    final base = AppTheme.colorFor(c.name);

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.courseGradient(base),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.person_rounded, '教师',
                c.teacher.isEmpty ? '未填写' : c.teacher),
            _detailRow(Icons.location_on_rounded, '地点',
                c.room.isEmpty ? '未填写' : c.room),
            _detailRow(
              Icons.schedule_rounded,
              '节次',
              '周${'一二三四五六日'[c.day - 1]} · 第 ${c.startSection}-${c.endSection} 节',
            ),
            _detailRow(Icons.date_range_rounded, '周次', weekText),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '未指定';
    final ranges = <String>[];
    int start = weeks.first;
    int prev = weeks.first;
    for (var i = 1; i < weeks.length; i++) {
      if (weeks[i] == prev + 1) {
        prev = weeks[i];
      } else {
        ranges.add(start == prev ? '$start' : '$start-$prev');
        start = weeks[i];
        prev = weeks[i];
      }
    }
    ranges.add(start == prev ? '$start' : '$start-$prev');
    return '第 ${ranges.join(', ')} 周';
  }

  List<List<Course>> _detectConflicts(List<Course> courses) {
    final result = <List<Course>>[];
    for (var i = 0; i < courses.length; i++) {
      for (var j = i + 1; j < courses.length; j++) {
        final a = courses[i];
        final b = courses[j];
        if (a.day != b.day) continue;
        final overlap =
            a.startSection <= b.endSection && b.startSection <= a.endSection;
        if (overlap) result.add([a, b]);
      }
    }
    return result;
  }
}

class _WeekPickerSheet extends StatelessWidget {
  final int current;
  const _WeekPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择周次',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(30, (i) {
                final w = i + 1;
                final selected = w == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          selected ? AppTheme.primary : AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$w',
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}