import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_metrics.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Marker shape for each answer option in the Create Quiz editor.
enum CreateQuizAnswerShape { triangle, diamond, square, circle }

/// Design tokens for the Create Quiz flow.
///
/// Semua warna, ukuran, dekorasi, dan tipografi khusus halaman Create Quiz
/// dikelompokkan di sini. Page dan widget hanya boleh membaca token ini.
class CreateQuizTextStyles {
  CreateQuizTextStyles._();

  static final headerTitle = AppTextStyles.heading6.copyWith(
    color: AppColors.textPrimary,
    height: 1,
  );

  static final saveAction = AppTextStyles.labelStrong.copyWith(
    color: AppColors.onPrimaryMuted,
  );

  static final fieldLabel = AppTextStyles.fieldLabel;
  static final fieldValue = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
  );
  static final fieldHint = AppTextStyles.quizFieldHint;
  static final category = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
  );

  static final suggest = AppTextStyles.heading6.copyWith(
    color: AppColors.textOnPrimary,
    fontWeight: FontWeight.w600,
    height: 1,
  );

  static final addQuestion = AppTextStyles.heading6.copyWith(
    color: AppColors.quizAction,
    height: 1.60,
  );

  static final questionPill = AppTextStyles.fieldLabel.copyWith(
    color: AppColors.textOnPrimary,
  );
  static final deleteAction = AppTextStyles.labelStrongError;
  static final questionInput = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
    height: 2,
    fontWeight: AppTextStyles.fieldLabel.fontWeight,
  );
  static final questionHint = AppTextStyles.quizFieldHint.copyWith(height: 2);

  static final answerInput = AppTextStyles.fieldValue.copyWith(
    color: AppColors.onPrimaryMuted,
    fontWeight: FontWeight.w600,
  );
  static final answerHint = AppTextStyles.fieldValue.copyWith(
    color: AppColors.onPrimarySubtle,
  );

  static final subLabel = AppTextStyles.labelStrong.copyWith(
    color: AppColors.textSecondary,
  );
  static final pointsHint = AppTextStyles.bodySmall.copyWith(
    color: AppColors.textSecondary,
  );
  static final pointsInput = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
  );
  static final pointsPlaceholder = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
  );
  static final pointsSuffix = AppTextStyles.fieldValue.copyWith(
    color: AppColors.textSecondary,
  );

  static final duration = AppTextStyles.fieldLabel;
  static final durationSelected = AppTextStyles.fieldLabel.copyWith(
    color: AppColors.textOnPrimary,
  );

  static final coverLabel = AppTextStyles.labelStrong.copyWith(
    color: AppColors.textSecondary,
    letterSpacing: 0.6,
  );
  static final coverCaption = AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textSecondary,
  );
  static final coverProgress = AppTextStyles.button.copyWith(
    color: AppColors.textOnPrimary,
  );
  static final coverError = AppTextStyles.button.copyWith(
    color: AppColors.textOnPrimary,
  );
  static final suggestSheetBody = AppTextStyles.bodyMedium.copyWith(
    color: AppColors.textSecondary,
  );
}

/// Header, form fields, category, and primary actions of the Create Quiz page.
class CreateQuizPageStyles {
  CreateQuizPageStyles._();

  static const contentMaxWidth = 896.0;

  static const pagePadding = EdgeInsets.fromLTRB(
    AppSpacing.space9,
    AppSpacing.space10,
    AppSpacing.space9,
    AppSpacing.space13,
  );

  static const headerBackground = AppColors.surface;
  static const headerElevation = AppElevation.hairline;
  static final headerShadowColor = AppShadows.navBar.first.color;

