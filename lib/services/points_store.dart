import 'package:flutter/foundation.dart';

import '../models/points.dart';
import 'api/points_service.dart';
import 'session_service.dart';

/// Sumber poin global untuk indikator poin di appbar.
/// Nilai awal diambil dari sesi tersimpan (respons login/session sudah memuat
/// points), lalu disegarkan dari server lewat [refresh].
class PointsStore extends ChangeNotifier {
  PointsStore._();

  static final PointsStore instance = PointsStore._();

  int? _points;
  bool _loading = false;
  PointsResponse? _detail;

  int? get points => _points;
  bool get loading => _loading;
  PointsResponse? get detail => _detail;
  List<CoinEntry> get history => _detail?.history ?? const [];

  /// Isi nilai poin dari peta user sesi (bila ada).
  void setFromUser(Map<String, dynamic>? user) {
    final value = user?['points'];
    if (value is num) {
      _points = value.toInt();
      notifyListeners();
    }
  }

  /// Set nilai poin langsung (mis. setelah permainan dibayar).
  void set(int value) {
    _points = value;
    if (_detail != null) {
      _detail = PointsResponse(
        message: _detail!.message,
        points: value,
        history: _detail!.history,
      );
    }
    notifyListeners();
  }

  /// Simpan detail poin (points + history) dari hasil fetch.
  void setDetail(PointsResponse detail) {
    _detail = detail;
    _points = detail.points;
    notifyListeners();
  }

  /// Segarkan dari server. Gagal (mis. offline) dibiarkan senyap.
  Future<void> refresh() async {
    if (_loading) return;
    final token = await SessionService.instance.getToken();
    if (token == null || token.isEmpty) return;

    _loading = true;
    notifyListeners();
    try {
      final fetched = await PointsService.instance.fetchPointsDetail(token: token);
      _detail = fetched;
      _points = fetched.points;
    } catch (_) {
      // Biarkan nilai lama; indikator tetap menampilkan yang terakhir diketahui.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

