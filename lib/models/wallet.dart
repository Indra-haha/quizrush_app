import '../helpers/json.dart';

/// Transaksi satuan pada dompet on-chain (event BalanceChanged).
class WalletHistoryItem {
  final String id;
  final String userId;
  final int pointsClaimed;
  final double rupiahValue;
  final String status;
  final String createdAt;
  final String txHash;
  final String explorerUrl;

  const WalletHistoryItem({
    required this.id,
    required this.userId,
    required this.pointsClaimed,
    required this.rupiahValue,
    required this.status,
    required this.createdAt,
    this.txHash = '',
    this.explorerUrl = '',
  });

  factory WalletHistoryItem.fromJson(Map<String, dynamic> json) {
    return WalletHistoryItem(
      id: jsonString(json['_id'] ?? json['id']),
      userId: jsonString(json['user_id']),
      pointsClaimed: jsonInt(json['points_claimed']),
      rupiahValue: jsonDouble(json['rupiah_value']),
      status: jsonString(json['status'], 'SUCCESS'),
      createdAt: jsonString(json['created_at']),
      txHash: jsonString(json['tx_hash']),
      explorerUrl: jsonString(json['explorer_url']),
    );
  }

  /// True jika transaksi merupakan pengurangan rupiah (tarik saldo).
  bool get isWithdrawal => rupiahValue < 0 || (pointsClaimed == 0 && rupiahValue <= 0);

  /// True jika transaksi merupakan klaim poin ke saldo rupiah.
  bool get isClaim => pointsClaimed > 0 || rupiahValue > 0;
}

/// Respons dari GET /api/me/wallet.
class WalletResponse {
  final String status;
  final String message;
  final String walletAddress;
  final int currentBalance;
  final List<WalletHistoryItem> data;

  const WalletResponse({
    required this.status,
    required this.currentBalance,
    required this.data,
    this.message = '',
    this.walletAddress = '',
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    // Dukung kemungkinan data dibungkus dalam key `data` seperti:
    // { "status": "SUCCESS", "data": { "current_balance": 10000, ... } }
    final rawData = json['data'];
    final Map<String, dynamic> dataMap = rawData is Map<String, dynamic> ? rawData : json;

    return WalletResponse(
      status: jsonString(json['status'], 'SUCCESS'),
      message: jsonString(json['message'] ?? dataMap['message']),
      walletAddress: jsonString(json['wallet_address'] ?? dataMap['wallet_address']),
      currentBalance: jsonInt(
        dataMap['current_balance'] ??
            json['current_balance'] ??
            dataMap['currentWallet'] ??
            json['currentWallet'] ??
            dataMap['current_wallet'] ??
            json['current_wallet'] ??
            dataMap['balance'] ??
            json['balance'] ??
            dataMap['saldo'] ??
            json['saldo'] ??
            dataMap['equivalent_rupiah'] ??
            json['equivalent_rupiah'],
      ),
      data: rawData is List
          ? jsonMapList(rawData).map(WalletHistoryItem.fromJson).toList()
          : (dataMap['transactions'] is List
              ? jsonMapList(dataMap['transactions']).map(WalletHistoryItem.fromJson).toList()
              : jsonMapList(dataMap['data']).map(WalletHistoryItem.fromJson).toList()),
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

