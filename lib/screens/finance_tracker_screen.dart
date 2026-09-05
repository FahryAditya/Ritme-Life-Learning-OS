import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../services/gemini_service.dart';
import '../services/ritme_data_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/donut_chart_widget.dart';

class FinanceTrackerScreen extends StatefulWidget {
  const FinanceTrackerScreen({super.key});

  @override
  State<FinanceTrackerScreen> createState() => _FinanceTrackerScreenState();
}

class _FinanceTrackerScreenState extends State<FinanceTrackerScreen> {
  double _balance = 0.0;
  // ignore: unused_field
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  Map<String, double> _categoryExpenses = {};
  Map<String, dynamic>? _healthScoreData;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _filterType = 'Semua'; // 'Semua', 'Pengeluaran', 'Pemasukan'

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
    RitmeDataNotifier.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadFinanceData();
  }

  @override
  void dispose() {
    RitmeDataNotifier.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    final balance = await DatabaseHelper.instance.calculateTotalBalance();
    final list = await DatabaseHelper.instance.getTransactions();

    double income = 0.0;
    double expense = 0.0;
    final catMap = <String, double>{};

    for (var tx in list) {
      if (tx.isExpense) {
        expense += tx.amount;
        catMap[tx.category] = (catMap[tx.category] ?? 0.0) + tx.amount;
      } else {
        income += tx.amount;
      }
    }

    final health = await GeminiService.instance.calculateFinancialHealthScore(income, expense, balance);

    if (mounted) {
      setState(() {
        _balance = balance;
        _totalIncome = income;
        _totalExpense = expense;
        _categoryExpenses = catMap;
        _healthScoreData = health;
        _transactions = list;
        _isLoading = false;
      });
    }
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    String category = 'Umum';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Catat Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected: isExpense,
                          selectedColor: AppColors.errorContainer,
                          onSelected: (val) {
                            setDialogState(() => isExpense = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected: !isExpense,
                          selectedColor: AppColors.primaryFixed,
                          onSelected: (val) {
                            setDialogState(() => isExpense = false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      hintText: 'Misal: Kopi, Gaji, dll',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal (Rp)',
                      hintText: '50000',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
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
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (title.isEmpty || amount <= 0) return;

                    if (isExpense) {
                      final impulsiveCheck = await GeminiService.instance.analyzeImpulsivePurchase(title, amount, _balance);
                      if (impulsiveCheck['isImpulsive'] == true && ctx.mounted) {
                        final shouldProceed = await showDialog<bool>(
                          context: ctx,
                          builder: (warnCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Row(
                              children: [
                                Icon(Icons.shield_outlined, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Impulsive Buying Shield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            content: Text(
                              impulsiveCheck['warning'] as String,
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(warnCtx, false),
                                child: const Text('Tunda (Jeda 24 Jam)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(warnCtx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                child: const Text('Tetap Catat'),
                              ),
                            ],
                          ),
                        );
                        if (shouldProceed != true) return;
                      }
                    }

                    final tx = TransactionModel(
                      title: title,
                      amount: amount,
                      isExpense: isExpense,
                      category: category,
                      date: 'Hari ini',
                    );

                    await DatabaseHelper.instance.insertTransaction(tx);
                    RitmeDataNotifier.instance.notifyDataChanged();
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadFinanceData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Future<void> _deleteTransaction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus item transaksi ini dari database SQLite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteTransaction(id);
      RitmeDataNotifier.instance.notifyDataChanged();
      _loadFinanceData();
    }
  }

  void _showQuickAiEntryDialog() {
    final aiController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Input Cepat AI Bahasa Alami', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ketik atau ucapkan kalimat santai, AI akan otomatis mencatatnya:',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aiController,
                decoration: InputDecoration(
                  hintText: 'Misal: "Beli kopi 25rb" atau "Saldo awal 5jt"',
                  hintStyle: const TextStyle(fontSize: 12),
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
            ElevatedButton.icon(
              onPressed: () async {
                final text = aiController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);
                final res = await GeminiService.instance.sendMessage(text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.length > 80 ? '${res.substring(0, 80)}...' : res),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  _loadFinanceData();
                }
              },
              icon: const Icon(Icons.send, size: 16, color: Colors.white),
              label: const Text('Proses AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
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
        Positioned(
          top: -30,
          right: 20,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer.withValues(alpha: 0.12),
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
                        'Finance & Cashflow',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                      ),
                      Text(
                        'Penyimpanan database SQLite & kalkulasi otomatis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showQuickAiEntryDialog,
                        icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                        tooltip: 'Input Cepat AI Bahasa Alami',
                      ),
                      IconButton(
                        onPressed: _showAddTransactionDialog,
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                        tooltip: 'Catat Transaksi',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Total Balance Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF532EC7), Color(0xFF6C4CE0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL SALDO AKTIF (SQLITE)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatRupiah(_balance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.storage, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text(
                                'SQLite Live',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tersimpan aman di database lokal',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),

              // AI Financial Health Score Card
              if (_healthScoreData != null) ...[
                GlassCard(
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
                              Icon(Icons.health_and_safety, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Kesehatan Keuangan AI',
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
                              '${_healthScoreData!['score']} / 100 • ${_healthScoreData!['badge']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryFixed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ((_healthScoreData!['score'] as int) / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (_healthScoreData!['score'] as int) >= 75
                                ? Colors.green
                                : ((_healthScoreData!['score'] as int) >= 50 ? Colors.orange : Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _healthScoreData!['advice'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
              ],

              // Donut Chart — Pengeluaran per Kategori
              if (_categoryExpenses.isNotEmpty) ...[
                GlassCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.donut_large_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Distribusi Pengeluaran',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap irisan untuk detail kategori',
                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      DonutChartWidget(
                        categoryData: _categoryExpenses,
                        total: _totalExpense,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
              ],

              // Category Budget Limit Progress Meters
              GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batas Anggaran Kategori',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Batas 80% Warning',
                          style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...[
                      {'name': 'Makanan & Minuman', 'limit': 1500000.0, 'icon': Icons.fastfood_outlined},
                      {'name': 'Transportasi', 'limit': 600000.0, 'icon': Icons.directions_car_outlined},
                      {'name': 'Hiburan & Belanja', 'limit': 1000000.0, 'icon': Icons.shopping_bag_outlined},
                    ].map((cat) {
                      final spent = _categoryExpenses[cat['name']] ?? 0.0;
                      final limit = cat['limit'] as double;
                      final ratio = (spent / limit).clamp(0.0, 1.0);
                      final isOver80 = ratio >= 0.8;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(cat['icon'] as IconData, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat['name'] as String,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rp ${_formatRupiah(spent)} / Rp ${_formatRupiah(limit)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isOver80 ? FontWeight.bold : FontWeight.normal,
                                    color: isOver80 ? Colors.red : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ratio >= 1.0 ? Colors.red : (isOver80 ? Colors.orange : AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // Impulsive Spending Radar (AI Delight feature)
              GlassCard(
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
                            Icon(Icons.radar, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Radar Pengeluaran Impulsif',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'AI Aktif',
                            style: TextStyle(
                              color: AppColors.onPrimaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _transactions.isEmpty
                          ? 'Belum ada data transaksi. Radar Gemini akan otomatis aktif memantau pola belanja tidak terjadwal begitu transaksi dicatat.'
                          : 'Gemini memantau pola belanja tidak terjadwal. Pengeluaran terkontrol rapi dengan SQLite!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _transactions.isEmpty ? 0.0 : 0.15,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 20),

              // Filter Chips
              Row(
                children: ['Semua', 'Pengeluaran', 'Pemasukan'].map((filter) {
                  final isSelected = _filterType == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _filterType = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Recent Transactions from SQLite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Transaksi SQLite',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${_filteredTransactions.length} Item',
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_filteredTransactions.isEmpty)
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum Ada Transaksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mulai catat pemasukan dan pengeluaran harianmu dengan aman di database lokal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddTransactionDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Catat Transaksi Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredTransactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTransactionItem(
                      id: tx.id,
                      title: tx.title,
                      date: tx.date,
                      amount: '${tx.isExpense ? '-' : '+'}Rp ${_formatRupiah(tx.amount)}',
                      isExpense: tx.isExpense,
                      icon: tx.isExpense ? Icons.coffee : Icons.payments,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  List<TransactionModel> get _filteredTransactions {
    if (_filterType == 'Pengeluaran') {
      return _transactions.where((t) => t.isExpense).toList();
    } else if (_filterType == 'Pemasukan') {
      return _transactions.where((t) => !t.isExpense).toList();
    }
    return _transactions;
  }

  Widget _buildTransactionItem({
    int? id,
    required String title,
    required String date,
    required String amount,
    required bool isExpense,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isExpense ? AppColors.errorContainer : AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isExpense ? AppColors.error : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isExpense ? AppColors.error : Colors.green[700],
            ),
          ),
          if (id != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.outline),
              onPressed: () => _deleteTransaction(id),
              tooltip: 'Hapus Transaksi',
            ),
          ],
        ],
      ),
    );
  }
}
