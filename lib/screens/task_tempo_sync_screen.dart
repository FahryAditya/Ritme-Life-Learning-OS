import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/pomodoro_timer_dialog.dart';
import '../widgets/weekly_bar_chart_widget.dart';

class TaskTempoSyncScreen extends StatefulWidget {
  const TaskTempoSyncScreen({super.key});

  @override
  State<TaskTempoSyncScreen> createState() => _TaskTempoSyncScreenState();
}

class _TaskTempoSyncScreenState extends State<TaskTempoSyncScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  TaskModel? _activeTask;
  List<TaskModel> _upcomingTasks = [];
  bool _isLoading = true;

  int _selectedPreset = 0;
  int _currentBpm = 62;
  bool _autoTransition = true;
  bool _dynamicDucking = true;
  String _viewMode = 'list'; // 'list' or 'kanban'
  List<int> _weeklyFocusMinutes = List.filled(7, 0);
  int _totalFocusMinutes = 0;

  final List<Map<String, dynamic>> _presets = [
    {
      'title': 'Deep Flow (60-70 BPM)',
      'bpm': 62,
      'icon': Icons.check,
      'genre': 'Lo-Fi Ambient Instrumental, Zero Lyrics',
    },
    {
      'title': 'Creative Pulse (80-100 BPM)',
      'bpm': 88,
      'icon': Icons.lightbulb_outline,
      'genre': 'Downtempo Synthwave & Neo-Jazz Beats',
    },
    {
      'title': 'Sprint Energy (110-130 BPM)',
      'bpm': 120,
      'icon': Icons.rocket_launch_outlined,
      'genre': 'High Tempo Electro-Acoustic Drive',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 960),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _loadDataFromDb();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadDataFromDb();
  }

  @override
  void dispose() {
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromDb() async {
    final active = await DatabaseHelper.instance.getActiveTask();
    final allTasks = await DatabaseHelper.instance.getTasks();
    final weeklyMins = await DatabaseHelper.instance.getWeeklyFocusMinutes();
    final totalMins = await DatabaseHelper.instance.getTotalFocusMinutesThisWeek();

    if (mounted) {
      setState(() {
        _activeTask = active ?? (allTasks.isNotEmpty ? allTasks.first : null);
        if (_activeTask != null) {
          _currentBpm = _activeTask!.bpm;
        }
        _upcomingTasks = allTasks.where((t) => t.id != _activeTask?.id).toList();
        _weeklyFocusMinutes = weeklyMins;
        _totalFocusMinutes = totalMins;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFocusSession(int minutes) async {
    final session = FocusSessionModel(
      taskId: _activeTask?.id,
      taskTitle: _activeTask?.title ?? 'Sesi Bebas',
      durationMinutes: minutes,
      sessionType: 'focus',
    );
    await DatabaseHelper.instance.saveFocusSession(session);
    _loadDataFromDb();
  }

  Future<void> _switchToTask(TaskModel task) async {
    if (task.id == null) return;
    await DatabaseHelper.instance.setActiveTask(task.id!);
    RitmeDataNotifier.instance.notifyDataChanged();
    await _loadDataFromDb();
  }

  void _showFocusTimerDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _FocusSessionDialog(task: task);
      },
    );
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _currentBpm = _presets[index]['bpm'] as int;
    });
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    int cognitive = 75;
    int bpm = 65;
    String genre = 'Lo-Fi Ambient Instrumental';
    bool isUrgent = true;
    bool isAnalyzingAi = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Tugas Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Tugas',
                        hintText: 'Misal: Review API Dokumen',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilterChip(
                      label: Text(
                        isUrgent ? 'Urgensi Tinggi (Deep Work)' : 'Urgensi Normal (Light Work)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUrgent ? AppColors.onErrorContainer : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isUrgent,
                      selectedColor: AppColors.errorContainer,
                      onSelected: (val) {
                        setDialogState(() => isUrgent = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Rekomendasikan BPM via Gemini
                    OutlinedButton.icon(
                      onPressed: isAnalyzingAi
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;

                              setDialogState(() => isAnalyzingAi = true);
                              final res = await GeminiService.instance
                                  .recommendBpmForTask(
                                      title, isUrgent ? 'Tinggi' : 'Normal');

                              setDialogState(() {
                                isAnalyzingAi = false;
                                bpm = res['bpm'] as int;
                                genre = res['genre'] as String;
                              });
                            },
                      icon: isAnalyzingAi
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        isAnalyzingAi
                            ? 'Gemini Menganalisis...'
                            : 'AI Auto-Detect BPM & Genre',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primaryFixed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'BPM Musik: $bpm ($genre)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Estimasi Beban Kognitif: $cognitive%',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    Slider(
                      value: cognitive.toDouble(),
                      min: 20,
                      max: 100,
                      divisions: 16,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setDialogState(() => cognitive = val.round());
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final newTask = TaskModel(
                      title: title,
                      category: isUrgent ? 'Deep Work • Prioritas' : 'Reguler Work',
                      isUrgent: isUrgent,
                      isImportant: true,
                      cognitiveLoad: cognitive,
                      bpm: bpm,
                      genre: genre,
                      isActive: false,
                      scheduledTime: 'Segera',
                    );

                    await DatabaseHelper.instance.insertTask(newTask);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadDataFromDb();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Simpan ke SQLite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final active = _activeTask;
    final cognitiveLoad = active?.cognitiveLoad ?? 80;

    return Stack(
      children: [
        // Ambient background glow orbs
        Positioned(
          top: -40,
          left: 40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.14),
            ),
          ),
        ),
        Positioned(
          top: 280,
          right: -50,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer.withValues(alpha: 0.14),
            ),
          ),
        ),

        // Scrollable content
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Context Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: AppColors.onPrimaryFixed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Gemini Dynamic Music & Productivity Engine',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onPrimaryFixed,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Toggle Kanban / List View
                      GestureDetector(
                        onTap: () => setState(() =>
                            _viewMode = _viewMode == 'list' ? 'kanban' : 'list'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _viewMode == 'kanban'
                                ? AppColors.primaryFixed
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _viewMode == 'kanban'
                                    ? Icons.view_column_outlined
                                    : Icons.view_list_outlined,
                                size: 16,
                                color: _viewMode == 'kanban'
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _viewMode == 'kanban' ? 'Kanban' : 'List',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _viewMode == 'kanban'
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 26),
                        tooltip: 'Tambah Tugas',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title and Live Sync status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Task-Tempo Sync',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3 + 0.5 * _pulseController.value),
                              blurRadius: 8 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Data tugas real-time tersimpan di database SQLite lokal.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),

              // Active Focus Mode Status Hero Card (Glassmorphic)
              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Task Meta Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: active != null
                                ? AppColors.errorContainer
                                : AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active != null ? Icons.priority_high : Icons.hourglass_empty,
                                size: 13,
                                color: active != null
                                    ? AppColors.onErrorContainer
                                    : AppColors.onSecondaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                active?.category ?? 'Mode Siaga • Belum Ada Tugas',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: active != null
                                          ? AppColors.onErrorContainer
                                          : AppColors.onSecondaryFixed,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.storage,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SQLite Sync',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Current Task Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active != null ? 'TUGAS BERJALAN AKTIF' : 'STATUS SISTEM',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                active?.title ?? 'Belum ada tugas aktif berjalan',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      height: 1.25,
                                    ),
                              ),
                              if (active == null) ...[
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _showAddTaskDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Buat Tugas Pertama'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C4CE0), Color(0xFF987CFE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            active != null ? Icons.laptop_chromebook : Icons.bedtime_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // BPM Pulse Rhythm Ring & Visualizer Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          // Animated Pulse Ring
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.08);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondaryContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$_currentBpm',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          height: 1.0,
                                        ),
                                      ),
                                      const Text(
                                        'BPM',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),

                          // BPM labels
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'BPM Terkunci: $_currentBpm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.lock,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  active?.genre ?? _presets[_selectedPreset]['genre'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Live soundwave bars
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(5, (i) {
                                  final heights = [
                                    12.0,
                                    22.0,
                                    16.0,
                                    26.0,
                                    14.0
                                  ];
                                  final factor =
                                      (i % 2 == 0) ? _waveController.value : (1 - _waveController.value);
                                  return Container(
                                    width: 3,
                                    height: (heights[i] * (0.5 + 0.5 * factor)).clamp(6.0, 28.0),
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (active != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showFocusTimerDialog(active),
                          icon: const Icon(Icons.play_circle_fill, size: 20),
                          label: const Text('Mulai Sesi Fokus (Timer & BPM Sync)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Cognitive Load Progress Meter
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Beban Kognitif Otak',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              '$cognitiveLoad% (${cognitiveLoad > 70 ? 'Tinggi' : 'Sedang'})',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cognitiveLoad > 70 ? AppColors.error : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 7,
                            width: double.infinity,
                            color: AppColors.surfaceContainerHigh,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (cognitiveLoad / 100).clamp(0.1, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.secondaryContainer,
                                      cognitiveLoad > 70 ? AppColors.error : AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Connected Streaming Service Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              active != null ? Icons.graphic_eq : Icons.music_off_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  active != null ? 'Spotify Terkoneksi' : 'Audio Engine Ritme',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  active != null
                                      ? active.genre
                                      : 'Mode Siaga • Putar musik saat tugas dimulai',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.open_in_new, size: 18),
                            color: AppColors.primary,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pomodoro Focus Timer Launch Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => PomodoroTimerDialog(
                              taskTitle: active?.title ?? 'Tugas Fokus Ritme',
                              bpm: _currentBpm,
                              onSessionComplete: _saveFocusSession,
                            ),
                          );
                        },
                        icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        label: const Text(
                          'Mulai Sesi Pomodoro (25 Min)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 24),

              // Task View: List or Kanban Board
              if (_viewMode == 'list') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.upcoming, size: 20, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Jadwal Pergeseran Dinamis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${_upcomingTasks.length} Tugas Terjadwal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_upcomingTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        active != null
                            ? 'Semua tugas lainnya terselesaikan! Sentuh + di atas untuk menambah tugas baru.'
                            : 'Belum ada jadwal tugas di database SQLite. Sentuh tombol + di atas untuk menambahkan tugas baru.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ..._upcomingTasks.map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _switchToTask(t),
                        borderRadius: BorderRadius.circular(18),
                        child: _buildShiftCard(
                          time: '${t.scheduledTime} (Sentuh untuk aktifkan)',
                          cognitiveLevel: t.category,
                          badgeColor: t.isUrgent ? AppColors.errorContainer : AppColors.primaryFixed,
                          badgeTextColor: t.isUrgent ? AppColors.onErrorContainer : AppColors.onPrimaryFixed,
                          icon: t.isUrgent ? Icons.bolt : Icons.task_alt,
                          iconBgColor: AppColors.secondaryFixed,
                          iconColor: AppColors.onSecondaryFixed,
                          title: t.title,
                          bpm: '${t.bpm} BPM',
                          genre: t.genre,
                        ),
                      ),
                    );
                  }),
              ] else ...[
                // KANBAN BOARD VIEW
                _buildKanbanBoard(),
              ],
              const SizedBox(height: 18),

              // Mode Switcher Chips (Favorite AI Tempo Presets)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preset Tempo AI Favorit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Sentuh untuk override',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_presets.length, (index) {
                    final isSelected = _selectedPreset == index;
                    final preset = _presets[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        onPressed: () => _selectPreset(index),
                        avatar: Icon(
                          isSelected ? Icons.check : preset['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                        label: Text(
                          preset['title'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceContainerLowest,
                        elevation: isSelected ? 3 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Focus Stats Section
              _buildFocusStatsSection(),
              const SizedBox(height: 24),

              // Real-time Sync Controls & Sensitivity Toggles
              GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pengaturan Sensitivitas Gemini',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Toggle 1
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Otomatis Transisi Lagu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Ganti BPM otomatis begitu Anda beralih tugas di Ritme',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoTransition,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() => _autoTransition = val);
                          },
                        ),
                      ],
                    ),
                    Divider(
                      height: 24,
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
                    ),

                    // Toggle 2
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dynamic Ducking Notifikasi',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Turunkan volume perlahan hanya untuk pesan prioritas Eisenhower',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _dynamicDucking,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() => _dynamicDucking = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily Metric Delight Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6DEFF), Color(0xFFE7DEFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EFISIENSI HARI INI',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.onPrimaryFixedVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            active != null ? 'Fokus Meningkat +32%' : 'Sistem Ritme Siaga',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.onPrimaryFixed,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            active != null
                                ? 'Didukung sinkronisasi tempo real-time'
                                : 'Mulai tugas pertamamu untuk melacak efisiensi fokus hari ini.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onPrimaryFixedVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutBack),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusStatsSection() {
    final todayIndex = DateTime.now().weekday - 1;
    final totalH = _totalFocusMinutes ~/ 60;
    final totalM = _totalFocusMinutes % 60;

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Statistik Fokus Minggu Ini',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _totalFocusMinutes > 0
                      ? '${totalH}j ${totalM}m total'
                      : 'Mulai sesi pertama!',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryFixed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeeklyBarChartWidget(
            minutesPerDay: _weeklyFocusMinutes,
            todayIndex: todayIndex,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap tombol Selesai di Pomodoro untuk merekam sesi',
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildKanbanBoard() {
    final allTasks = [
      ?_activeTask,
      ..._upcomingTasks,
    ];
    final todo = allTasks.where((t) => !t.isCompleted && !t.isActive).toList();
    final inProgress = allTasks.where((t) => t.isActive && !t.isCompleted).toList();
    final done = allTasks.where((t) => t.isCompleted).toList();

    return SizedBox(
      height: 340,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn('Todo', todo, AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant, 'todo'),
          const SizedBox(width: 8),
          _buildKanbanColumn('In Progress', inProgress, AppColors.primaryFixed, AppColors.primary, 'active'),
          const SizedBox(width: 8),
          _buildKanbanColumn('Selesai', done, const Color(0xFFE8F5E9), Colors.green, 'done'),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<TaskModel> tasks,
    Color bgColor,
    Color titleColor,
    String columnId,
  ) {
    return Expanded(
      child: DragTarget<TaskModel>(
        onAcceptWithDetails: (details) async {
          final task = details.data;
          if (task.id == null) return;
          if (columnId == 'active') {
            await DatabaseHelper.instance.setActiveTask(task.id!);
          } else if (columnId == 'done') {
            await DatabaseHelper.instance.updateTask(task.copyWith(isCompleted: true, isActive: false));
          } else {
            await DatabaseHelper.instance.updateTask(task.copyWith(isCompleted: false, isActive: false));
          }
          RitmeDataNotifier.instance.notifyDataChanged();
          await _loadDataFromDb();
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHovered ? bgColor.withValues(alpha: 0.8) : bgColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered ? titleColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: titleColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: titleColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: titleColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return Draggable<TaskModel>(
                        data: t,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              t.title,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildKanbanCard(t),
                        ),
                        child: _buildKanbanCard(t),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKanbanCard(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.speed, size: 10, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${task.bpm} BPM',
                  style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(fontSize: 8, color: AppColors.onErrorContainer, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard({
    required String time,
    required String cognitiveLevel,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String bpm,
    required String genre,
  }) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cognitiveLevel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const TextSpan(text: 'Auto-shift: '),
                                TextSpan(
                                  text: bpm,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' • $genre'),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusSessionDialog extends StatefulWidget {
  final TaskModel task;

  const _FocusSessionDialog({required this.task});

  @override
  State<_FocusSessionDialog> createState() => _FocusSessionDialogState();
}

class _FocusSessionDialogState extends State<_FocusSessionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _secondsRemaining = 25 * 60; // 25 minutes Pomodoro
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    final msPerBeat = (60000 / widget.task.bpm).round();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: msPerBeat),
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRunning) return false;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Sesi Fokus Deep Work',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.aiOrbGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withValues(
                              alpha: 0.35 + 0.3 * _pulseController.value),
                          blurRadius: 30,
                          spreadRadius: 6 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.task.bpm}\nBPM',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              widget.task.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.task.genre,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Text(
              _formatTime(_secondsRemaining),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isRunning = !_isRunning);
                    if (_isRunning) _startTimer();
                  },
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Jeda' : 'Lanjut'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Selesai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
