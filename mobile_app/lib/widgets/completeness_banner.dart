import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/completeness_model.dart';

class CompletenessBanner extends StatelessWidget {
  final ProfileCompletenessModel? completeness;
  final VoidCallback? onRefresh;
  final VoidCallback? onCompleteNow;

  const CompletenessBanner({
    super.key,
    required this.completeness,
    this.onRefresh,
    this.onCompleteNow,
  });

  @override
  Widget build(BuildContext context) {
    if (completeness == null) {
      return const SizedBox.shrink();
    }

    final pct = completeness!.completionPercentage;
    final isEligible = completeness!.isEligibleForApplication || pct == 100;
    final missing = completeness!.missingFields;

    Color progressColor;
    if (pct >= 100) {
      progressColor = AppTheme.accent; // #10B981
    } else if (pct >= 67) {
      progressColor = AppTheme.warning; // #F59E0B
    } else {
      progressColor = AppTheme.error; // #EF4444
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored completeness indicator.
          Container(
            width: 4,
            color: progressColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              pct == 100
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: progressColor,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Profile Completeness: ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$pct%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: progressColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onRefresh != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onRefresh,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryLight
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 14,
                                  color: AppTheme.primaryLight,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Re-check',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (pct == 100)
                    const Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'All mandatory fields complete - you can apply to vacancies!',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isEligible
                                ? 'Eligible to apply for vacancies'
                                : 'Complete all mandatory fields to apply for vacancies',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: missing.map((field) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'Missing: $field',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFCA5A5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
