import '../../helpers/json.dart';
import '../../models/wallet.dart';
import 'api_client.dart';

/// Klien transaksi saldo on-chain (Base Sepolia) dan klaim reward.
class WalletService {
  WalletService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  WalletService.withApi(this._api);

  static final WalletService instance = WalletService._(ApiClient.instance);

  final ApiClient _api;
  ///
  /// Response: [WalletClaimResult] yang memuat status, pesan, tx_hash, dan remaining_points.
  Future<WalletClaimResult> claim({
    required String token,
    String? userId,
    int pointsToClaim = 0,
    double? rupiahValue,
  }) async {
    final body = <String, dynamic>{
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'points_to_claim': pointsToClaim,
      'rupiah_value': rupiahValue,
    };

    final response = await _api.post(
      '/api/wallet/claim',
      token: token,
      body: body,
    );

    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data, statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return WalletClaimResult.fromJson(jsonMap(data));
  }

  /// Ambil saldo rupiah on-chain dan riwayat transaksi dari GET /api/me/wallet.
  /// Identitas diambil dari token (tanpa perlu mengirim user di path).
  Future<WalletResponse> fetchMyWallet({required String token}) async {
    final response = await _api.get(
      '/api/me/wallet',
      token: token,
    );

    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data, statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return WalletResponse.fromJson(jsonMap(data));
  }

  /// Kompatibilitas dengan pemanggil lama yang mempassing `user`.
  Future<WalletResponse> fetchWallet({
    required String token,
    String? user,
  }) async {
    return fetchMyWallet(token: token);
  }

}

