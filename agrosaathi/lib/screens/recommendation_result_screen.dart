import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/recommendation_model.dart';
import '../services/localization_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import 'crop_setup_screen.dart';

/// Detailed Crop Recommendation Results Screen.
/// Owned by Person A. Multi-language and overflow safe.
class RecommendationResultScreen extends StatelessWidget {
  final RecommendationInput input;
  final List<CropRecommendationOutput> results;
  final bool isFromHistory;

  const RecommendationResultScreen({
    super.key,
    required this.input,
    required this.results,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, langCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LocalizationService.tr('results_title')),
          ),
          body: results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 54, color: AppColors.textDisabled),
                        const SizedBox(height: 16),
                        const Text(
                          'No matching crops found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting soil type or water availability criteria.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Back to Form',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary banner
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppColors.primaryLight,
                      borderColor: AppColors.primary.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.tr('results_subtitle'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${input.district} • ${input.season.toUpperCase()} • ${input.soilType.toUpperCase()} • ${input.farmSizeAcres} Acres',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ranked Crop Cards
                    ...results.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final crop = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Rank + Crop Name + Match Score
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: rank == 1 ? AppColors.secondary : AppColors.primaryLight,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '#$rank',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: rank == 1 ? Colors.white : AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            crop.cropName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip.score(crop.suitabilityScore),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Badges Row
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StatusChip.risk(crop.riskLevel),
                                  StatusChip.water(crop.waterRequirement),
                                  StatusChip(
                                    label: '${crop.growthDurationDays} ${LocalizationService.tr('days')}',
                                    icon: Icons.schedule,
                                    backgroundColor: AppColors.background,
                                    textColor: AppColors.textSecondary,
                                    borderColor: AppColors.cardBorder,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Financial Breakdown Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            LocalizationService.tr('estimated_profit'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(crop.estimatedProfit),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFinanceDetail(
                                            LocalizationService.tr('est_yield'),
                                            '${crop.estimatedYieldQuintal.toStringAsFixed(1)} Qt',
                                          ),
                                        ),
                                        Container(height: 24, width: 1, color: AppColors.cardBorder),
                                        Expanded(
                                          child: _buildFinanceDetail(
                                            LocalizationService.tr('est_revenue'),
                                            currencyFormatter.format(crop.estimatedRevenue),
                                          ),
                                        ),
                                        Container(height: 24, width: 1, color: AppColors.cardBorder),
                                        Expanded(
                                          child: _buildFinanceDetail(
                                            LocalizationService.tr('est_cost'),
                                            currencyFormatter.format(crop.estimatedCost),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Sowing window & Agronomic Tips
                              Row(
                                children: [
                                  const Icon(Icons.event_available, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${LocalizationService.tr('sowing_window')}: ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      crop.sowingWindow,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      crop.agronomicTips,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action: Launch Growth Planner
                              AppButton(
                                text: LocalizationService.tr('btn_start_growth_plan'),
                                icon: Icons.add_task,
                                type: AppButtonType.primary,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CropSetupScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFinanceDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
