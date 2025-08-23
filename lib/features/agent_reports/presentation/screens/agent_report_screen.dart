import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/agent_report_provider.dart';
import '../models/agent_report.dart';

class AgentReportScreen extends ConsumerStatefulWidget {
  const AgentReportScreen({super.key});

  @override
  ConsumerState<AgentReportScreen> createState() => _AgentReportScreenState();
}

class _AgentReportScreenState extends ConsumerState<AgentReportScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last Month', 'This Year'];
  DateTime? _lastRefreshed;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(agentReportProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Report'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleLarge.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _lastRefreshed = DateTime.now();
              });
              ref.refresh(agentReportProvider(_selectedPeriod));
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                        ),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(
                              period,
                              style: AppTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_lastRefreshed != null) ...[
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Last updated: ${DateFormat('MMM dd, HH:mm').format(_lastRefreshed!)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Report Content
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _lastRefreshed = DateTime.now();
                  });
                  ref.refresh(agentReportProvider(_selectedPeriod));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppTheme.textHintColor),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'Failed to load report',
                            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            error.toString(),
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          PrimaryButton(
                            label: 'Retry',
                            onPressed: () {
                              ref.refresh(agentReportProvider(_selectedPeriod));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              data: (report) => RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _lastRefreshed = DateTime.now();
                  });
                  ref.refresh(agentReportProvider(_selectedPeriod));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing16,
                    AppTheme.spacing16,
                    AppTheme.spacing16,
                    AppTheme.spacing32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Cards
                      _buildSummaryCards(report),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AgentReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacing12,
          mainAxisSpacing: AppTheme.spacing12,
          childAspectRatio: 1.4,
          children: [
            _buildSummaryCard(
              'Total Sales',
              '${NumberFormat('#,##0').format(report.totalSales)} RWF',
              Icons.trending_up,
              AppTheme.successColor,
            ),
            _buildSummaryCard(
              'Total Collections',
              '${NumberFormat('#,##0').format(report.totalCollections)} RWF',
              Icons.account_balance_wallet,
              AppTheme.primaryColor,
            ),
            _buildSummaryCard(
              'Customers Added',
              '${report.customersAdded}',
              Icons.person_add,
              AppTheme.warningColor,
            ),
            _buildSummaryCard(
              'Suppliers Added',
              '${report.suppliersAdded}',
              Icons.business,
              AppTheme.snackbarInfoColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Flexible(
            child: Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Flexible(
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }






}
