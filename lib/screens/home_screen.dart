import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../screens/quick_add_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final userName = context.select<AuthProvider, String>((a) => a.userName);
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_greeting()}, ${userName.isEmpty ? 'Chef' : userName}', style: textStyles.headlineMedium?.copyWith(color: theme.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('What\'s on the menu today?', style: textStyles.bodyMedium?.copyWith(color: theme.secondaryText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    label: 'Settings',
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.settings),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.isEmpty ? 'C' : userName[0].toUpperCase(),
                          style: TextStyle(color: theme.colorScheme.surface, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.add_shopping_cart_rounded,
                      iconBg: theme.colorScheme.surface,
                      iconColor: theme.colorScheme.primary,
                      title: 'Add Items',
                      subtitle: 'Quickly tap or speak items',
                      onTap: () => showQuickAddSheet(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.restaurant_menu_rounded,
                      iconBg: theme.colorScheme.surface,
                      iconColor: theme.colorScheme.secondary,
                      title: 'Add a Dish',
                      subtitle: 'Generate list from recipes',
                      onTap: () => context.push(AppRoutes.addDish),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.receipt_long_rounded,
                      iconBg: theme.colorScheme.surface,
                      iconColor: theme.colorScheme.onSurface,
                      title: 'My Lists',
                      subtitle: 'Manage your active lists',
                      onTap: () => context.push('/my-lists'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.group_add_rounded,
                      iconBg: theme.colorScheme.surface,
                      iconColor: theme.accent,
                      title: 'Shared',
                      subtitle: 'Collaborate with others',
                      onTap: () => context.push('/shared'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final allLists = dataProvider.allLists;
                  final totalSpending = allLists.fold<double>(0, (sum, l) => sum + l.totalPrice);
                  final boughtSpending = allLists.fold<double>(0, (sum, l) => sum + l.boughtPrice);
                  // Build per-category spending for the bar chart
                  final categoryTotals = <String, double>{};
                  for (final list in allLists) {
                    for (final item in list.items) {
                      categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + (item.price * item.qty);
                    }
                  }
                  final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  final topCategories = sortedCategories.take(7).toList();
                  final maxVal = topCategories.isEmpty ? 1.0 : topCategories.first.value;

                  return Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spending Overview', style: textStyles.titleSmall?.copyWith(color: theme.primaryText)),
                            Text('\$${totalSpending.toStringAsFixed(2)} total', style: textStyles.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('\$${boughtSpending.toStringAsFixed(2)} purchased so far', style: textStyles.bodySmall?.copyWith(color: theme.secondaryText)),
                        const SizedBox(height: AppSpacing.md),
                        if (topCategories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Text('Add items to see spending breakdown', style: textStyles.bodySmall?.copyWith(color: theme.hint), textAlign: TextAlign.center),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxVal * 1.2,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= topCategories.length) return const SizedBox.shrink();
                                        final label = topCategories[idx].key;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: SizedBox(
                                            width: 40,
                                            child: Text(label, style: TextStyle(color: theme.secondaryText, fontSize: 9), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(topCategories.length, (i) => _makeGroupData(i, topCategories[i].value, theme.colorScheme.primary)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Lists', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
                  TextButton(
                    onPressed: () => context.push('/my-lists'),
                    child: Text('See All', style: textStyles.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...dataProvider.myLists.take(3).map((list) {
                return _buildListPreview(
                  context,
                  icon: list.isShared ? Icons.local_pizza_rounded : Icons.eco_rounded,
                  color: list.isShared ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  name: list.title,
                  details: '${list.items.length} items • ${list.isShared ? 'Shared' : 'Personal'}',
                  price: '\$${list.totalPrice.toStringAsFixed(2)}',
                  onTap: () {
                    dataProvider.setActiveList(list.id);
                    context.push(AppRoutes.activeList);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                button: true,
                label: 'Unlock Smart AI',
                child: InkWell(
                  onTap: () => context.push(AppRoutes.addDish),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.auto_awesome, color: theme.colorScheme.surface, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Unlock Smart AI', style: textStyles.bodyLarge?.copyWith(color: theme.primaryText, fontWeight: FontWeight.bold)),
                              Text('Get precise ingredients for any dish instantly.', style: textStyles.bodySmall?.copyWith(color: theme.secondaryText)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: FloatingActionButton.small(
          heroTag: 'home_voice_add_fab',
          tooltip: 'Quick add',
          onPressed: () => showQuickAddSheet(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  BarChartGroupData _makeGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryText)),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.secondaryText), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPreview(BuildContext context, {required IconData icon, required Color color, required String name, required String details, required String price, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open $name',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
                    Text(details, style: theme.textTheme.labelSmall?.copyWith(color: theme.secondaryText)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryText, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: theme.hint, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
