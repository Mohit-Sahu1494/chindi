import 'package:flutter/material.dart';
import '../../data/models/app_version_model.dart';
import '../theme/app_theme.dart';
import 'gold_button.dart';

class UpdateDialog extends StatelessWidget {
  final AppVersionModel versionInfo;
  final VoidCallback onUpdate;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isMandatory = versionInfo.isMandatory;

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.25),
                      AppColors.surfaceElevated,
                    ],
                  ),
                  border: Border.all(color: AppColors.goldLight, width: 1.5),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  size: 32,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                versionInfo.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textIvory,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 12),

              // Version Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      'Aapka: v${AppVersionModel.currentVersionName}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.gold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Naya: v${versionInfo.latestVersion}',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Release Notes Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.new_releases_outlined, size: 15, color: AppColors.goldLight),
                        SizedBox(width: 6),
                        Text(
                          'Kya Naya Hai:',
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      versionInfo.releaseNotes,
                      style: const TextStyle(
                        color: AppColors.textIvory,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              GoldButton(
                label: 'ABHI UPDATE KAREIN',
                icon: Icons.download_rounded,
                onPressed: () {
                  onUpdate();
                  if (!isMandatory) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),

              if (!isMandatory) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text(
                    'Baad mein karenge (Later)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
