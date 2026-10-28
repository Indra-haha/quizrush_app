import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../helpers/format.dart';
import '../../models/live_game.dart';
import '../../models/room.dart';
import '../../services/live_game_controller.dart';
import '../../services/api/room_socket.dart';
import '../../services/notification_service.dart';
import '../../services/profile_settings_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/leaderboard_pause_view.dart';
import '../../widgets/quiz_answer_banner.dart';
import '../../widgets/quiz_countdown_dial.dart';
import '../../widgets/quiz_option_tile.dart';
import '../../widgets/quiz_question_card.dart';
import '../../widgets/quiz_test_header.dart';
import 'quiz_result_page.dart';

/// Halaman permainan live: merender soal aktif, timer, dan pilihan jawaban;
/// menampilkan papan jeda antar soal; lalu berpindah ke hasil akhir saat kuis
/// selesai. Seluruh aturan permainan ada di [LiveGameController].
///
/// Untuk host ([isHost] true), sesi soal tidak menampilkan view peserta
/// (soal / opsi / jawaban); host hanya melihat progress soal dan papan
/// peringkat sementara.
class LiveQuizPage extends StatefulWidget {
  final Room room;
  final RoomSocket socket;
  final String loginToken;
  final String myUsername;
  final String myNama;
  final LiveQuestion initialQuestion;
  final bool isHost;

  const LiveQuizPage({
    super.key,
    required this.room,
    required this.socket,
    required this.loginToken,
    required this.myUsername,
    required this.myNama,
    required this.initialQuestion,
    this.isHost = false,
  });

  @override
  State<LiveQuizPage> createState() => _LiveQuizPageState();
}

class _LiveQuizPageState extends State<LiveQuizPage> {
  late final LiveGameController _controller;
  bool _navHandled = false;

  // Fitur auto-choose jawaban via Gyroscope / kemiringan
  bool _gyroAnswerEnabled = false;
  bool _hasBaseline = false;
  int _calibrationSamples = 0;
  double _sumAccX = 0.0;
  double _sumAccY = 0.0;
  double _sumAccZ = 0.0;
  double _baseAccX = 0.0;
  double _baseAccY = 0.0;
  double _baseAccZ = 0.0;

