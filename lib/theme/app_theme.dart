/// Central design tokens (barrel).
///
/// Setiap widget dan halaman WAJIB membaca warna, tipografi, spacing,
/// radius, dan shadow dari file ini. Jangan menulis nilai warna,
/// font, atau spacing secara hardcoded di file lain.
///
/// Implementasi dipisah menjadi modul token per-domain di folder ini.
/// Import barrel ini untuk mengakses semuanya:
///
/// ```dart
/// import '../theme/app_theme.dart';
/// ```
library;

export 'app_buttons.dart';
export 'app_colors.dart';
export 'app_gradients.dart';
export 'app_metrics.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_theme_data.dart';
export 'app_typography.dart';
export 'create_quiz_theme.dart';
export 'profile_theme.dart';
