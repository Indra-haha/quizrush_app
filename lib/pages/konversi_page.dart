import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/app_tab_bar.dart';
import '../helpers/konversi_format.dart';

class KonversiPage extends StatelessWidget {
  const KonversiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppHeaderBar(
          title: 'Konversi Kalender',
          bottom: const AppTabBar(
            tabs: ['Hijriah', 'Umur', 'Weton', 'Saka Bali'],
          ),
        ),
        body: TabBarView(
          children: [
            _TanggalTab(
              judul: 'Pilih Tanggal Masehi',
              labelHasil: 'Tanggal Hijriah',
              konversi: CalendarUtils.formatHijriah,
            ),
            const _UmurTab(),
            _TanggalTab(
              judul: 'Pilih Tanggal',
              labelHasil: 'Weton',
              konversi: CalendarUtils.wetonDari,
            ),
            _TanggalTab(
              judul: 'Pilih Tanggal',
              labelHasil: '',
              konversi: CalendarUtils.formatSakaBali,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB TANGGAL ====================

class _TanggalTab extends StatefulWidget {
  final String judul;
  final String labelHasil;
  final String Function(DateTime) konversi;

  const _TanggalTab({
    required this.judul,
    required this.labelHasil,
    required this.konversi,
  });

  @override
  State<_TanggalTab> createState() => _TanggalTabState();
}

class _TanggalTabState extends State<_TanggalTab> {
  DateTime? tanggal;
  String? hasil;

  Future<void> pilihTanggal() async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1500),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        tanggal = result;
        hasil = widget.konversi(result);
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
            onPressed: pilihTanggal,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              tanggal == null
                  ? widget.judul
                  : '${tanggal!.day}/${tanggal!.month}/${tanggal!.year}',
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          if (hasil != null)
            Card(
              color: AppColors.surfaceSoft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space8),
                child: Text(
                  widget.labelHasil.isEmpty
                      ? hasil!
                      : '${widget.labelHasil}:\n$hasil',
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

// ==================== TAB UMUR ====================

class _UmurTab extends StatefulWidget {
  const _UmurTab();

  @override
  State<_UmurTab> createState() => _UmurTabState();
}

class _UmurTabState extends State<_UmurTab> {
  DateTime? lahir;
  Map<String, int>? umur;

  Future<void> pilihTanggal() async {
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
        lahir = tanggal;
        umur = CalendarUtils.hitungUmur(tanggal, DateTime.now());
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
            onPressed: pilihTanggal,
            icon: const Icon(Icons.cake),
            label: Text(
              lahir == null
                  ? 'Pilih Tanggal Lahir'
                  : '${lahir!.day}/${lahir!.month}/${lahir!.year}',
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          if (umur != null)
            Card(
              color: AppColors.surfaceSoft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space8),
                child: Text(
                  'Umur kamu:\n'
                  '${umur!['tahun']} tahun, '
                  '${umur!['bulan']} bulan, '
                  '${umur!['hari']} hari\n'
                  '${umur!['jam']} jam, '
                  '${umur!['menit']} menit, '
                  '${umur!['detik']} detik',
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
