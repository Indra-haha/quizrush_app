import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bantuan"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          children: [
            const Icon(
              Icons.help_center,
              size: AppIconSize.display,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.space6),

            Text(
              "Panduan Penggunaan Aplikasi",
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1Strong,
            ),

            const SizedBox(height: AppSpacing.space4),

            Text(
              "Berikut adalah panduan singkat penggunaan setiap fitur yang tersedia pada aplikasi.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.space10),

            _buildHelpCard(
              icon: Icons.login,
              title: "Login / Registrasi",
              description: "Masuk atau buat akun menggunakan NIM dan password.",
            ),

            _buildHelpCard(
              icon: Icons.home,
              title: "Home",
              description:
                  "Melihat menu utama dan quiz yang tersedia pada aplikasi.",
            ),

            _buildHelpCard(
              icon: Icons.quiz,
              title: "Quiz",
              description:
                  "Cari dan ikuti quiz menggunakan judul quiz atau kode room yang diberikan.",
            ),

            _buildHelpCard(
              icon: Icons.add_box,
              title: "Buat Quiz",
              description:
                  "Buat quiz sendiri dengan menambahkan pertanyaan, pilihan jawaban, dan informasi quiz.",
            ),

            _buildHelpCard(
              icon: Icons.calculate,
              title: "Kalkulator",
              description:
                  "Gunakan fitur kalkulator untuk melakukan perhitungan matematika serta pengecekan bilangan ganjil dan genap.",
            ),

            _buildHelpCard(
              icon: Icons.calendar_month,
              title: "Konversi",
              description:
                  "Pilih tanggal untuk melihat hasil konversi Hijriah, perhitungan umur, weton Jawa, dan tahun Saka Bali.",
            ),

            _buildHelpCard(
              icon: Icons.logout,
              title: "Logout",
              description:
                  "Keluar dari akun yang sedang digunakan dan kembali ke halaman login.",
            ),

            const SizedBox(height: AppSpacing.space9),

            const Divider(),

            const SizedBox(height: AppSpacing.space5),

            Text(
              "Jika mengalami kendala saat menggunakan aplikasi, silakan hubungi administrator atau pengembang aplikasi.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: AppElevation.medium,
      margin: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: AppTextStyles.cardTitle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Text(description),
        ),
      ),
    );
  }
}
