import '../helpers/json.dart';

/// Payload request untuk POST /api/feedback (§16.1).
class FeedbackRequest {
  final String username;
  final String saran;
  final String kesan;

  const FeedbackRequest({
    required this.username,
    required this.saran,
    required this.kesan,
  });

  Map<String, dynamic> toJson() => {
    'username': username.trim(),
    'saran': saran.trim(),
    'kesan': kesan.trim(),
  };
}

/// Dokumen feedback yang dikembalikan dalam response (§16.1).
class FeedbackItem {
  final String id;
  final String username;
  final String saran;
  final String kesan;
  final String createdAt;

  const FeedbackItem({
    required this.id,
    required this.username,
    required this.saran,
    required this.kesan,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: jsonString(json['id']),
      username: jsonString(json['username']),
      saran: jsonString(json['saran']),
      kesan: jsonString(json['kesan']),
      createdAt: jsonString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'saran': saran,
    'kesan': kesan,
    'created_at': createdAt,
  };
}

/// Response dari POST /api/feedback (§16.1).
class FeedbackResponse {
  final String message;
  final FeedbackItem feedback;

  const FeedbackResponse({
    required this.message,
    required this.feedback,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      message: jsonString(json['message']),
      feedback: FeedbackItem.fromJson(jsonMap(json['feedback'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'feedback': feedback.toJson(),
  };
}
