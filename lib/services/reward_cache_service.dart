import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/points.dart';
import '../models/wallet.dart';
import 'session_service.dart';

/// Service cache lokal untuk data poin & dompet rupiah (Reward).
/// Cache dipisahkan per user scope agar multi-user di satu perangkat tidak bercampur.
class RewardCacheService {
  RewardCacheService._();
  static final RewardCacheService instance = RewardCacheService._();

  static const _prefix = 'cache_reward_';

  Future<String> _scope() async {
    final user = await SessionService.instance.getUser();
    final username = (user?['username'] as String?)?.trim() ?? '';
    return username.isEmpty ? 'guest' : username;
  }

  // ==========================================
  // CACHE POIN & RIWAYAT POIN (/api/me/points)
  // ==========================================

  Future<void> savePointsDetail(PointsResponse data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = await _scope();
      final map = {
        'message': data.message,
        'points': data.points,
        'history': data.history
            .map((h) => {
                  'id': h.id,
                  'amount': h.amount,
                  'reason': h.reason,
                  'room_kode': h.roomKode,
                  'quiz_id': h.quizId,
                  'created_at': h.createdAt,
                  'prev_hash': h.prevHash,
                  'hash': h.hash,
                })
            .toList(),
      };
      await prefs.setString('${_prefix}points_$scope', jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving points cache: $e');
    }
  }

  Future<PointsResponse?> readPointsDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = await _scope();
      final raw = prefs.getString('${_prefix}points_$scope');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return PointsResponse.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error reading points cache: $e');
    }
    return null;
  }

  // ==========================================
  // CACHE WALLET & RIWAYAT SALDO (/api/me/wallet)
  // ==========================================

  Future<void> saveWallet(WalletResponse data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = await _scope();
      final map = {
        'status': data.status,
        'message': data.message,
        'wallet_address': data.walletAddress,
        'current_balance': data.currentBalance,
        'data': data.data
            .map((w) => {
                  '_id': w.id,
                  'user_id': w.userId,
                  'points_claimed': w.pointsClaimed,
                  'rupiah_value': w.rupiahValue,
                  'status': w.status,
                  'created_at': w.createdAt,
                  'tx_hash': w.txHash,
                  'explorer_url': w.explorerUrl,
                })
            .toList(),
      };
      await prefs.setString('${_prefix}wallet_$scope', jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving wallet cache: $e');
    }
  }

  Future<WalletResponse?> readWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = await _scope();
      final raw = prefs.getString('${_prefix}wallet_$scope');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return WalletResponse.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error reading wallet cache: $e');
    }
    return null;
  }
}

