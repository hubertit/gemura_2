import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class SavingsStatsCard extends StatelessWidget {
  final Map<String, double> stats;

  const SavingsStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final totalSaved = stats['totalSaved'] ?? 0.0;
    final totalTarget = stats['totalTarget'] ?? 0.0;
    final overallProgress = stats['overallProgress'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.savings,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Total Savings',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20.0),
          
          // Progress Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${overallProgress.toStringAsFixed(0)}%',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              LinearProgressIndicator(
                value: overallProgress / 100,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
          
          const SizedBox(height: 20.0),
          
          // Stats Row
          Row(
            children: [
                              Expanded(
                  child: _buildStatItem(
                    'Saved',
                    NumberFormat('#,##0', 'en_US').format(totalSaved.toInt()) + ' RWF',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Target',
                    NumberFormat('#,##0', 'en_US').format(totalTarget.toInt()) + ' RWF',
                    Icons.flag,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Remaining',
                    NumberFormat('#,##0', 'en_US').format((totalTarget - totalSaved).toInt()) + ' RWF',
                    Icons.schedule,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 