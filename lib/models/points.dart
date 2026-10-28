import '../helpers/json.dart';

/// Satu baris riwayat perolehan koin (ledger SHA-256).
class CoinEntry {
  final String id;
  final int amount;
  final String reason;
  final String roomKode;
  final String quizId;
  final String createdAt;
  final String prevHash;
  final String hash;

  const CoinEntry({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.roomKode = '',
    this.quizId = '',
    this.prevHash = '',
    this.hash = '',
  });

  factory CoinEntry.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    int parsedAmount = 0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toInt();
    } else if (rawAmount is String) {
      final str = rawAmount.trim();
      final isNegative = str.startsWith('-');
      final cleaned = str.replaceAll(RegExp(r'[^0-9]'), '');
      parsedAmount = (int.tryParse(cleaned) ?? 0) * (isNegative ? -1 : 1);
    }

    return CoinEntry(
      id: jsonString(json['id'] ?? json['_id']),
      amount: parsedAmount,
      reason: jsonString(json['reason']),
      roomKode: jsonString(json['room_kode']),
      quizId: jsonString(json['quiz_id']),
      createdAt: jsonString(json['created_at']),
      prevHash: jsonString(json['prev_hash']),
      hash: jsonString(json['hash']),
    );
  }

  String get reasonLabel => switch (reason) {
        'quiz_reward' => 'Hadiah kuis',
        'redeem' => 'Penukaran poin',
        _ => reason,
      };
}

class PointsResponse {
  final String message;
  final int points;
  final List<CoinEntry> history;

  const PointsResponse({
    required this.message,
    required this.points,
    required this.history,
  });

  factory PointsResponse.fromJson(Map<String, dynamic> json) {
    final historyList = json['history'];
    final history = <CoinEntry>[];
    if (historyList is List) {
      for (final item in historyList) {
        if (item is Map) {
          history.add(CoinEntry.fromJson(item.cast<String, dynamic>()));
        }
      }
    }
    return PointsResponse(
      message: jsonString(json['message']),
      points: jsonInt(json['points']),
      history: history,
    );
  }
}

