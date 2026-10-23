import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/points.dart';
import '../services/api/api_client.dart';
import '../services/api/points_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';

/// Riwayat perolehan koin (ledger SHA-256) milik user.
class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({super.key});

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  bool _loading = true;
  String? _error;
  List<CoinEntry> _coins = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await SessionService.instance.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sesi tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    try {
      final coins = await PointsService.instance.fetchCoins(token: token);
      if (!mounted) return;
      setState(() {
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
        _error = 'Tidak bisa memuat riwayat koin.';
      });
    }
  }

  int get _total => _coins.fold<int>(0, (sum, c) => sum + c.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: 'Riwayat Poin',
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }
    if (_coins.isEmpty) {
      return const EmptyStateView(
        icon: Icons.emoji_events_outlined,
        message: 'Belum ada poin.',
        caption: 'Selesaikan kuis live untuk mengumpulkan poin.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.space8),
      itemCount: _coins.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space4),
      itemBuilder: (context, index) {
        if (index == 0) return _summaryCard();
        return _coinCard(_coins[index - 1]);
      },
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL POIN TERKUMPUL',
            style: AppTextStyles.statLabelOnPrimary.copyWith(
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            formatPoints(_total),
            style: AppTextStyles.statValueOnPrimary.copyWith(
              fontSize: AppFontSize.hero,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${_coins.length} transaksi',
            style: AppTextStyles.statLabelOnPrimary.copyWith(
              fontWeight: AppFontWeight.regular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinCard(CoinEntry coin) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
        ),
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Row(
        children: [
          Container(
            width: AppIconSize.xxl + 8,
            height: AppIconSize.xxl + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.sm,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: AppIconSize.body,
            ),
          ),
          const SizedBox(width: AppSpacing.space6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin.reasonLabel, style: AppTextStyles.labelStrong),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  coin.roomKode.isEmpty
                      ? relativeTime(coin.createdAt)
                      : 'Room ${formatKode(coin.roomKode)} • ${relativeTime(coin.createdAt)}',
                  style: AppTextStyles.bodyCaption,
                ),
                if (coin.hash.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    'hash ${coin.hash.length > 10 ? coin.hash.substring(0, 10) : coin.hash}…',
                    style: AppTextStyles.bodyCaption.copyWith(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Text(
            '+${formatPoints(coin.amount)}',
            style: AppTextStyles.heading5.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