  static const saveButtonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space10,
    vertical: AppSpacing.space4,
  );
  static const saveButtonShape = StadiumBorder();
  static const saveButtonDecoration = ShapeDecoration(
    gradient: AppGradients.authAction,
    shape: StadiumBorder(),
    shadows: AppShadows.authAction,
  );
  static const saveDisabledOpacity = 0.6;
  static const saveProgressSize = 16.0;
  static const saveProgressStroke = 2.0;

  static const fieldContentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space10,
    vertical: AppSpacing.space16,
  );

  static const categoryMaxWidth = 170.0;
  static const categoryPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space9,
    vertical: AppSpacing.space3,
  );
  static const categoryDecoration = ShapeDecoration(
    color: AppColors.fieldBackground,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: AppColors.primaryBorder,
        width: AppBorderWidth.regular,
      ),
      borderRadius: AppRadius.lg,
    ),
  );
  static const categoryGap = AppSpacing.space5;
  static const categoryIconSize = 21.0;

  static const suggestPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space16,
    vertical: AppSpacing.space15,
  );
  static final suggestButton = FilledButton.styleFrom(
    backgroundColor: AppColors.quizAction,
    foregroundColor: AppColors.textOnPrimary,
    shape: const StadiumBorder(),
    padding: suggestPadding,
  );
  static const suggestIconSize = AppIconSize.xxl;
  static const suggestGap = AppSpacing.space8;

  static const addQuestionPadding = EdgeInsets.symmetric(
    vertical: AppSpacing.space12,
  );
  static const addQuestionDecoration = ShapeDecoration(
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: AppColors.primaryBorder,
        width: AppBorderWidth.heavy,
      ),
      borderRadius: AppRadius.xxl,
    ),
  );
  static const addQuestionCircleSize = 48.0;
  static const addQuestionCircleDecoration = BoxDecoration(
    color: AppColors.quizAction,
    shape: BoxShape.circle,
  );
  static const addQuestionIconSize = AppIconSize.lg;
  static const addQuestionGap = AppSpacing.space3;

  static InputDecoration fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: CreateQuizTextStyles.fieldHint,
      filled: true,
      fillColor: AppColors.fieldBackground,
      contentPadding: fieldContentPadding,
      border: fieldBorder(AppColors.primaryBorder),
      enabledBorder: fieldBorder(AppColors.primaryBorder),
      focusedBorder: fieldBorder(AppColors.quizAction),
    );
  }

  static OutlineInputBorder fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: AppRadius.lg,
      borderSide: BorderSide(color: color, width: AppBorderWidth.regular),
    );
  }
}

/// Question card, answer rows, duration selector, and points field.
class CreateQuizQuestionStyles {
  CreateQuizQuestionStyles._();

  static const answerColors = <Color>[
    AppColors.answerRedSolid,
    AppColors.answerBlueSolid,
    AppColors.answerGreenSolid,
    AppColors.answerAmberSolid,
  ];
  static const answerShapes = <CreateQuizAnswerShape>[
    CreateQuizAnswerShape.triangle,
    CreateQuizAnswerShape.diamond,
    CreateQuizAnswerShape.square,
    CreateQuizAnswerShape.circle,
  ];

  static const cardPadding = EdgeInsets.all(AppSpacing.space10);
  static final cardDecoration = BoxDecoration(
    color: AppColors.quizQuestionSurface,
    borderRadius: AppRadius.xxl,
    border: Border.all(
      color: AppColors.primaryBorder,
      width: AppBorderWidth.regular,
    ),
    boxShadow: AppShadows.softCard,
  );

