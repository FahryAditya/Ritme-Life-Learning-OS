import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/study_pod_model.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class VoiceToTextScreen extends StatefulWidget {
  const VoiceToTextScreen({super.key});

  @override
  State<VoiceToTextScreen> createState() => _VoiceToTextScreenState();
}

class _VoiceToTextScreenState extends State<VoiceToTextScreen> {
  bool _isListening = false;
  int _recordingSeconds = 0;
  Timer? _timer;

  final TextEditingController _speechTextController = TextEditingController();
  List<StudyPodModel> _savedNotes = [];
  bool _isLoading = true;

  // Sample dictation presets to test instantly
  final List<String> _quickPresets = [
    'Rapat hari ini membahas tentang strategi manajemen waktu, pembagian tugas sprint mingguan, dan evaluasi pengeluaran tim.',
    'Sistem operasi menggunakan konsep manajemen memori virtual dengan teknik paging dan segmentation untuk optimasi RAM.',
    'Target keuangan bulan ini adalah menabung 20 persen dari gaji awal dan mengurangi pengeluaran konsumtif di kafe.',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedNotes();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadSavedNotes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechTextController.dispose();
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadSavedNotes() async {
    final notes = await DatabaseHelper.instance.getStudyPods();
    if (mounted) {
      setState(() {
        _savedNotes = notes;
        _isLoading = false;
      });
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _recordingSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isListening) {
        setState(() {
          _recordingSeconds++;
          // Simulate dynamic speech recognition accretion
          if (_recordingSeconds == 2 && _speechTextController.text.isEmpty) {
            _speechTextController.text = 'Merekam ucapan... ';
          } else if (_recordingSeconds == 4 && _speechTextController.text == 'Merekam ucapan... ') {
            _speechTextController.text =
                'Merekam ucapan suara pengguna tentang rencana proyek dan materi belajar...';
          }
        });
      }
    });
  }

  void _stopListening() {
    _timer?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _processVoiceWithAi() async {
    final rawText = _speechTextController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan rekam suara atau ketik teks ucapan terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _stopListening();

    // Show loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Gemini AI sedang merapikan teks ucapan\ndan mengekstrak poin penting...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final aiResult = await GeminiService.instance.refineVoiceTranscription(rawText);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    final title = aiResult['title'] ?? 'Catatan Suara AI';
    final cleanText = aiResult['cleanText'] ?? rawText;
    final aiNotes = aiResult['aiNotes'] ?? 'Poin utama tercatat.';

    final newPod = StudyPodModel(
      title: title,
      subtitle: 'Transkripsi Suara • ${_formatDuration(_recordingSeconds > 0 ? _recordingSeconds : 15)}',
      durationSeconds: _recordingSeconds > 0 ? _recordingSeconds : 15,
      audioUrl: cleanText,
      aiNotes: aiNotes,
      isActive: true,
    );

    await DatabaseHelper.instance.insertStudyPod(newPod);
    RitmeDataNotifier.instance.notifyDataChanged();

    _speechTextController.clear();
    setState(() {
      _recordingSeconds = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teks ucapan berhasil diproses & disimpan oleh AI!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _showAiQuizDialog(StudyPodModel note) async {
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
                Text('Membuat Kuis AI dari Teks Transkripsi...'),
              ],
            ),
          ),
        ),
      ),
    );

    final questions = await GeminiService.instance.generateQuizForStudyPod(
      note.title,
      'Teks: ${note.audioUrl}\n\nCatatan: ${note.aiNotes}',
    );
    if (!mounted) return;
    Navigator.pop(context);

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
                      'Kuis AI: ${note.title}',
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
                    'Pertanyaan ${currentQuestion + 1} dari ${questions.length}',
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
                  child: const Text('Tutup'),
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

    return Stack(
      children: [
        // Background Decorative Glow
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Voice To Text AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
              ),
              Text(
                'Konversi ucapan suara menjadi teks terstruktur & poin penting AI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),

              // Dictation & Voice Recording Glass Card
              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.red.shade100
                                : AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isListening ? Icons.fiber_manual_record : Icons.auto_awesome,
                                size: 12,
                                color: _isListening ? Colors.red : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isListening ? 'Merekam Suara...' : 'Dikte Suara AI',
                                style: TextStyle(
                                  color: _isListening ? Colors.red.shade900 : AppColors.onPrimaryFixed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDuration(_recordingSeconds),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isListening ? Colors.red : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Big Animated Record Button & Sound Wave Visualizer
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isListening
                              ? const LinearGradient(colors: [Colors.redAccent, Colors.deepOrange])
                              : AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.red : AppColors.primary).withValues(alpha: 0.4),
                              blurRadius: _isListening ? 24 : 12,
                              spreadRadius: _isListening ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ).animate(target: _isListening ? 1 : 0).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 12),

                    Text(
                      _isListening ? 'Ketuk untuk Berhenti Merekam' : 'Ketuk Mikrofon untuk Mulai Dikte Suara',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isListening ? Colors.red : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Soundwave animation effect when recording
                    if (_isListening) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (idx) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 5,
                            height: 12.0 + (idx % 3 * 10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                                begin: 0.5,
                                end: 1.8,
                                duration: Duration(milliseconds: 300 + (idx * 80)),
                              );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Text Field Dictation Preview & Editable Box
                    TextField(
                      controller: _speechTextController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Teks ucapan Anda akan muncul di sini... (Atau ketik ucapan langsung)',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preset Quick Dictations Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickPresets.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                              label: Text(
                                preset.length > 25 ? '${preset.substring(0, 25)}...' : preset,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                setState(() {
                                  _speechTextController.text = preset;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Process with AI Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _processVoiceWithAi,
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        label: const Text(
                          'Proses Dikte dengan AI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 24),

              // Saved Voice Transcriptions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hasil Transkripsi Suara AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${_savedNotes.length} Catatan',
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_savedNotes.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.mic_off_outlined, size: 40, color: AppColors.onSurfaceVariant),
                      SizedBox(height: 8),
                      Text(
                        'Belum Ada Transkripsi Suara',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rekam ucapan Anda atau pilih preset di atas untuk mulai membuat catatan AI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._savedNotes.map((note) => _buildSavedNoteCard(note)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedNoteCard(StudyPodModel note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryFixed),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.subtitle,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Clean transcription text snippet
          if (note.audioUrl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.audioUrl,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // AI Notes & Summary markdown box
          if (note.aiNotes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: MarkdownBody(
                data: note.aiNotes,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                  h3: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  listBullet: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Row
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAiQuizDialog(note),
                icon: const Icon(Icons.quiz, size: 14),
                label: const Text('Kuis AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _showFlashcardsDialog(note),
                icon: const Icon(Icons.style, size: 14),
                label: const Text('Flashcard AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${note.title}\n\n${note.audioUrl}\n\n${note.aiNotes}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks transkripsi disalin ke clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Salin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  if (note.id != null) {
                    await DatabaseHelper.instance.deleteStudyPod(note.id!);
                    RitmeDataNotifier.instance.notifyDataChanged();
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Hapus Transkripsi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showFlashcardsDialog(StudyPodModel note) async {
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
                Text('Membuat Flashcard AI dari Catatan...'),
              ],
            ),
          ),
        ),
      ),
    );

    final cards = await GeminiService.instance.generateFlashcardsFromText(
      'Teks: ${note.audioUrl}\n\nCatatan: ${note.aiNotes}',
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    int currentIdx = 0;
    bool showAnswer = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setCardState) {
            final card = cards[currentIdx];
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.style, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flashcard AI (${currentIdx + 1}/${cards.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setCardState(() => showAnswer = !showAnswer),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 140),
                      decoration: BoxDecoration(
                        color: showAnswer ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: showAnswer ? AppColors.primary : AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showAnswer ? 'JAWABAN / BELAKANG' : 'PERTANYAAN / DEPAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: showAnswer ? AppColors.primary : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            showAnswer ? card['back']! : card['front']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            showAnswer ? 'Ketuk untuk kembali ke pertanyaan' : 'Ketuk kartu untuk melihat jawaban',
                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (currentIdx > 0)
                  TextButton(
                    onPressed: () => setCardState(() {
                      currentIdx--;
                      showAnswer = false;
                    }),
                    child: const Text('Sebelumnya'),
                  ),
                if (currentIdx < cards.length - 1)
                  ElevatedButton(
                    onPressed: () => setCardState(() {
                      currentIdx++;
                      showAnswer = false;
                    }),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('Berikutnya'),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Selesai'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
