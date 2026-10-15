import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tab konversi kalender generik: pilih tanggal lalu tampilkan hasil fungsi
/// konversi yang diberikan.
class KonversiTanggalTab extends StatefulWidget {
  final String judul;
  final String labelHasil;
  final String Function(DateTime) konversi;

  const KonversiTanggalTab({
    super.key,
    required this.judul,
    required this.labelHasil,
    required this.konversi,
  });

  @override
  State<KonversiTanggalTab> createState() => _KonversiTanggalTabState();
}

class _KonversiTanggalTabState extends State<KonversiTanggalTab> {
  DateTime? _tanggal;
  String? _hasil;

  Future<void> _pilihTanggal() async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        _tanggal = result;
        _hasil = widget.konversi(result);
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
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _tanggal == null
                  ? widget.judul
                  : '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}',
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          if (_hasil != null)
            Card(
              color: AppColors.surfaceSoft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space8),
                child: Text(
                  widget.labelHasil.isEmpty
                      ? _hasil!
                      : '${widget.labelHasil}:\n$_hasil',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
