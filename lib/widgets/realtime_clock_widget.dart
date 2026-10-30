import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';

/// Enum zona waktu Indonesia & UTC.
enum IndonesiaTimeZone {
  wib('WIB', 7, 'Waktu Indonesia Barat (UTC+7)'),
  wita('WITA', 8, 'Waktu Indonesia Tengah (UTC+8)'),
  wit('WIT', 9, 'Waktu Indonesia Timur (UTC+9)'),
  utc('UTC', 0, 'Coordinated Universal Time (UTC+0)');

  const IndonesiaTimeZone(this.code, this.offsetHours, this.description);

  final String code;
  final int offsetHours;
  final String description;
}

/// Widget jam digital realtime interaktif dengan pilihan zona waktu (WIB, WITA, WIT, UTC).
/// Tampilan picker menggunakan bottom sheet konsisten seperti create room (AppBottomSheet & dropdown style).
class RealtimeClockWidget extends StatefulWidget {
  final IndonesiaTimeZone initialTimeZone;
  final ValueChanged<IndonesiaTimeZone>? onTimeZoneChanged;

  const RealtimeClockWidget({
    super.key,
    this.initialTimeZone = IndonesiaTimeZone.wib,
    this.onTimeZoneChanged,
  });

  @override
  State<RealtimeClockWidget> createState() => _RealtimeClockWidgetState();
}

class _RealtimeClockWidgetState extends State<RealtimeClockWidget> {
  late IndonesiaTimeZone _timeZone;
  late Timer _timer;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _timeZone = widget.initialTimeZone;
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now().toUtc();
    });
  }

  String _formatTime() {
    final targetTime = _now.add(Duration(hours: _timeZone.offsetHours));
    final hour = targetTime.hour.toString().padLeft(2, '0');
    final minute = targetTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${_timeZone.code}';
  }

  void _showTimeZonePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppBottomSheet(
        title: 'Pilih Zona Waktu',
        children: [
          Text(
            'Zona Waktu Aktif',
            style: CreateQuizTextStyles.fieldLabel,
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBorder,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<IndonesiaTimeZone>(
                value: _timeZone,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary,
                ),
                items: IndonesiaTimeZone.values.map((tz) {
                  return DropdownMenuItem<IndonesiaTimeZone>(
                    value: tz,
                    child: Row(
                      children: [
                        Text(
                          tz.code,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            '— ${tz.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    Navigator.of(ctx).pop();
                    setState(() => _timeZone = selected);
                    widget.onTimeZoneChanged?.call(selected);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'Pilihan Cepat',
            style: CreateQuizTextStyles.fieldLabel,
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space2,
            children: IndonesiaTimeZone.values.map((tz) {
              final isSelected = tz == _timeZone;
              return InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _timeZone = tz);
                  widget.onTimeZoneChanged?.call(tz);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primaryBorder,
                    ),
                  ),
                  child: Text(
                    tz.code,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showTimeZonePicker,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                _formatTime(),
                style: AppTextStyles.bodyMeta.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
