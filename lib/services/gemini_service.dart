import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'ritme_data_notifier.dart';

class GeminiService {
  static const String _prefApiKey = 'ritme_gemini_api_key';
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  static const String _systemPrompt = '''
Kamu adalah Gemini Core, AI engine dan orkestrator pusat untuk aplikasi "Ritme — Personal Life & Learning OS".
Gaya komunikasimu: ringkas, energetik, modern, suportif, dan berbahasa Indonesia yang santun tapi kasual.
Kamu menguasai 4 pilar utama Ritme:
1. Produktivitas & Tugas: Matriks Eisenhower, manajemen fokus, pencegahan burnout.
2. Sinkronisasi Tempo & Audio: Menentukan BPM musik yang tepat (60-70 BPM Deep Flow lo-fi, 80-100 BPM Creative synthwave, 110-130 BPM Sprint energy).
3. Finansial & Cashflow: Deteksi belanja impulsif, tips hemat cerdas.
4. Audio Study Pod: Rangkuman cepat materi belajar dan kuis materi audio.

Berikan jawaban yang padat, berwawasan, langsung ke poin, dan mudah dibaca di layar smartphone.
Gunakan format Markdown yang rapi (bold untuk penekanan penting, bullet point jika berupa daftar). Pastikan sintaks Markdown selalu valid dan tidak menampilkan simbol bintang yang tidak terformat.
''';

