import 'package:flutter/foundation.dart';

import 'api/points_service.dart';
import 'session_service.dart';

/// Sumber poin global untuk indikator poin di appbar.
///
/// Nilai awal diambil dari sesi tersimpan (respons login/session sudah memuat
/// `points`), lalu disegarkan dari server lewat [refresh] — mis. setelah
/// permainan selesai atau saat appbar pertama dibuka.
class PointsStore extends ChangeNotifier {
  PointsStore._();

  static final PointsStore instance = PointsStore._();

  int? _points;
  bool _loading = false;

  int? get points => _points;
  bool get loading => _loading;

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
      final fetched = await PointsService.instance.fetchPoints(token: token);
      _points = fetched;
    } catch (_) {
      // Biarkan nilai lama; indikator tetap menampilkan yang terakhir diketahui.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
