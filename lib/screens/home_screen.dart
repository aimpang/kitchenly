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
    final userName = context.watch<AuthProvider>().userName;
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good Morning, ${userName.isEmpty ? 'Chef' : userName}', style: textStyles.headlineMedium?.copyWith(color: const Color(0xFF4A3728))),
                      Text('What\'s on the menu today?', style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push(AppRoutes.settings),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC4785A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isEmpty ? 'C' : userName[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFFDF6E3), fontSize: 20, fontWeight: FontWeight.bold),
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
                      iconBg: const Color(0xFFFDF6E3),
                      iconColor: const Color(0xFFC4785A),
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
                      iconBg: const Color(0xFFFDF6E3),
                      iconColor: const Color(0xFF808055),
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
                      iconBg: const Color(0xFFFDF6E3),
                      iconColor: const Color(0xFF6B4423),
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
                      iconBg: const Color(0xFFFDF6E3),
                      iconColor: const Color(0xFFF08080),
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
                  final allLists = [...dataProvider.myLists, ...dataProvider.sharedLists];
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
                      color: const Color(0xFFFDF6E3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8DFD0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spending Overview', style: textStyles.titleSmall?.copyWith(color: const Color(0xFF4A3728))),
                            Text('\$${totalSpending.toStringAsFixed(2)} total', style: textStyles.labelLarge?.copyWith(color: const Color(0xFFC4785A))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('\$${boughtSpending.toStringAsFixed(2)} purchased so far', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                        const SizedBox(height: AppSpacing.md),
                        if (topCategories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Text('Add items to see spending breakdown', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFBDB2A7)), textAlign: TextAlign.center),
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
                                          child: Text(label.length > 5 ? label.substring(0, 5) : label, style: const TextStyle(color: Color(0xFF8C7E6F), fontSize: 9)),
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
                                barGroups: List.generate(topCategories.length, (i) => _makeGroupData(i, topCategories[i].value)),
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
                  Text('Recent Lists', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
                  TextButton(
                    onPressed: () => context.push('/my-lists'),
                    child: Text('See All', style: textStyles.labelLarge?.copyWith(color: const Color(0xFFC4785A))),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...dataProvider.myLists.take(3).map((list) {
                return _buildListPreview(
                  context,
                  icon: list.isShared ? Icons.local_pizza_rounded : Icons.eco_rounded,
                  color: list.isShared ? const Color(0xFFC4785A) : const Color(0xFF808055),
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
              InkWell(
                onTap: () => context.push(AppRoutes.addDish),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFC4785A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC4785A),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFFDF6E3), size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unlock Smart AI', style: textStyles.bodyLarge?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.bold)),
                            Text('Get precise ingredients for any dish instantly.', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFFC4785A), size: 16),
                    ],
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

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFC4785A),
          width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8DFD0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4423).withValues(alpha: 0.1),
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
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8C7E6F)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildListPreview(BuildContext context, {required IconData icon, required Color color, required String name, required String details, required String price, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFE8DFD0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFFFFBF5), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600)),
                  Text(details, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF8C7E6F))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right, color: Color(0xFFBDB2A7), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