  double _currentAccX = 0.0;
  double _currentAccY = 0.0;
  double _currentAccZ = 0.0;
  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;
  double _currentGyroZ = 0.0;

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  bool _isNeutral = true;
  int? _lastChosenIndex;
  int? _lastQuestionIndex;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = LiveGameController(
      socket: widget.socket,
      roomKode: widget.room.kode,
      loginToken: widget.loginToken,
      myUsername: widget.myUsername,
      isHost: widget.isHost,
      initialQuestion: widget.initialQuestion,
    );
    _controller.addListener(_onChanged);
    _loadGyroSettings();
  }

  Future<void> _loadGyroSettings() async {
    if (widget.isHost) return;
    final service = ProfileSettingsService.instance;
    final enabled = await service.gyroscopeEnabled();
    if (!mounted || !enabled) return;

    final baseline = await service.getGyroBaseline();
    if (baseline != null) {
      _baseAccX = baseline['x']!;
      _baseAccY = baseline['y']!;
      _baseAccZ = baseline['z']!;
      _hasBaseline = true;
    }

    setState(() {
      _gyroAnswerEnabled = true;
    });

    _startGyroListening();
  }

  void _startGyroListening() {
    _gyroSub?.cancel();
    _accelSub?.cancel();

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!_gyroAnswerEnabled || widget.isHost || !mounted) return;

          _currentAccX = event.x;
          _currentAccY = event.y;
          _currentAccZ = event.z;

          // Jika belum memiliki baseline tersimpan, kalibrasi dari 5 sampel awal
          if (!_hasBaseline) {
            _sumAccX += event.x;
            _sumAccY += event.y;
            _sumAccZ += event.z;
            _calibrationSamples++;

            if (_calibrationSamples >= 5) {
              _baseAccX = _sumAccX / _calibrationSamples;
              _baseAccY = _sumAccY / _calibrationSamples;
              _baseAccZ = _sumAccZ / _calibrationSamples;
              setState(() {
                _hasBaseline = true;
              });
              unawaited(ProfileSettingsService.instance.setGyroBaseline(
                x: _baseAccX,
                y: _baseAccY,
                z: _baseAccZ,
              ));
            }
            return;
          }

          _evaluateGyroAnswer();
        },
        onError: (_) {
          _accelSub?.cancel();
          _accelSub = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      _accelSub = null;
    }

    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!_gyroAnswerEnabled || widget.isHost || !mounted) return;

          _currentGyroX = event.x;
          _currentGyroY = event.y;
          _currentGyroZ = event.z;

          if (_hasBaseline) {
            _evaluateGyroAnswer();
          }
        },
        onError: (_) {
          _gyroSub?.cancel();
          _gyroSub = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      _gyroSub = null;
    }
  }

  void _recalibratePosition() {
    setState(() {
      _hasBaseline = false;
      _calibrationSamples = 0;
      _sumAccX = 0.0;
      _sumAccY = 0.0;
      _sumAccZ = 0.0;
      _isNeutral = true;
    });
    HapticFeedback.lightImpact();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.crop_rotate_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mengkalibrasi posisi HP... Tahan posisi nyaman Anda.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _evaluateGyroAnswer() {
    if (!_gyroAnswerEnabled || widget.isHost || !mounted) return;
    final question = _controller.question;
    if (question == null ||
        _controller.answered ||
        _controller.phase != LivePhase.question) {
      return;
    }

    if (!_hasBaseline) return;

    final deltaAccX = _currentAccX - _baseAccX;
    final deltaAccY = _currentAccY - _baseAccY;

    final gyroPitch = _currentGyroX; // Pitch rotasi sumbu X (gerakan ke depan/belakang)
    final gyroRoll = _currentGyroY;  // Roll rotasi sumbu Y (kemiringan ke kiri/kanan)

    // Gabungan sinyal kemiringan & goyangan dinamis
    final signalX = deltaAccX + (gyroRoll * 1.0);
    final signalY = deltaAccY + (gyroPitch * 1.0);

    const double triggerThreshold = 2.0;
    const double neutralThreshold = 0.8;

    final absX = signalX.abs();
    final absY = signalY.abs();

    if (absX < neutralThreshold && absY < neutralThreshold) {
      _isNeutral = true;
      return;
    }

    if (absX >= triggerThreshold || absY >= triggerThreshold) {
      int targetIndex = -1;
      String directionName = '';

      if (absY > absX) {
        if (signalY < -triggerThreshold) {
          // Gerakan ke depan -> Opsi C (index 2)
          targetIndex = 2;
          directionName = 'Tilt Depan / Atas';
        } else if (signalY > triggerThreshold) {
          // Gerakan ke belakang -> Opsi D (index 3)
          targetIndex = 3;
          directionName = 'Tilt Belakang / Bawah';
        }
      } else {
        if (signalX > triggerThreshold) {
          // Miring ke kiri -> Opsi A (index 0)
          targetIndex = 0;
          directionName = 'Ke Kiri';
        } else if (signalX < -triggerThreshold) {
          // Miring ke kanan -> Opsi B (index 1)
          targetIndex = 1;
          directionName = 'Ke Kanan';
        }
      }

      if (targetIndex >= 0 && targetIndex < question.options.length) {
        final now = DateTime.now();
        final isDifferent = targetIndex != _lastChosenIndex;
        final cooldownPassed =
            now.difference(_lastTriggerTime) > const Duration(milliseconds: 1200);

        if (_isNeutral || isDifferent || cooldownPassed) {
          _isNeutral = false;
          _lastTriggerTime = now;
          _lastChosenIndex = targetIndex;

          _handleGyroAnswerSelected(targetIndex, directionName);
        }
      }
    }
  }

  void _handleGyroAnswerSelected(int index, String directionName) {
    if (_controller.answered) return;

    // Auto-choose: submit jawaban ke LiveGameController
    _controller.answer(index);

    HapticFeedback.mediumImpact();

    final letter = String.fromCharCode(65 + index % optionThemes.length);
    final optionText = (_controller.question != null &&
            index < _controller.question!.options.length)
        ? _controller.question!.options[index]
        : '';

    

    // Visual In-App Notification (Floating SnackBar)
    if (mounted) {
      final theme = optionThemes[index % optionThemes.length];
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          backgroundColor: theme.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.screen_rotation_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opsi $letter Terpilih!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Arah: $directionName • Sensor Gyroscope',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _accelSub?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;

    if (_controller.phase == LivePhase.ended && !_navHandled) {
      _navHandled = true;
      final end = _controller.gameEnd;
      if (end != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultPage(
              result: end,
              myUsername: widget.myUsername,
              myScore: _controller.totalScore,
              myCorrect: _controller.correctCount,
              myAnswered: _controller.answeredCount,
              roomTitle: widget.room.displayTitle,
              isHost: widget.isHost,
            ),
          ),
        );
      }
      return;
    }

    // Reset neutral saat berpindah soal
    final currentQIndex = _controller.question?.index;
    if (currentQIndex != _lastQuestionIndex) {
      _lastQuestionIndex = currentQIndex;
      _isNeutral = true;
      _lastChosenIndex = null;
    }

    setState(() {});
  }

  QuizOptionState _stateFor(int index) {
    final controller = _controller;
    if (!controller.answered) {
      return controller.selectedIndex == index
          ? QuizOptionState.selected
          : QuizOptionState.idle;
    }
    final question = controller.question;
    if (question == null) return QuizOptionState.dimmed;
    if (index == question.correctIdx) return QuizOptionState.correct;
    if (index == controller.selectedIndex) return QuizOptionState.wrong;
    return QuizOptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final pause = _controller.roundResult;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: widget.room.displayTitle,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
        ),
      ),
      body: switch (_controller.phase) {
        LivePhase.pause when pause != null => LeaderboardPauseView(
          round: pause.round,
          total: pause.total,
          nextInMs: pause.nextInMs,
          leaderboard: pause.leaderboard,
          myUsername: widget.myUsername,
          isHost: widget.isHost,
        ),
        LivePhase.ended => const Center(child: CircularProgressIndicator()),
        _ => widget.isHost ? _buildHostDashboard() : _buildQuestion(),
      },
    );
  }

  Widget _buildQuestion() {
    final question = _controller.question;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space4,
        AppSpacing.space8,
        AppSpacing.space10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuizTestHeader(
            title: widget.room.displayTitle,
            currentIndex: question.index,
            totalQuestions: question.total,
            maxScore: question.maxScore,
            totalScore: _controller.totalScore,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: QuizCountdownDial(seconds: _controller.timeLeft),
            ),
          ),
          QuizQuestionCard(question: question.question),
          const SizedBox(height: AppSpacing.space8),
          _buildOptions(question),
          if (_controller.answered && _controller.isCorrect != null) ...[
            const SizedBox(height: AppSpacing.space4),
            QuizAnswerBanner(
              isCorrect: _controller.isCorrect!,
              gainedScore: _controller.gainedScore,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(LiveQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_gyroAnswerEnabled) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.space6),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.screen_rotation_alt_rounded,
                      size: AppIconSize.sm,
                      color: AppColors.locationInk,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Gyro Aktif: ⬅ A | ➡ B | ⬆ C | ⬇ D',
                      style: AppTextStyles.labelStrongSmall.copyWith(
                        color: AppColors.locationInk,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _recalibratePosition,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Kalibrasi',
                      style: AppTextStyles.bodyCaption.copyWith(
                        color: AppColors.locationInk,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        for (var index = 0; index < question.options.length; index++)
          QuizOptionTile(
            label: question.options[index],
            letter: String.fromCharCode(65 + index % optionThemes.length),
            theme: optionThemes[index % optionThemes.length],
            state: _stateFor(index),
            onTap: _controller.answered
                ? null
                : () => _controller.answer(index),
          ),
      ],
    );
  }

  /// Dashboard host selama sesi soal berjalan: progress soal + timer +
  /// papan peringkat sementara (tanpa soal maupun opsi jawaban).
  Widget _buildHostDashboard() {
    final question = _controller.question;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space4,
        AppSpacing.space8,
        AppSpacing.space10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hostHeader(question),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: QuizCountdownDial(seconds: _controller.timeLeft),
            ),
          ),
          _hostStandingsHeader(),
          const SizedBox(height: AppSpacing.space4),
          ..._hostStandingsRows(),
        ],
      ),
    );
  }

  Widget _hostHeader(LiveQuestion question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.room.displayTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelStrongSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              AppPill(
                text: 'Soal ${question.index + 1}',
                trailingText: '/ ${question.total}',
                trailingColor: AppColors.textSecondary,
                background: AppColors.surfaceSoft,
                foreground: AppColors.textPrimary,
                dot: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space2,
                ),
              ),
            ],
          ),
        ),
        AppPill(
          text: 'MODE HOST',
          background: AppColors.primary,
          foreground: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space2,
          ),
        ),
      ],
    );
  }

  Widget _hostStandingsHeader() {
    return Row(
      children: [
        Text(
          'PERINGKAT SEMENTARA',
          style: AppTextStyles.accentCaption.copyWith(letterSpacing: 1.2),
        ),
        const Spacer(),
        Text(
          'Total ${_controller.lastLeaderboard.length} peserta',
          style: AppTextStyles.bodyCaption,
        ),
      ],
    );
  }

  List<Widget> _hostStandingsRows() {
    final entries = _controller.lastLeaderboard;
    if (entries.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary,
            border: Border.all(
              color: AppColors.primaryBorder.withValues(alpha: 0.4),
            ),
            borderRadius: AppRadius.md,
          ),
          child: Text(
            'Belum ada data peringkat. Menunggu ronde pertama selesai...',
            style: AppTextStyles.bodyCaption,
          ),
        ),
      ];
    }
    return [for (final entry in entries) _hostRankRow(entry)];
  }

  Widget _hostRankRow(LiveLeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
          width: AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              _medal(entry.rank),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelStrong,
                ),
                Text(
                  '${(entry.accuracy * 100).toStringAsFixed(1)}% '
                  '(${entry.correct}/${entry.answered})',
                  style: AppTextStyles.bodyCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '${formatPoints(entry.score)} PTS',
            style: AppTextStyles.labelStrongSmall.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) => switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '#$rank',
  };
}
