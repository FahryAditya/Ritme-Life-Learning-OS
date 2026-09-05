import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../models/habit_model.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'habit_calendar_screen.dart';
import 'reflection_journal_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  double _balance = 0.0;
  int _pendingTasksCount = 0;
  TaskModel? _activeTask;
  List<TransactionModel> _recentTxs = [];
  List<HabitModel> _habits = [];
  Map<String, dynamic>? _burnoutRadar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadDashboardData();
  }

  @override
  void dispose() {
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final balance = await DatabaseHelper.instance.calculateTotalBalance();
    final tasks = await DatabaseHelper.instance.getTasks(onlyIncomplete: true);
    final active = await DatabaseHelper.instance.getActiveTask();
    final txs = await DatabaseHelper.instance.getTransactions();
    final habits = await DatabaseHelper.instance.getHabits();
    final burnout = await GeminiService.instance.generateBurnoutRadar(tasks);

    if (mounted) {
      setState(() {
        _balance = balance;
        _pendingTasksCount = tasks.length;
        _activeTask = active ?? (tasks.isNotEmpty ? tasks.first : null);
        _recentTxs = txs.take(3).toList();
        _habits = habits;
        _burnoutRadar = burnout;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Stack(
      children: [
        // Ambient background glow
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          top: 350,
          left: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer.withValues(alpha: 0.1),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Creative!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Life OS tersinkronisasi dengan SQLite lokal.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0),
              const SizedBox(height: 18),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks, tempo, finance...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.outline,
                    ),
                    suffixIcon: const Icon(
                      Icons.tune,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 22),

              // Hero Card: Today's Briefing
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF532EC7), Color(0xFF6C4CE0), Color(0xFF8B6FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Today's AI Briefing",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Live SQLite',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _pendingTasksCount == 0 && _balance == 0.0 && _activeTask == null
                          ? 'Selamat datang di Ritme! Belum ada tugas atau transaksi tercatat. Mulai atur ritme produktivitas & fokus belajarmu hari ini.'
                          : '$_pendingTasksCount tugas aktif di SQLite, total saldo kas Rp ${_formatRupiah(_balance)}, ritme fokus ${_activeTask?.bpm ?? 60} BPM terkunci.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => widget.onNavigateTab?.call(1),
                          icon: const Icon(Icons.headphones, size: 16),
                          label: const Text('Mulai Sesi Tempo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => widget.onNavigateTab?.call(2),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          child: const Text('Tanya AI'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.08, end: 0).shimmer(delay: 600.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 20),

              // Floating Overlapping Mini Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.track_changes,
                      iconColor: AppColors.primary,
                      title: 'Focus BPM',
                      value: '${_activeTask?.bpm ?? 60}',
                      badge: _activeTask != null ? 'Terkunci' : 'Siaga',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.assignment_outlined,
                      iconColor: Colors.deepOrange,
                      title: 'Tasks',
                      value: '$_pendingTasksCount Item',
                      badge: 'SQLite',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: AppColors.secondary,
                      title: 'Saldo Kas',
                      value: 'Rp ${_formatRupiah(_balance)}',
                      badge: _balance > 0 ? 'Aman' : 'Kosong',
                      isPositive: _balance >= 0,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 24),

              // AI Burnout Radar Card
              if (_burnoutRadar != null) ...[
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed, color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Radar Burnout & Kognitif AI',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_burnoutRadar!['riskLevel'] == 'Tinggi'
                                      ? Colors.red.shade100
                                      : (_burnoutRadar!['riskLevel'] == 'Sedang'
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Risiko ${_burnoutRadar!['riskLevel']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (_burnoutRadar!['riskLevel'] == 'Tinggi'
                                    ? Colors.red.shade900
                                    : (_burnoutRadar!['riskLevel'] == 'Sedang'
                                        ? Colors.orange.shade900
                                        : Colors.green.shade900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ((_burnoutRadar!['riskScore'] as int) / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _burnoutRadar!['riskLevel'] == 'Tinggi'
                                ? Colors.red
                                : (_burnoutRadar!['riskLevel'] == 'Sedang'
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _burnoutRadar!['recommendation'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
              ],

              // Ritme Habit Tracker Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habit Tracker & Daily Streaks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_habits.where((h) => h.isCompletedToday).length}/${_habits.length} Selesai',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HabitCalendarScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.grid_view_rounded, size: 12, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Kalender',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _habits.map((habit) {
                    return Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: habit.isCompletedToday ? AppColors.primaryContainer.withValues(alpha: 0.25) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: habit.isCompletedToday ? AppColors.primary : AppColors.surfaceContainerHigh,
                          width: habit.isCompletedToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.whatshot, size: 12, color: Colors.deepOrange),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${habit.streakCount} Hari',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  await DatabaseHelper.instance.toggleHabitCompletion(habit);
                                  RitmeDataNotifier.instance.notifyDataChanged();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Icon(
                                  habit.isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: habit.isCompletedToday ? AppColors.primary : AppColors.onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            habit.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            habit.category,
                            style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Module Quick-Access Row
              Text(
                'Modul Ritme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModuleCard(
                      icon: Icons.check_circle_outline,
                      title: 'Tasks',
                      subtitle: '$_pendingTasksCount di SQLite',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C4CE0), Color(0xFF987CFE)],
                      ),
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                    const SizedBox(width: 12),
                    _buildModuleCard(
                      icon: Icons.music_note,
                      title: 'Tempo Sync',
                      subtitle: '${_activeTask?.bpm ?? 62} BPM Lo-Fi',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF532EC7), Color(0xFF6446C6)],
                      ),
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                    const SizedBox(width: 12),
                    _buildModuleCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Finance',
                      subtitle: 'Rp ${_formatRupiah(_balance)}',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6446C6), Color(0xFF8B6FF0)],
                      ),
                      onTap: () => widget.onNavigateTab?.call(3),
                    ),
                    const SizedBox(width: 12),
                    _buildModuleCard(
                      icon: Icons.mic_none_outlined,
                      title: 'Voice AI',
                      subtitle: 'Voice to Text',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF534978), Color(0xFF6B6192)],
                      ),
                      onTap: () => widget.onNavigateTab?.call(4),
                    ),
                    const SizedBox(width: 12),
                    _buildModuleCard(
                      icon: Icons.grid_view_rounded,
                      title: 'Habit Cal',
                      subtitle: 'Streak Heatmap',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HabitCalendarScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildModuleCard(
                      icon: Icons.auto_stories,
                      title: 'Jurnal',
                      subtitle: 'Refleksi Harian',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReflectionJournalScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions & Activities from SQLite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas SQLite Terbaru',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(3),
                    child: const Text('Buka Kas'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_recentTxs.isEmpty)
                _buildActivityItem(
                  icon: Icons.checklist_rtl,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryFixed,
                  title: 'Belum ada riwayat transaksi. Sentuh Buka Kas untuk mencatat.',
                  time: 'Data Kosong',
                  module: 'Finance',
                )
              else
                ..._recentTxs.map((tx) {
                  return _buildActivityItem(
                    icon: tx.isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                    iconColor: tx.isExpense ? AppColors.error : Colors.green,
                    iconBg: tx.isExpense ? AppColors.errorContainer : Colors.green.withValues(alpha: 0.15),
                    title: '${tx.title} (${tx.isExpense ? '-' : '+'}Rp ${_formatRupiah(tx.amount)})',
                    time: tx.date,
                    module: 'Finance',
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String badge,
    required bool isPositive,
  }) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.onPrimaryFixed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 135,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String time,
    required String module,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              module,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
