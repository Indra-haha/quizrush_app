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
    return CoinEntry(
      id: jsonString(json['id']),
      amount: jsonInt(json['amount']),
      reason: jsonString(json['reason']),
      roomKode: jsonString(json['room_kode']),
      quizId: jsonString(json['quiz_id']),
      createdAt: jsonString(json['created_at']),
      prevHash: jsonString(json['prev_hash']),
      hash: jsonString(json['hash']),
    );
  }

  /// Label alasan yang ramah dibaca.
  String get reasonLabel => switch (reason) {
    'quiz_reward' => 'Hadiah kuis',
    _ => reason,
  };
}
