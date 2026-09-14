import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../services/storage.dart';
import '../services/zf_parser.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'timetable_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Semester> _semesters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await Storage.loadSemesters();
    setState(() {
      _semesters = list;
      _loading = false;
    });
  }

  Future<void> _addSemester() async {
    final cookie = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (cookie == null || cookie.isEmpty) return;

    final start = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '选择第一周的周一',
    );
    if (start == null) return;

    final courses = await _fetch(cookie);
    if (courses == null) return;

    final name = await _inputName();
    if (name == null || name.isEmpty) return;

    final s = Semester(name: name, startDate: start, courses: courses);
    _semesters.add(s);
    await Storage.saveSemesters(_semesters);
    await Storage.saveCurrentName(name);
    setState(() {});
  }

  Future<String?> _inputName() {
    final ctrl = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().year + 1}-1',
    );
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('学期名称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如 2024-2025-1'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<List<Course>?> _fetch(String cookie) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        AppConfig.scheduleApiUrl,
        data: {'xnm': AppConfig.xnm, 'xqm': AppConfig.xqm, 'kzlx': 'ck'},
        options: Options(
          headers: {
            'Cookie': cookie,
            'User-Agent': AppConfig.userAgent,
            'Referer': AppConfig.referer,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      dynamic data = response.data;
      if (data is String) data = jsonDecode(data);
      return ZfParser.parseKbList(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取课表失败：$e')),
        );
      }
      return null;
    }
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除该学期？'),
        content: const Text('删除后本地课表数据将不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _semesters.removeAt(index));
    await Storage.saveSemesters(_semesters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '我的学期',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _semesters.isEmpty
                          ? '添加一个学期开始使用'
                          : '共 ${_semesters.length} 个学期',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_semesters.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyHome(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList.separated(
                itemCount: _semesters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _semesterCard(i),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSemester,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加学期'),
      ),
    );
  }

  Widget _semesterCard(int index) {
    final s = _semesters[index];
    final week = s.currentWeek();
    final progress = week == null ? 0.0 : (week / 20).clamp(0.0, 1.0);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TimetablePage(semester: s)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.courseGradient(AppTheme.primary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      week == null
                          ? '尚未开学'
                          : '第 $week 周 · 共 ${s.courses.length} 门课',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (week != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppTheme.primarySoft,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _delete(index),
                icon: const Icon(Icons.more_horiz_rounded),
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_note_rounded,
              size: 44,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '还没有课表',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '点击下方按钮，登录教务系统导入',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}