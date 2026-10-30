import 'package:flutter/foundation.dart';

import '../models/quiz.dart';
import 'api/api_client.dart';
import 'cache/quiz_cache_service.dart';
import 'quiz_index.dart';
import 'api/quiz_service.dart';
import 'session_service.dart';

/// Hasil satu proses muat daftar quiz: indeks untuk ditampilkan, atau alasan
/// kenapa gagal.
///
/// [needsAuth] terpisah dari [error] supaya halaman tidak perlu menangkap
/// [ApiException] hanya untuk memeriksa `statusCode == 401`.
typedef QuizFeedResult = ({QuizIndex? index, String? error, bool needsAuth});

/// Pembacaan daftar quiz yang dipakai semua halaman: baca cache dulu, hubungi
/// server hanya kalau perlu, lalu simpan hasilnya kembali ke cache.
///
/// Fungsi-fungsinya murni data, tanpa [BuildContext], supaya bisa diuji dan
/// tidak mengikat layer UI ke HTTP.
class QuizFeed {
  QuizFeed._();

  /// Daftar quiz milik pengguna dari cache, atau null kalau cache belum ada.
  static Future<QuizIndex?> readCachedMine() async {
    final cached = await QuizCacheService.instance.readMine();
    if (cached == null) return null;
    return QuizIndex.fromCache(cached);
  }

  /// Daftar semua quiz dari cache, atau null kalau cache belum ada.
  static Future<QuizIndex?> readCachedAll() async {
    final cached = await QuizCacheService.instance.readAll();
    if (cached == null) return null;
    return QuizIndex.fromCache(cached);
  }

  /// Muat dari cache; kalau kosong, langsung sync dari server.
  static Future<QuizFeedResult> loadMine() async {
    final cached = await readCachedMine();
    if (cached != null) return _ok(cached);
    return syncMine();
  }

  static Future<QuizFeedResult> loadAll() async {
    final cached = await readCachedAll();
    if (cached != null) return _ok(cached);
    return syncAll();
  }

  /// Tarik daftar quiz milik pengguna dari server, tulis ke cache, kembalikan
  /// indeksnya.
  static Future<QuizFeedResult> syncMine() async {
    return _guard('Quiz sync error', () async {
      final token = await SessionService.instance.getToken();
      if (token == null) return null;
      final data = await QuizService.instance.getMyQuizzes(token);
      final cache = await QuizCacheService.instance.saveMyQuizzes(data);
      return QuizIndex.fromCache(cache);
    });
  }

  /// Tarik semua daftar quiz dari server, tulis ke cache, kembalikan indeksnya.
  static Future<QuizFeedResult> syncAll() async {
    return _guard('Quizzes sync error', () async {
      final token = await SessionService.instance.getToken();
      if (token == null) return null;
      final data = await QuizService.instance.getQuizzes(token);
      final cache = await QuizCacheService.instance.saveAllQuizzes(data);
      return QuizIndex.fromCache(cache);
    });
  }

  /// Satu quiz milik pengguna, dari cache saja supaya halaman detail tidak
  /// memaksa request server di halaman. Null kalau belum pernah di-cache.
  static Future<Quizes?> readCachedQuizById(String quizId) {
    return QuizCacheService.instance.getQuizById(quizId);
  }

  static QuizFeedResult _ok(QuizIndex index) =>
      (index: index, error: null, needsAuth: false);

  /// Bungkus satu proses sinkronisasi: ubah `ApiException` 401 jadi
  /// [QuizFeedResult.needsAuth] sehingga halaman cukup memeriksa satu flag.
  static Future<QuizFeedResult> _guard(
    String debugLabel,
    Future<QuizIndex?> Function() run,
  ) async {
    try {
      final index = await run();
      if (index == null) return _needsAuth();
      return _ok(index);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await SessionService.instance.clear();
        return _needsAuth();
      }
      return (index: null, error: e.message, needsAuth: false);
    } catch (e) {
      debugPrint('$debugLabel: $e');
      return (
        index: null,
        error: 'Tidak dapat terhubung ke server. ($e)',
        needsAuth: false,
      );
    }
  }

  static QuizFeedResult _needsAuth() =>
      (index: null, error: null, needsAuth: true);
}
