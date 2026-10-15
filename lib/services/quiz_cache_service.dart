import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz.dart';
import '../helpers/format.dart';
import 'quiz_index.dart';
import 'session_service.dart';

class QuizCacheService {
  QuizCacheService._();
  static final QuizCacheService instance = QuizCacheService._();

  static const _prefix = 'cache_';
  static const _version = 2;
  static const _allKey = 'all';
  static const _mineKey = 'mine';

  /// Cache disimpan per-username supaya data user lain di perangkat yang sama
  /// tidak ikut terbaca.
  Future<String> _scope() async {
    final user = await SessionService.instance.getUser();
    final username = (user?['username'] as String?)?.trim() ?? '';
    return username.isEmpty ? 'guest' : username;
  }

  String _key(String kind, String scope) => '$_prefix$kind-$scope';

  Future<QuizCache> saveAllQuizzes(AllQuizzes data) async {
    final scope = await _scope();
    return _write(_key(_allKey, scope), data.all, data.groups);
  }

  Future<QuizCache> saveMyQuizzes(MyQuizzes data) async {
    final scope = await _scope();
    return _write(_key(_mineKey, scope), data.all, data.groups);
  }

  /// Balas `null` kalau belum pernah sync, cache rusak, atau versinya berbeda.
  Future<QuizCache?> readAll() async {
    final scope = await _scope();
    return _read(_key(_allKey, scope));
  }

  Future<QuizCache?> readMine() async {
    final scope = await _scope();
    return _read(_key(_mineKey, scope));
  }

  Future<Quizes?> getQuizById(String id) async {
    final all = await readAll();
    final mine = await readMine();
    if (all != null) {
      final hit = _findById(all.all, id);
      if (hit != null) return hit;
    }
    if (mine != null) return _findById(mine.all, id);
    return null;
  }

  Quizes? _findById(List<Quizes> quizzes, String id) {
    for (final quiz in quizzes) {
      if (quiz.id == id) return quiz;
    }
    return null;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_prefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<QuizCache> _write(
    String key,
    List<Quizes> quizzes,
    List<({String status, List<Quizes> quizzes})> groups,
  ) async {
    final savedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'version': _version,
        'savedAt': savedAt.toIso8601String(),
        'groups': {
          for (final group in groups)
            group.status: group.quizzes.map((quiz) => quiz.id).toList(),
        },
        'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
      }),
    );
    return QuizCache(all: quizzes, groups: _groupIds(groups), savedAt: savedAt);
  }

  Future<QuizCache?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        // Cache versi lama: daftar flat tanpa peta grup. Grup diturunkan dari
        // status room terakhir lalu ditulis ulang ke format baru.
        final quizzes = _parse(decoded);
        final cache = QuizCache(
          all: quizzes,
          groups: _deriveGroups(quizzes),
          savedAt: DateTime.now(),
        );
        await prefs.setString(
          key,
          jsonEncode({
            'version': _version,
            'savedAt': cache.savedAt.toIso8601String(),
            'groups': cache.groups,
            'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
          }),
        );
        return cache;
      }

      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      if (map['version'] != _version) return null;

      final groups = <String, List<String>>{};
      final rawGroups = map['groups'];
      if (rawGroups is Map) {
        for (final entry in rawGroups.entries) {
          groups['${entry.key}'] = (entry.value as List? ?? [])
              .whereType<String>()
              .toList();
        }
      }

      return QuizCache(
        all: _parse(map['quizzes']),
        groups: groups,
        savedAt:
            DateTime.tryParse(map['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      debugPrint('Quiz cache read error: $e');
      return null;
    }
  }

  List<Quizes> _parse(dynamic raw) {
    return (raw as List? ?? [])
        .map((e) => Quizes.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Map<String, List<String>> _groupIds(
    List<({String status, List<Quizes> quizzes})> groups,
  ) {
    return {
      for (final group in groups)
        group.status: group.quizzes.map((quiz) => quiz.id).toList(),
    };
  }

  /// Server mengelompokkan kuis berdasarkan status room paling terakhir dibuat;
  /// kuis tanpa room masuk grup `quarantine`.
  Map<String, List<String>> _deriveGroups(List<Quizes> quizzes) {
    final groups = <String, List<String>>{};
    for (final quiz in quizzes) {
      final status = _latestStatus(quiz);
      groups.putIfAbsent(status, () => <String>[]).add(quiz.id);
    }
    return groups;
  }

  String _latestStatus(Quizes quiz) {
    if (quiz.rooms.isEmpty) return 'quarantine';
    var latest = quiz.rooms.first;
    for (final room in quiz.rooms) {
      final time = parseTimeOrEpoch(room.createdAt);
      if (time.isAfter(parseTimeOrEpoch(latest.createdAt))) latest = room;
    }
    return latest.status;
  }
}
