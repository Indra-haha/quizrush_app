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

  /// Kirim request ke `POST /api/wallet/claim` untuk:
  /// - Menukar poin menjadi rupiah (`pointsToClaim > 0`, `rupiahValue` opsional/positif)
  /// - Mengurangi saldo rupiah / tarik saldo (`pointsToClaim == 0`, `rupiahValue < 0`)
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
      'rupiah_value': ?rupiahValue,
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

  /// Ambil saldo rupiah on-chain dan riwayat transaksi dari `GET /api/wallet/{user}`.
  ///
  /// [user] dapat berupa username atau ObjectID pengguna yang sedang login.
  Future<WalletResponse> fetchWallet({
    required String token,
    required String user,
  }) async {
    final response = await _api.get(
      '/api/wallet/${Uri.encodeComponent(user)}',
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
}
