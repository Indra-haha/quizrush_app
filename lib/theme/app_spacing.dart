/// Spacing scale and semantic aliases.
///
/// Setiap widget dan halaman WAJIB membaca spacing dari sini. Jangan menulis
/// nilai spacing secara hardcoded di file lain.
class AppSpacing {
  AppSpacing._();

  // --- numeric scale (every value used anywhere in the app) ---
  static const none = 0.0;
  static const space1 = 2.0;
  static const space2 = 4.0;
  static const space3 = 6.0;
  static const space4 = 8.0;
  static const space5 = 10.0;
  static const space6 = 12.0;
  static const space7 = 14.0;
  static const space8 = 16.0;
  static const space9 = 20.0;
  static const space10 = 24.0;
  static const space11 = 28.0;
  static const space12 = 32.0;
  static const space13 = 40.0;
  static const space14 = 48.0;
  static const space15 = 15.0;
  static const space16 = 25.0;

  // --- clearances for floating UI / scroll views ---
  static const fabClearance = 96.0;
  static const scrollClearance = 112.0;
  static const scrollClearanceLarge = 160.0;
  static const bottomListClearance = 80.0;
  static const podiumTopGap = 60.0;

  // --- semantic aliases ---
  static const xxs = space2;
  static const xs = space4;
  static const sm = space6;
  static const md = space8;
  static const lg = space9;
  static const xl = space10;
  static const xxl = space12;
}