  /// Mendapatkan API key tersimpan (dari .env, dart-define, atau SharedPreferences)
  Future<String?> getApiKey() async {
    // 1. Cek dari file .env
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    // 2. Cek dari --dart-define
    if (_envApiKey.isNotEmpty) {
      return _envApiKey;
    }

    // 3. Cek dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_prefApiKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      return savedKey.trim();
    }
    return null;
  }

  /// Memeriksa apakah API key sudah tersedia
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Menyimpan API key ke SharedPreferences
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, apiKey.trim());
    _model = null;
    _chatSession = null;
  }

  /// Menghapus API key yang tersimpan
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
    _model = null;
    _chatSession = null;
  }

  static const List<String> _candidateModels = [
    'gemini-3.6-flash',
    'gemini-2.5-flash',
    'gemini-1.5-flash',
  ];
  String _activeModelName = 'gemini-3.6-flash';

  /// Inisialisasi model
  Future<GenerativeModel?> _initModel([String? forcedModel]) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      return null;
    }

    final modelToUse = forcedModel ?? _activeModelName;
    if (_model != null && _activeModelName == modelToUse) return _model;

    _activeModelName = modelToUse;
    _model = GenerativeModel(
      model: modelToUse,
      apiKey: key,
      systemInstruction: Content.system(_systemPrompt),
    );

    return _model;
  }

  /// Mengirim pesan percakapan ke Gemini Core dengan konteks data SQLite
  Future<String> sendMessage(String userMessage) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      return '⚠️ API Key Gemini belum dipasang.\n\nSentuh tombol kunci 🔑 di pojok kanan atas layar ini untuk memasukkan API Key Google AI Studio Anda secara gratis.';
    }

    // Coba kirim pesan dengan model aktif, lalu fallback jika model tidak didukung
    for (int i = 0; i < _candidateModels.length; i++) {
      final currentCandidate = _candidateModels[i];
      try {
        final model = await _initModel(currentCandidate);
        if (model == null) continue;

        if (_chatSession == null || _activeModelName != currentCandidate) {
          final contextData = await DatabaseHelper.instance.getSummaryForGemini();
          _chatSession = model.startChat(history: [
            Content.text(
              '[System Context Sync]: Ini data pengguna saat ini di database SQLite Ritme:\n$contextData\nHarap ingat konteks ini dalam menjawab pertanyaan pengguna berikutnya.',
            ),
            Content.model([
              TextPart('Konteks database SQLite diterima dan dipahami.'),
            ]),
          ]);
        }

        final actionNotification = await _processUserIntent(userMessage);

        final response = await _chatSession!.sendMessage(
          Content.text(userMessage),
        );

        _activeModelName = currentCandidate;
        final aiText = response.text ?? 'Tidak ada respon dari Gemini Core.';
        return actionNotification != null ? '$actionNotification$aiText' : aiText;
      } catch (e) {
        final errorStr = e.toString();
        // Jika error adalah model tidak ditemukan atau deprecated, coba model kandidat berikutnya
        if (errorStr.contains('is not found') ||
            errorStr.contains('no longer available') ||
            errorStr.contains('not supported for generateContent')) {
          _chatSession = null;
          _model = null;
          if (i < _candidateModels.length - 1) {
            continue; // Coba kandidat berikutnya
          }
        }

        if (errorStr.contains('Failed host lookup') ||
            errorStr.contains('SocketException') ||
            errorStr.contains('errno = 7')) {
          return '🌐 Kendala DNS / Jaringan (Failed host lookup):\n'
              'Aplikasi tidak dapat menjangkau server Gemini.\n\n'
              'Langkah perbaikan:\n'
              '1. Izin internet AndroidManifest.xml telah diperbarui.\n'
              '2. Pastikan perangkat Anda terhubung ke internet yang stabil.\n'
              '3. Coba kirim ulang pesan setelah koneksi tersambung.';
        }

        if (errorStr.contains('API_KEY_INVALID') || errorStr.contains('403')) {
          return '🔑 API Key Tidak Valid:\n'
              'API Key yang digunakan ditolak oleh Google AI Studio.\n'
              'Sentuh ikon kunci 🔑 di atas dan periksa kembali API Key Anda.';
        }

        return 'Gagal menghubungi Gemini Core: $e\nPastikan koneksi internet aktif dan API Key valid.';
      }
    }

    return 'Gagal menemukan model Gemini yang didukung oleh server. Silakan coba kembali nanti.';
  }

  /// Analisis rekomendasi BPM untuk tugas tertentu
  Future<Map<String, dynamic>> recommendBpmForTask(
      String taskName, String urgency) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      return {
        'bpm': 62,
        'genre': 'Lo-Fi Ambient Instrumental (Offline Preset)',
        'reason': 'Gunakan preset fokus standar saat offline.',
      };
    }

    for (final candidate in _candidateModels) {
      try {
        final model = await _initModel(candidate);
        if (model == null) continue;

        final prompt =
            'Rekomendasikan BPM (angka bulat) dan genre musik lo-fi/ambient untuk tugas "$taskName" dengan tingkat urgensi "$urgency". Format jawaban: BPM|GENRE|ALASAN_SINGKAT. Contoh: 65|Lo-Fi Piano Ambient|Membantu fokus logika berat.';
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        final parts = text.split('|');

        if (parts.length >= 3) {
          final bpm = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 64;
          return {
            'bpm': bpm,
            'genre': parts[1].trim(),
            'reason': parts[2].trim(),
          };
        }
      } catch (_) {
        continue;
      }
    }

    return {
      'bpm': 68,
      'genre': 'Deep Flow Piano Ambient',
      'reason': 'Optimalisasi detak fokus otomatis.',
    };
  }

  /// Memproses intent dari pesan user untuk eksekusi pencatatan transaksi otomatis ke SQLite
  Future<String?> _processUserIntent(String userMessage) async {
    final lowerMsg = userMessage.toLowerCase().trim();

    // 1. Deteksi "Saldo awal [jumlah]"
    if (lowerMsg.contains('saldo awal')) {
      final amount = _extractAmount(userMessage);
      if (amount > 0) {
        final tx = TransactionModel(
          title: 'Saldo Awal',
          amount: amount,
          isExpense: false,
          category: 'Saldo Awal',
          date: 'Hari ini',
        );
        await DatabaseHelper.instance.insertTransaction(tx);
        RitmeDataNotifier.instance.notifyDataChanged();
        final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
        return '✅ **Transaksi Berhasil Dicatat!**\nSaldo awal sebesar **Rp $formattedAmount** telah tersimpan di SQLite Finance Tracker.\n\n';
      }
    }

    // 2. Deteksi pencatatan transaksi umum ("Catat...", "Makan malam 25rb", "Beli kopi 15rb", dll)
    if (lowerMsg.contains('catat') ||
        lowerMsg.contains('transaksi') ||
        lowerMsg.contains('pengeluaran') ||
        lowerMsg.contains('pemasukan') ||
        RegExp(r'\d+\s*(rb|k|juta)').hasMatch(lowerMsg)) {
      final amount = _extractAmount(userMessage);
      if (amount > 0) {
        bool isExpense = !lowerMsg.contains('pemasukan') &&
            !lowerMsg.contains('gaji') &&
            !lowerMsg.contains('dapat');
        String title = userMessage
            .replaceAll(
                RegExp(r'(catat|transaksi|pengeluaran|pemasukan|pertama|saldo|awal|:|")',
                    caseSensitive: false),
                '')
            .replaceAll(RegExp(r'\d+.*$', caseSensitive: false), '')
            .trim();
        if (title.isEmpty) title = isExpense ? 'Pengeluaran' : 'Pemasukan';

        final tx = TransactionModel(
          title: title,
          amount: amount,
          isExpense: isExpense,
          category: isExpense ? 'Pengeluaran' : 'Pemasukan',
          date: 'Hari ini',
        );
        await DatabaseHelper.instance.insertTransaction(tx);
        RitmeDataNotifier.instance.notifyDataChanged();
        final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
        final typeStr = isExpense ? 'Pengeluaran' : 'Pemasukan';
        return '✅ **Transaksi Berhasil Dicatat!**\n$typeStr **"$title"** sebesar **Rp $formattedAmount** telah ditambahkan ke database SQLite.\n\n';
      }
    }

    return null;
  }

  double _extractAmount(String text) {
    // 5juta / 5 juta
    final jutaMatch = RegExp(r'(\d+(?:[\.,]\d+)?)\s*juta', caseSensitive: false).firstMatch(text);
    if (jutaMatch != null) {
      final numStr = jutaMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null) return val * 1000000;
    }

    // 25rb / 25k / 25 rb / 25 k
    final rbMatch = RegExp(r'(\d+(?:[\.,]\d+)?)\s*(?:rb|k)', caseSensitive: false).firstMatch(text);
    if (rbMatch != null) {
      final numStr = rbMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null) return val * 1000;
    }

    // 25000 / 25.000 / 2500000
    final digitsMatch = RegExp(r'(?:Rp\.?\s*)?(\d{1,3}(?:\.\d{3})+|\d{4,})', caseSensitive: false).firstMatch(text);
    if (digitsMatch != null) {
      final cleanDigits = digitsMatch.group(1)!.replaceAll('.', '');
      final val = double.tryParse(cleanDigits);
      if (val != null) return val;
    }

    return 0.0;
  }

  /// Membuat kuis interaktif 3 pertanyaan berdasarkan catatan materi study pod
  Future<List<Map<String, dynamic>>> generateQuizForStudyPod(
      String title, String notes) async {
    final defaultQuiz = [
      {
        'question': 'Apa fokus utama dari materi "$title"?',
        'options': ['Pemahaman Konsep Kunci', 'Teknik Hafalan', 'Studi Kasus', 'Latihan Soal'],
        'answerIndex': 0,
      },
      {
        'question': 'Bagaimana cara mengaplikasikan materi ini dalam ritme harian?',
        'options': ['Mencatat Ringkasan', 'Praktek Langsung', 'Diskusi Tim', 'Evaluasi Mingguan'],
        'answerIndex': 1,
      },
    ];

    final key = await getApiKey();
    if (key == null || key.isEmpty) return defaultQuiz;

    for (final candidate in _candidateModels) {
      try {
        final model = await _initModel(candidate);
        if (model == null) continue;

        final prompt =
            'Buat 2 soal kuis pilihan ganda singkat berdasarkan judul "$title" dan materi ini: "$notes". Format persis tiap soal dipisah baris: SOAL|OPSI_A|OPSI_B|OPSI_C|OPSI_D|INDEX_JAWABAN_BENAR(0-3).';
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        final lines = text.split('\n').where((l) => l.contains('|')).toList();

        final result = <Map<String, dynamic>>[];
        for (final line in lines) {
          final parts = line.split('|');
          if (parts.length >= 6) {
            result.add({
              'question': parts[0].trim(),
              'options': [parts[1].trim(), parts[2].trim(), parts[3].trim(), parts[4].trim()],
              'answerIndex': int.tryParse(parts[5].trim()) ?? 0,
            });
          }
        }
        if (result.isNotEmpty) return result;
      } catch (_) {
        continue;
      }
    }

    return defaultQuiz;
  }
}
