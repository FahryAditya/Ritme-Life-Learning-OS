import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/study_pod_model.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AudioStudyPodScreen extends StatefulWidget {
  const AudioStudyPodScreen({super.key});

  @override
  State<AudioStudyPodScreen> createState() => _AudioStudyPodScreenState();
}

class _AudioStudyPodScreenState extends State<AudioStudyPodScreen> {
  bool _isPlaying = true;
  StudyPodModel? _activePod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPodData();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadPodData();
  }

  @override
  void dispose() {
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadPodData() async {
    final active = await DatabaseHelper.instance.getActiveStudyPod();
    final allPods = await DatabaseHelper.instance.getStudyPods();

    if (mounted) {
      setState(() {
        _activePod = active ?? (allPods.isNotEmpty ? allPods.first : null);
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showAddPodDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.library_music, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Tambah Pod Belajar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Pod',
                  hintText: 'Misal: Sistem Operasi & Logika',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(
                  labelText: 'Kategori / Subjudul',
                  hintText: 'Misal: Bab 3 - Manajemen Memori',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan Rangkuman AI',
                  hintText: 'Ringkasan poin penting materi...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final subtitle = subtitleController.text.trim();
                final notes = notesController.text.trim();
                if (title.isEmpty) return;

                final newPod = StudyPodModel(
                  title: title,
                  subtitle: subtitle.isNotEmpty ? subtitle : 'Materi Belajar',
                  durationSeconds: 1200,
                  aiNotes: notes.isNotEmpty ? notes : 'Rangkuman materi siap dipelajari.',
                  isActive: true,
                );

                await DatabaseHelper.instance.insertStudyPod(newPod);
                RitmeDataNotifier.instance.notifyDataChanged();
                if (ctx.mounted) Navigator.pop(ctx);
                _loadPodData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Simpan Pod'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAiQuizDialog(StudyPodModel pod) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text('Membuat Kuis AI dari Catatan Pod...'),
              ],
            ),
          ),
        ),
      ),
    );

    final questions = await GeminiService.instance.generateQuizForStudyPod(pod.title, pod.aiNotes);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    int currentQuestion = 0;
    int score = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setQuizState) {
            final q = questions[currentQuestion];
            final opts = q['options'] as List<String>;
            final correctIdx = q['answerIndex'] as int;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.quiz, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kuis AI: ${pod.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soal ${currentQuestion + 1} dari ${questions.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(opts.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: () {
                          if (index == correctIdx) score++;
                          if (currentQuestion < questions.length - 1) {
                            setQuizState(() => currentQuestion++);
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kuis Selesai! Skor Anda: $score / ${questions.length}'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('${String.fromCharCode(65 + index)}. ${opts[index]}'),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
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

    final pod = _activePod;
    final totalDuration = pod?.durationSeconds ?? 1695;
    final currentProgress = (pod?.progressSeconds ?? 760).clamp(0, totalDuration);
    final progressFraction = (currentProgress / totalDuration).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Study Pod',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                      ),
                      Text(
                        'Materi audio & ringkasan inti tersimpan di SQLite',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _showAddPodDialog,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                    tooltip: 'Tambah Pod Belajar',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Active Audio Study Player Card
              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
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
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sesi Belajar Aktif',
                            style: TextStyle(
                              color: AppColors.onPrimaryFixed,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.headset, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Spatial 3D Audio',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      pod?.title ?? 'Belum Ada Materi Audio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pod?.subtitle ?? 'Tambahkan materi audio atau rangkuman studi pertama Anda.',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),

                    if (pod != null) ...[
                      // Playback slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 4,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceContainerHigh,
                          thumbColor: AppColors.primary,
                        ),
                        child: Slider(
                          value: progressFraction,
                          onChanged: (val) async {
                            if (pod.id == null) return;
                            final newSeconds = (val * totalDuration).round();
                            setState(() {
                              _activePod = pod.copyWith(progressSeconds: newSeconds);
                            });
                            await DatabaseHelper.instance.updateStudyPodProgress(
                              pod.id!,
                              newSeconds,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(currentProgress),
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            Text(_formatDuration(totalDuration),
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.replay_10),
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isPlaying = !_isPlaying);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.forward_30),
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Koleksi Study Pod SQLite masih kosong.\nKoleksi materi audio baru akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 20),

              // AI Live Generated Key Insights
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catatan Inti AI dari Database SQLite',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (pod != null)
                    ElevatedButton.icon(
                      onPressed: () => _showAiQuizDialog(pod),
                      icon: const Icon(Icons.quiz, size: 16),
                      label: const Text('Kuis AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (pod != null && pod.aiNotes.isNotEmpty)
                ...pod.aiNotes.split('\n\n').map((note) {
                  final lines = note.split('\n');
                  final title = lines.first;
                  final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInsightCard(title, body),
                  );
                })
              else
                _buildInsightCard(
                  'Belum Ada Catatan Inti AI',
                  'Gemini akan otomatis merangkum poin penting begitu materi audio baru ditambahkan.',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryFixed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
