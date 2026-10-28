import '../helpers/json.dart';

/// Transaksi satuan pada dompet on-chain (event BalanceChanged).
class WalletHistoryItem {
  final String id;
  final String userId;
  final int pointsClaimed;
  final double rupiahValue;
  final String status;
  final String createdAt;

  const WalletHistoryItem({
    required this.id,
    required this.userId,
    required this.pointsClaimed,
    required this.rupiahValue,
    required this.status,
    required this.createdAt,
  });

  factory WalletHistoryItem.fromJson(Map<String, dynamic> json) {
    return WalletHistoryItem(
      id: jsonString(json['_id']),
      userId: jsonString(json['user_id']),
      pointsClaimed: jsonInt(json['points_claimed']),
      rupiahValue: jsonDouble(json['rupiah_value']),
      status: jsonString(json['status'], 'SUCCESS'),
      createdAt: jsonString(json['created_at']),
    );
  }

  /// True jika transaksi merupakan pengurangan rupiah (tarik saldo).
  bool get isWithdrawal => rupiahValue < 0 || (pointsClaimed == 0 && rupiahValue <= 0);

  /// True jika transaksi merupakan klaim poin ke saldo rupiah.
  bool get isClaim => pointsClaimed > 0 || rupiahValue > 0;
}

/// Respons dari GET /api/wallet/{user}.
class WalletResponse {
  final String status;
  final int currentBalance;
  final List<WalletHistoryItem> data;

  const WalletResponse({
    required this.status,
    required this.currentBalance,
    required this.data,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      status: jsonString(json['status'], 'SUCCESS'),
      currentBalance: jsonInt(json['current_balance']),
      data: jsonMapList(json['data']).map(WalletHistoryItem.fromJson).toList(),
    );
  }
}

/// Respons dari POST /api/wallet/claim.
class WalletClaimResult {
  final String status;
  final String message;
  final String txHash;
  final int? remainingPoints;

  const WalletClaimResult({
    required this.status,
    required this.message,
    required this.txHash,
    this.remainingPoints,
  });

  factory WalletClaimResult.fromJson(Map<String, dynamic> json) {
    return WalletClaimResult(
      status: jsonString(json['status'], 'SUCCESS'),
      message: jsonString(json['message']),
      txHash: jsonString(json['tx_hash']),
      remainingPoints: json['remaining_points'] != null
          ? jsonInt(json['remaining_points'])
          : null,
    );
  }
}

