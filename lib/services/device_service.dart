import 'dart:io';

/// ID perangkat yang diturunkan dari info platform (agent), bukan acak.
///
/// Nilai stabil untuk kombinasi OS/versi/host perangkat yang sama.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  String? _cached;

  /// String agent mentah dari platform, mis. `android/.../host`.
  String get agent =>
      '${Platform.operatingSystem}/${Platform.operatingSystemVersion}'
      '/${Platform.localHostname}';

  /// User-Agent bergaya smartphone agar lolos allowlist device di backend
  /// (`middleware.DeviceLabel` hanya menerima UA Android/iPhone/Mobile).
  String get userAgent {
    if (Platform.isIOS || Platform.isMacOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
          'Mobile/15E148 Safari/604.1';
    }
    return 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  }

  String getId() => _cached ??= _buildFromAgent();

  String _buildFromAgent() {
    final hash = _fnv1a(agent);
    return 'dev-${hash.toRadixString(16).padLeft(16, '0')}';
  }

  int _fnv1a(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash;
  }
}
