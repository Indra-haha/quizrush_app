import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../models/points.dart';
import '../../services/api/api_client.dart';
import '../../services/api/points_service.dart';
import '../../services/points_store.dart';
import '../../services/session_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/status_filter.dart';

/// Halaman tab "Reward" dengan dua bagian yang bisa digeser: Reward dan Saldo.
class RewardPage extends StatefulWidget {
  /// Apakah tab ini sedang aktif/dibuka. Data dimuat saat halaman dibuka,
  /// bukan saat dibuat di dalam `IndexedStack`.
  final bool isActive;

  /// Service yang dapat di-inject pada pengujian.
  final PointsService? service;

  const RewardPage({super.key, this.isActive = true, this.service});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  static const List<String> _tabs = ['Reward', 'Saldo'];
  static const int _koinToRupiah = 10;
  static const List<String> _historyFilters = ['Semua', 'Hadiah', 'Tarik'];

  static const Map<String, ({String symbol, double rate})> _currencies = {
    'IDR': (symbol: 'Rp', rate: 1),
    'USD': (symbol: r'US$', rate: 16000),
    'MYR': (symbol: 'RM', rate: 3400),
    'SGD': (symbol: r'S$', rate: 12000),
  };

  final PageController _pageController = PageController();
  final TextEditingController _amountController = TextEditingController(
    text: '10000',
  );

  late String _selectedTab = _tabs.first;
  String _currency = 'IDR';
  String _historyFilter = 'Semua';

  PointsService get _service => widget.service ?? PointsService.instance;

  int? _points;
  List<CoinEntry> _coins = const [];
  bool _loading = true;
  String? _error;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _points = PointsStore.instance.points;
    _amountController.addListener(_onAmountChanged);
    if (widget.isActive) _onOpened();
  }

  @override
  void didUpdateWidget(covariant RewardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _onOpened();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  void _onOpened() {
    if (_opened) return;
    _opened = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sesi tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    try {
      final points = await _service.fetchPoints(token: token);
      final coins = await _service.fetchCoins(token: token);
      if (!mounted) return;
      PointsStore.instance.set(points);
      setState(() {
        _points = points;
        _coins = coins;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tidak bisa memuat saldo.';
      });
    }
  }

  int get _amount {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  String get _conversionLabel {
    final currency = _currencies[_currency] ?? _currencies['IDR']!;
    final idr = _amount * _koinToRupiah;
    if (_currency == 'IDR') return formatRupiah(idr);
    final value = idr / currency.rate;
    return '${currency.symbol} ${value.toStringAsFixed(2)}';
  }

  List<CoinEntry> get _filteredCoins {
    switch (_historyFilter) {
      case 'Hadiah':
        return _coins.where((c) => c.reason == 'quiz_reward').toList();
      case 'Tarik':
        return _coins.where((c) => c.amount < 0).toList();
      default:
        return _coins;
    }
  }

  void _selectTab(String tab) {
    final index = _tabs.indexOf(tab);
    if (index < 0) return;
    if (!_pageController.hasClients) {
      setState(() => _selectedTab = tab);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final tab = _tabs[index];
    if (tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
  }

  void _notAvailable(String label) {
    AppSnackBar.show(context, '$label belum tersedia saat ini.');
  }

  void _setAmount(int value) {
    _amountController.text = '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatusFilter<String>(
              values: _tabs,
              selected: _selectedTab,
              onChanged: _selectTab,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [_buildRewardTab(), _buildSaldoTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada konten reward.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSaldoTab() {
    if (_loading && _points == null && _coins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _points == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildConversionCard(),
          const SizedBox(height: 16),
          _buildHistoryCard(),
          const SizedBox(height: 300),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final value = _points ?? 0;
    return Card(
      child: ListTile(
        title: const Text('Saldo Koin'),
        subtitle: Text('≈ ${formatRupiah(value * _koinToRupiah)}'),
        trailing: Text(
          '${formatPoints(value)} KOIN',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildConversionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Konversi Koin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah koin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final amount in const [1000, 5000, 10000]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setAmount(amount),
                      child: Text(formatPoints(amount)),
                    ),
                  ),
                  if (amount != 10000) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currencies.containsKey(_currency)
                  ? _currency
                  : _currencies.keys.first,
              decoration: const InputDecoration(
                labelText: 'Mata uang',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final code in _currencies.keys)
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (value) {
                if (value == null || !_currencies.containsKey(value)) return;
                setState(() => _currency = value);
              },
            ),
            const SizedBox(height: 12),
            Text('Hasil: $_conversionLabel'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _notAvailable('Cairkan saldo'),
              child: const Text('Cairkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    final coins = _filteredCoins;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Riwayat Transaksi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final filter in _historyFilters)
                  ChoiceChip(
                    label: Text(filter),
                    selected: filter == _historyFilter,
                    onSelected: (_) =>
                        setState(() => _historyFilter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (coins.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada transaksi koin.',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              for (final coin in coins) _buildTransactionTile(coin),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(CoinEntry coin) {
    final positive = coin.amount >= 0;
    final sign = positive ? '+' : '-';
    final time = relativeTime(coin.createdAt);
    final subtitle = coin.roomKode.isEmpty
        ? '${coin.reasonLabel} • $time'
        : 'Room ${formatKode(coin.roomKode)} • $time';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        coin.reason == 'quiz_reward'
            ? Icons.emoji_events_rounded
            : Icons.toll_rounded,
      ),
      title: Text(coin.reasonLabel),
      subtitle: Text(subtitle),
      trailing: Text('$sign${formatPoints(coin.amount.abs())} KOIN'),
    );
  }
}
