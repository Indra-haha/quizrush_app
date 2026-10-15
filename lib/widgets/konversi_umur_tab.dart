import 'package:flutter/material.dart';

import '../helpers/konversi_format.dart';
import '../theme/app_theme.dart';

/// Tab "Umur": pilih tanggal lahir lalu tampilkan rentang umur.
class KonversiUmurTab extends StatefulWidget {
  const KonversiUmurTab({super.key});

  @override
  State<KonversiUmurTab> createState() => _KonversiUmurTabState();
}

class _KonversiUmurTabState extends State<KonversiUmurTab> {
  DateTime? _lahir;
  Map<String, int>? _umur;

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1500),
      lastDate: now,
    );

    if (result != null) {
      final tanggal = DateTime(result.year, result.month, result.day);

      setState(() {
        _lahir = tanggal;
        _umur = CalendarUtils.hitungUmur(tanggal, DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.cake),
            label: Text(
              _lahir == null
                  ? 'Pilih Tanggal Lahir'
                  : '${_lahir!.day}/${_lahir!.month}/${_lahir!.year}',
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          if (_umur != null)
            Card(
              color: AppColors.surfaceSoft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space8),
                child: Text(
                  'Umur kamu:\n'
                  '${_umur!['tahun']} tahun, '
                  '${_umur!['bulan']} bulan, '
                  '${_umur!['hari']} hari\n'
                  '${_umur!['jam']} jam, '
                  '${_umur!['menit']} menit, '
                  '${_umur!['detik']} detik',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