  static const pillPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space8,
    vertical: AppSpacing.space2,
  );
  static const pillShape = StadiumBorder();
  static const deletePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space8,
    vertical: AppSpacing.space2,
  );
  static final deleteButton = TextButton.styleFrom(
    foregroundColor: AppColors.error,
    padding: deletePadding,
  );

  static const questionMinHeight = 100.0;
  static const questionPadding = EdgeInsets.only(
    top: AppSpacing.space4,
    left: AppSpacing.space4,
    right: AppSpacing.space4,
    bottom: AppSpacing.space12,
  );

  static const answerPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space9,
    vertical: AppSpacing.space6,
  );
  static const answerMarkerBoxSize = 24.0;
  static const answerMarkerSize = 20.0;
  static const answerMarkerDiamondSize = 15.0;
  static const answerMarkerTriangleSize = Size(22, 20);
  static const answerMarkerDiamondRotation = -0.79;
  static const answerMarkerColor = AppColors.onPrimaryMuted;
  static const answerMarkerShadowColor = Color(0x0C000000);
  static const answerMarkerShadowElevation = 1.0;
  static const answerMarkerShadow = <BoxShadow>[
    BoxShadow(
      color: answerMarkerShadowColor,
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];
  static const answerGap = AppSpacing.space9;
  static const answerFieldPadding = EdgeInsets.symmetric(
    vertical: AppSpacing.space2,
  );
  static const answerToggleGap = AppSpacing.space4;
  static const toggleSize = Size(44, 24);
  static const checkIconSize = AppIconSize.sm;

  static const durationHadiahGap = AppSpacing.space3;
  static const durationTrackPadding = EdgeInsets.all(AppSpacing.space1);
  static const durationTrackDecoration = ShapeDecoration(
    color: AppColors.fieldBackground,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: AppColors.primaryBorder,
        width: AppBorderWidth.regular,
      ),
      borderRadius: AppRadius.pill,
    ),
  );
  static const durationChipPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space6,
    vertical: AppSpacing.space4,
  );
  static const durationChipShape = StadiumBorder();
  static const durationChipSelectedDecoration = ShapeDecoration(
    color: AppColors.quizAction,
    shape: StadiumBorder(),
  );
  static const durationChipDecoration = ShapeDecoration(
    color: Colors.transparent,
    shape: StadiumBorder(),
  );

  static const labelGap = AppSpacing.space3;
  static const pointsFieldWidth = 100.0;
  static const pointsFieldPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space8,
    vertical: AppSpacing.space5,
  );

  static BoxDecoration toggleDecoration({required bool selected}) {
    return BoxDecoration(
      color: selected ? AppColors.textOnPrimary : AppColors.onPrimaryFaint,
      borderRadius: AppRadius.md,
    );
  }

  static InputDecoration pointsDecoration() {
    return InputDecoration(
      hintText: '20',
      hintStyle: CreateQuizTextStyles.pointsPlaceholder,
      suffixText: 'Pts',
      suffixStyle: CreateQuizTextStyles.pointsSuffix,
      filled: true,
      fillColor: AppColors.fieldBackground,
      contentPadding: pointsFieldPadding,
      border: pointsBorder(AppColors.primaryBorder),
      enabledBorder: pointsBorder(AppColors.primaryBorder),
      focusedBorder: pointsBorder(AppColors.quizAction),
    );
  }

  static OutlineInputBorder pointsBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: AppRadius.pill,
      borderSide: BorderSide(color: color, width: AppBorderWidth.regular),
    );
  }
}

/// Cover picker: placeholder, preview, upload overlay, and error overlay.
class CreateQuizCoverStyles {
  CreateQuizCoverStyles._();

  static const height = 260.0;
  static final decoration = BoxDecoration(
    color: AppColors.quizCoverSurface,
    borderRadius: AppRadius.xxl,
    border: Border.all(
      color: AppColors.quizCoverBorder,
      width: AppBorderWidth.regular,
    ),
  );

  static const placeholderPadding = EdgeInsets.all(AppSpacing.space10);
  static const placeholderIconBox = 64.0;
  static const placeholderIconDecoration = BoxDecoration(
    color: AppColors.onPrimarySoft,
    shape: BoxShape.circle,
  );
  static const placeholderIconSize = AppIconSize.xxl;

  static const removePadding = EdgeInsets.all(AppSpacing.space4);
  static const removeDecoration = BoxDecoration(
    color: AppColors.scrimSoft,
    shape: BoxShape.circle,
  );
  static const removeIconSize = AppIconSize.sm;

  static const progressSize = 32.0;
  static const progressStroke = 3.0;
  static const uploadOverlayDecoration = BoxDecoration(color: AppColors.scrim);
  static const errorOverlayDecoration = BoxDecoration(
    color: AppColors.scrimStrong,
  );
  static const errorIconSize = AppIconSize.lg;
  static const retryIconSize = AppIconSize.body;
  static final retryButton = FilledButton.styleFrom(
    backgroundColor: AppColors.quizAction,
    foregroundColor: AppColors.textOnPrimary,
  );
}
