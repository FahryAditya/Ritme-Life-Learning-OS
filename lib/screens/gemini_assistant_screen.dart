import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';

class GeminiAssistantScreen extends StatefulWidget {
  const GeminiAssistantScreen({super.key});

  @override
  State<GeminiAssistantScreen> createState() => _GeminiAssistantScreenState();
}

class _GeminiAssistantScreenState extends State<GeminiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasApiKey = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          'Halo! Saya Gemini Core, orkestrator hidup dan belajarmu di Ritme. Semua data tugas, ritme audio, dan keuanganmu telah tersinkronisasi.',
      'hasCard': true,
    },
  ];

  final List<String> _suggestedPrompts = [
    '✨ Ringkas hariku',
    '💸 Cek radar pengeluaran impulsif',
    '🎵 Sesuaikan tempo tugas berikutnya',
    '📚 Kuis materi audio pod',
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _checkApiKey();
    _loadChatHistory();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadChatHistory() async {
    final history = await DatabaseHelper.instance.getChatMessages();
    if (!mounted) return;

    if (history.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(history);
      });
    } else {
      // Simpan pesan sambutan awal ke SQLite
      final welcomeMsg = _messages.first;
      await DatabaseHelper.instance.insertChatMessage(
        isUser: welcomeMsg['isUser'] as bool,
        text: welcomeMsg['text'] as String,
        hasCard: welcomeMsg['hasCard'] as bool,
      );
    }
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiService.instance.hasApiKey();
    if (mounted) {
      setState(() => _hasApiKey = hasKey);
    }
  }

  @override
  void dispose() {
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    _orbController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'hasCard': false,
      });
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();
    await DatabaseHelper.instance.insertChatMessage(
      isUser: true,
      text: text,
      hasCard: false,
    );

    try {
      final responseText = await GeminiService.instance.sendMessage(text);
      if (!mounted) return;

      setState(() {
        _messages.add({
          'isUser': false,
          'text': responseText,
          'hasCard': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
      await DatabaseHelper.instance.insertChatMessage(
        isUser: false,
        text: responseText,
        hasCard: false,
      );
    } catch (e) {
      if (!mounted) return;
      final errStr = 'Terjadi kesalahan: $e';
      setState(() {
        _messages.add({
          'isUser': false,
          'text': errStr,
          'hasCard': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
      await DatabaseHelper.instance.insertChatMessage(
        isUser: false,
        text: errStr,
        hasCard: false,
      );
    }
  }

  void _showApiKeyDialog() async {
    final currentKey = await GeminiService.instance.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.key, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Gemini API Key',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dapatkan API Key gratis di aistudio.google.com dan tempelkan di bawah ini:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await GeminiService.instance.clearApiKey();
                  if (ctx.mounted) Navigator.pop(ctx);
                  _checkApiKey();
                },
                child: const Text('Hapus Key',
                    style: TextStyle(color: AppColors.error)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  await GeminiService.instance.saveApiKey(key);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _checkApiKey();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ambient background glow
        Positioned(
          top: -30,
          left: 50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withOpacity(0.12),
            ),
          ),
        ),

        Column(
          children: [
            // Top Header & Pulsing Orb with API Key configuration button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gemini AI Core',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _showApiKeyDialog,
                        icon: Icon(
                          _hasApiKey ? Icons.vpn_key : Icons.vpn_key_outlined,
                          color: _hasApiKey
                              ? AppColors.primary
                              : AppColors.outline,
                          size: 20,
                        ),
                        tooltip: 'Pengaturan API Key',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Animated Glowing AI Orb
                  AnimatedBuilder(
                    animation: _orbController,
                    builder: (context, child) {
                      final scale = 1.0 + (_orbController.value * 0.1);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.aiOrbGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withOpacity(
                                    0.35 + 0.3 * _orbController.value),
                                blurRadius: 24,
                                spreadRadius: 4 * _orbController.value,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // API key status banner if not configured yet
            if (!_hasApiKey)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.onPrimaryFixed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'API Key belum diisi. Sentuh ikon kunci 🔑 untuk aktivasi.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onPrimaryFixed,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showApiKeyDialog,
                      child: const Text('Isi Key',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          )),
                    ),
                  ],
                ),
              ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final hasCard = msg['hasCard'] as bool;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUser)
                            Text(
                              msg['text'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            )
                          else
                            MarkdownBody(
                              data: msg['text'] as String,
                              shrinkWrap: true,
                              selectable: false,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                                strong: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.45,
                                ),
                                em: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                                h1: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                h2: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                h3: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                listBullet: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                                code: TextStyle(
                                  color: AppColors.primary,
                                  backgroundColor:
                                      AppColors.primaryFixed.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                                  ),
                                ),
                                blockquoteDecoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: const Border(
                                    left: BorderSide(
                                      color: AppColors.primary,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (hasCard) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primaryFixed,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.insights,
                                          size: 16, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        'Rangkuman Harmonisasi',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '• 1 Tugas Deep Work (Beban Kognitif 88%)\n• Rekomendasi Tempo: 62 BPM Lo-Fi Ambient\n• Sisa Anggaran Harian: Aman (+18%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Loading indicator while waiting for Gemini
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemini Core sedang menganalisis...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

            // Suggested prompt chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      onPressed: () => _sendMessage(prompt),
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                          color: AppColors.primaryFixed,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (val) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Tanya Gemini Core apa saja...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
