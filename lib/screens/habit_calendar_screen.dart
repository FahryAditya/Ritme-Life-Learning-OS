import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/habit_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HabitCalendarScreen extends StatefulWidget {
  const HabitCalendarScreen({super.key});

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  List<HabitModel> _habits = [];
  bool _isLoading = true;
  int? _selectedDayIndex; // index in _last84Days

  // 84 hari = 12 minggu terakhir
  late final List<DateTime> _last84Days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Mulai dari hari Monday 12 minggu lalu
    final today = DateTime(now.year, now.month, now.day);
    final daysToMonday = today.weekday - 1;
    final startOfWeek = today.subtract(Duration(days: daysToMonday));
    final startDate = startOfWeek.subtract(const Duration(days: 77)); // 11 minggu ke belakang

    _last84Days = List.generate(84, (i) => startDate.add(Duration(days: i)));
    _loadData();
  }

  Future<void> _loadData() async {
    final habits = await DatabaseHelper.instance.getHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    }
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Menentukan "level" aktivitas habit pada suatu hari (0-4)
  int _getActivityLevel(DateTime day) {
    final dayStr = _dateStr(day);
    int completedCount = 0;
    for (final h in _habits) {
      if (h.lastCompletedDate == dayStr) {
        completedCount++;
      } else if (dayStr == _todayStr && h.isCompletedToday) {
        completedCount++;
      }
    }
    if (_habits.isEmpty) return 0;
    final ratio = completedCount / _habits.length;
    if (ratio == 0) return 0;
    if (ratio <= 0.25) return 1;
    if (ratio <= 0.5) return 2;
    if (ratio <= 0.75) return 3;
    return 4;
  }

  Color _levelToColor(int level) {
    switch (level) {
      case 1:
        return AppColors.primaryFixed;
      case 2:
        return AppColors.primaryFixed.withValues(alpha: 0.8);
      case 3:
        return AppColors.primary.withValues(alpha: 0.5);
      case 4:
        return AppColors.primary;
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  int get _totalActiveDays {
    return _last84Days.where((d) => _getActivityLevel(d) > 0).length;
  }

  int get _longestStreak {
    int max = 0;
    int cur = 0;
    for (final h in _habits) {
      cur = h.streakCount;
      if (cur > max) max = cur;
    }
    return max;
  }

  HabitModel? get _bestHabit {
    if (_habits.isEmpty) return null;
    return _habits.reduce((a, b) => a.streakCount >= b.streakCount ? a : b);
  }

  String _formatMonth(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[d.month];
  }

  List<HabitModel> _habitsCompletedOn(DateTime day) {
    final dayStr = _dateStr(day);
    return _habits.where((h) {
      if (dayStr == _todayStr) return h.isCompletedToday;
      return h.lastCompletedDate == dayStr;
    }).toList();
  }

  void _onDayTap(int index) {
    setState(() {
      _selectedDayIndex = _selectedDayIndex == index ? null : index;
    });
    if (_selectedDayIndex != null) {
      _showDayDetail(_last84Days[_selectedDayIndex!]);
    }
  }

  void _showDayDetail(DateTime day) {
    final completed = _habitsCompletedOn(day);
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${days[day.weekday]}, ${day.day} ${months[day.month]}',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${completed.length} dari ${_habits.length} habit selesai',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (completed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Tidak ada habit yang tercatat\npada hari ini',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ...completed.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h.title,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${h.streakCount} hari',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryHeader()),
                SliverToBoxAdapter(child: _buildHeatmap()),
                SliverToBoxAdapter(child: _buildHabitList()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final best = _bestHabit;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatBadge(
                icon: Icons.local_fire_department,
                label: 'Longest Streak',
                value: '$_longestStreak Hari',
                color: const Color(0xFFFF7043),
              ),
              const SizedBox(width: 10),
              _buildStatBadge(
                icon: Icons.calendar_month_outlined,
                label: 'Hari Aktif',
                value: '$_totalActiveDays Hari',
                color: AppColors.primary,
              ),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryFixed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Best Habit',
                          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          best.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${best.streakCount} hari',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04);
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    // Build month label row
    final monthLabels = <Widget>[];
    DateTime? lastMonth;
    for (int col = 0; col < 12; col++) {
      final day = _last84Days[col * 7];
      if (lastMonth == null || day.month != lastMonth.month) {
        lastMonth = day;
        monthLabels.add(
          SizedBox(
            width: 28,
            child: Text(
              _formatMonth(day),
              style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant),
            ),
          ),
        );
      } else {
        monthLabels.add(const SizedBox(width: 28));
      }
    }

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Streak Heatmap — 12 Minggu Terakhir',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day labels (Mon-Sun)
          Row(
            children: [
              const SizedBox(width: 14),
              ...['S', 'S', 'R', 'K', 'J', 'S', 'M'].map(
                (d) => SizedBox(
                  width: 28,
                  child: RotatedBox(
                    quarterTurns: 0,
                    child: Text(
                      d,
                      style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // The grid: columns = weeks, rows = days (Mon-Sun)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(12, (week) {
                return Column(
                  children: List.generate(7, (dayOfWeek) {
                    final idx = week * 7 + dayOfWeek;
                    if (idx >= _last84Days.length) return const SizedBox(width: 28, height: 28);
                    final day = _last84Days[idx];
                    final level = _getActivityLevel(day);
                    final isToday = _dateStr(day) == _todayStr;
                    final isFuture = day.isAfter(DateTime.now());

                    return GestureDetector(
                      onTap: isFuture ? null : () => _onDayTap(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isFuture
                              ? AppColors.surfaceContainer.withValues(alpha: 0.3)
                              : _levelToColor(level),
                          borderRadius: BorderRadius.circular(5),
                          border: isToday
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              const Text('Kurang', style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: _levelToColor(i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
              const SizedBox(width: 4),
              const Text('Penuh', style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildHabitList() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Daftar Habit Aktif',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_habits.isEmpty)
            const Text(
              'Belum ada habit. Tambahkan di Home.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            )
          else
            ..._habits.asMap().entries.map((e) {
              final h = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: h.isCompletedToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        h.isCompletedToday ? Icons.check : Icons.radio_button_unchecked,
                        color: h.isCompletedToday ? AppColors.primary : AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: h.isCompletedToday
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: h.isCompletedToday
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurface,
                                ),
                          ),
                          Text(
                            h.category,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${h.streakCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: Duration(milliseconds: 60 * e.key), duration: 250.ms),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}
