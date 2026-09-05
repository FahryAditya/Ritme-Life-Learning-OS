import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/journal_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ReflectionJournalScreen extends StatefulWidget {
  const ReflectionJournalScreen({super.key});

  @override
  State<ReflectionJournalScreen> createState() => _ReflectionJournalScreenState();
}

class _ReflectionJournalScreenState extends State<ReflectionJournalScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

  int _moodLevel = 3;
  int _streak = 0;
  JournalModel? _todayEntry;
  List<JournalModel> _allEntries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final String _todayDate =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

  static const List<String> _motivationalQuotes = [
    'Refleksi adalah cermin jiwa yang sejujurnya.',
    'Setiap hari adalah halaman baru yang bisa kamu tulis.',
    'Menulis membuat pikiran lebih jernih dan hati lebih tenang.',
    'Perjalanan dimulai dari satu langkah, jurnal dari satu kalimat.',
    'Tuliskan pikiranmu sebelum dunia mengisinya dengan kebisingan.',
    'Setiap momen yang dicatat adalah kenangan yang tidak akan pudar.',
    'Kejujuran pada diri sendiri adalah langkah pertama menuju pertumbuhan.',
    'Refleksi harian membantumu memahami siapa dirimu sebenarnya.',
    'Kata-kata yang kamu tulis hari ini adalah kebijaksanaan masa depanmu.',
    'Berhenti sejenak dan perhatikan betapa jauh kamu telah melangkah.',
    'Setiap perasaan layak untuk diakui dan dituliskan.',
    'Jurnal adalah teman yang tidak pernah menghakimi.',
    'Dalam kesederhanaan kata, tersimpan kedalaman makna.',
    'Pikiran yang dituliskan menjadi rencana yang bisa diwujudkan.',
    'Hari ini mungkin berat, tapi kamu cukup kuat untuk melewatinya.',
    'Setiap hari menawarkan kesempatan baru untuk berkembang.',
    'Tulisan tangan adalah jejak jiwa yang paling autentik.',
    'Bersyukur dimulai dari menyadari hal-hal kecil yang indah.',
    'Kamu tidak perlu sempurna untuk layak menuliskan hidupmu.',
    'Masa lalu adalah guru, masa kini adalah canvas, masa depan adalah karya.',
    'Konsistensi kecil menghasilkan perubahan besar.',
    'Refleksi membawa ketenangan di tengah kesibukan.',
    'Jadilah penulis cerita hidupmu sendiri.',
    'Setiap struggle yang kamu tulis adalah kemenangan yang kamu akui.',
    'Hari yang tidak dicatat tetaplah berharga, tapi hari yang dicatat menjadi legenda.',
    'Menulis adalah cara paling jujur untuk berbicara dengan diri sendiri.',
    'Dalam ketidaksempurnaan tulisanmu, tersimpan keindahan yang nyata.',
    'Satu halaman sehari mengubah perspektif seumur hidup.',
    'Pikiranmu layak untuk didengar — mulai dari dirimu sendiri.',
    'Hari ini, hadiah terbaik untukmu adalah waktu untuk merenung.',
  ];

  String get _todayQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _motivationalQuotes[dayOfYear % _motivationalQuotes.length];
  }

  static const List<IconData> _moodIcons = [
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_satisfied_outlined,
    Icons.sentiment_very_satisfied_outlined,
  ];

  static const List<String> _moodLabels = [
    'Buruk', 'Kurang', 'Biasa', 'Baik', 'Luar Biasa',
  ];

  static const List<Color> _moodColors = [
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFA726),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _contentFocus.addListener(() {
      if (!_contentFocus.hasFocus && _contentController.text.isNotEmpty) {
        _autoSave();
      }
    });
  }

  Future<void> _loadData() async {
    final today = await DatabaseHelper.instance.getJournalEntryByDate(_todayDate);
    final all = await DatabaseHelper.instance.getAllJournalEntries();
    final streak = await DatabaseHelper.instance.getJournalStreak();

    if (mounted) {
      setState(() {
        _todayEntry = today;
        _allEntries = all;
        _streak = streak;
        if (today != null) {
          _contentController.text = today.content;
          _moodLevel = today.moodLevel;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _autoSave() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final entry = JournalModel(
      date: _todayDate,
      content: _contentController.text.trim(),
      moodLevel: _moodLevel,
    );
    await DatabaseHelper.instance.saveJournalEntry(entry);
    final streak = await DatabaseHelper.instance.getJournalStreak();
    final all = await DatabaseHelper.instance.getAllJournalEntries();

    if (mounted) {
      setState(() {
        _todayEntry = entry;
        _allEntries = all;
        _streak = streak;
        _isSaving = false;
      });
    }
  }

  Future<void> _saveManually() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis sesuatu dulu sebelum menyimpan')),
      );
      return;
    }
    await _autoSave();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jurnal hari ini tersimpan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDisplayDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    const days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildTodayEditor()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Riwayat Jurnal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${_allEntries.length} entri',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                _allEntries.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Belum ada riwayat jurnal.\nMulai tulis hari ini!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildHistoryCard(_allEntries[i], i)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms)
                              .slideX(begin: 0.04),
                          childCount: _allEntries.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.15),
            AppColors.tertiaryContainer.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryFixed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jurnal Refleksi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      _formatDisplayDate(_todayDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _streak > 0 ? AppColors.primary : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: _streak > 0 ? Colors.white : AppColors.onSurfaceVariant,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_streak Hari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _streak > 0 ? Colors.white : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _todayQuote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildTodayEditor() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood Picker
          Text(
            'Bagaimana perasaanmu hari ini?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final isSelected = _moodLevel == i + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _moodLevel = i + 1);
                  if (_contentController.text.isNotEmpty) _autoSave();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _moodColors[i].withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _moodColors[i] : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _moodIcons[i],
                        color: isSelected ? _moodColors[i] : AppColors.onSurfaceVariant,
                        size: isSelected ? 28 : 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _moodLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? _moodColors[i] : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Text editor
          TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            maxLines: 8,
            minLines: 5,
            decoration: InputDecoration(
              hintText: 'Ceritakan harimu... apa yang terjadi, apa yang kamu rasakan, apa yang kamu pelajari.',
              hintStyle: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_isSaving)
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Menyimpan...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              else if (_todayEntry != null)
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Tersimpan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                    ),
                  ],
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saveManually,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Simpan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(JournalModel entry, int index) {
    final isToday = entry.date == _todayDate;
    final moodIdx = entry.moodLevel - 1;
    final moodColor = _moodColors[moodIdx.clamp(0, 4)];
    final moodIcon = _moodIcons[moodIdx.clamp(0, 4)];

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(entry),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(moodIcon, color: moodColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDisplayDate(entry.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isToday ? AppColors.primary : AppColors.onSurface,
                            ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(JournalModel entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Entri?'),
        content: Text('Hapus jurnal tanggal ${_formatDisplayDate(entry.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (entry.id != null) {
                await DatabaseHelper.instance.deleteJournalEntry(entry.id!);
                _loadData();
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
