import 'package:flutter/material.dart';
import '../services/settings.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<SectionTime> _times = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _times = await Settings.loadSectionTimes();
    setState(() => _loading = false);
  }

  Future<void> _pickTime(int index) async {
    final t = _times[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _times[index] = SectionTime(picked.hour, picked.minute));
    await Settings.saveSectionTimes(_times);
  }

  Future<void> _resetDefault() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('恢复默认作息？'),
        content: const Text('当前自定义的上课时间将被替换。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _times = List.of(Settings.defaultSectionTimes));
    await Settings.saveSectionTimes(_times);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            onPressed: _resetDefault,
            icon: const Icon(Icons.restore_rounded),
            tooltip: '恢复默认',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _sectionHeader('上课时间', '点任意一节修改开始时刻'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow(),
                  ),
                  child: Column(
                    children: List.generate(_times.length, (i) {
                      final isLast = i == _times.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.vertical(
                              top: i == 0
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                            onTap: () => _pickTime(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      '第 ${i + 1} 节',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _times[i].label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              indent: 64,
                              endIndent: 16,
                              color: AppTheme.divider,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('关于', null),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow(),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: AppTheme.primary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '账号密码仅在登录网页时使用，本应用不会保存。课表数据只存储在本地。',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}