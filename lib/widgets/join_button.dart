import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol aksi besar "GABUNG" pada halaman gabung room: gradient brand,
/// radius kecil, dan label Montserrat besar.
class JoinButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  const JoinButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: ShapeDecoration(
            gradient: AppGradients.joinButton,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xs),
            shadows: AppShadows.softLift,
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.xs,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
              child: Center(
                child: loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: AppSpacing.space5,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                          if (loadingLabel != null)
                            Flexible(
                              child: Text(
                                loadingLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.buttonLarge,
                              ),
                            ),
                        ],
                      )
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.joinButtonLabel,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
