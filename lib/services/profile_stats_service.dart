import 'api/points_service.dart';
import 'points_store.dart';
import 'quiz_feed.dart';
import 'quiz_index.dart';
import 'api/result_service.dart';
import 'session_service.dart';

class ProfileStats {
  final int? games;
  final int? accuracy;
  final int? points;

  const ProfileStats({this.games, this.accuracy, this.points});
}

class ProfileStatsService {
  ProfileStatsService({
    ResultService? resultService,
    PointsService? pointsService,
    Future<QuizIndex?> Function()? myQuizzes,
  }) : _resultService = resultService ?? ResultService.instance,
       _pointsService = pointsService ?? PointsService.instance,
       _myQuizzes = myQuizzes ?? _loadMyQuizzes;

  static final ProfileStatsService instance = ProfileStatsService();

  final ResultService _resultService;
  final PointsService _pointsService;
  final Future<QuizIndex?> Function() _myQuizzes;

  static Future<QuizIndex?> _loadMyQuizzes() async {
    final result = await QuizFeed.loadMine();
    return result.index;
  }

  Future<ProfileStats> load({required String nama}) async {
    final token = await SessionService.instance.getToken();
    final normalizedNama = nama.trim().toLowerCase();

    int? games;
    try {
      final index = await _myQuizzes();
      if (index != null) {
        games = index.all.fold<int>(
          0,
          (total, quiz) => total + quiz.rooms.length,
        );
      }
    } catch (_) {
      games = null;
    }

    int? accuracy;
    int? points;

    if (token != null && token.isNotEmpty) {
      try {
        final results = await _resultService.fetchResults(token: token);
        final scores = <int>[];
        if (normalizedNama.isNotEmpty) {
          for (final result in results) {
            for (final entry in result.entries) {
              if (entry.nama.trim().toLowerCase() == normalizedNama) {
                scores.add(entry.skor);
              }
            }
          }
        }
        if (scores.isNotEmpty) {
          final total = scores.fold<int>(0, (sum, score) => sum + score);
          accuracy = (total / scores.length).round();
        }
      } catch (_) {
        accuracy = null;
      }

      try {
        final fetched = await _pointsService.fetchPoints(token: token);
        points = fetched;
        PointsStore.instance.set(fetched);
      } catch (_) {
        points = null;
      }
    }

    points ??= PointsStore.instance.points;
    return ProfileStats(games: games, accuracy: accuracy, points: points);
  }
}
