import 'package:flutter/material.dart';

import '../helpers/konversi_format.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/konversi_tanggal_tab.dart';
import '../widgets/konversi_umur_tab.dart';

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
            KonversiTanggalTab(
              judul: 'Pilih Tanggal Masehi',
              labelHasil: 'Tanggal Hijriah',
              konversi: CalendarUtils.formatHijriah,
            ),
            const KonversiUmurTab(),
            KonversiTanggalTab(
              judul: 'Pilih Tanggal',
              labelHasil: 'Weton',
              konversi: CalendarUtils.wetonDari,
            ),
            KonversiTanggalTab(
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
