import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedStore = 'Supermarket';
  String _selectedCity = 'San Francisco, CA';
  final _priceSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load the local price book (used for estimating totals) once the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DataProvider>().ensurePriceBookLoaded();
    });
  }

  @override
  void dispose() {
    _priceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName;
    final userEmail = authProvider.userEmail;
    final isPremium = authProvider.isPremium;
    final dataProvider = context.watch<DataProvider>();
    final search = _priceSearchController.text.trim().toLowerCase();
    final priceEntries = dataProvider.priceBookEntries.where((e) {
      if (search.isEmpty) return true;
      return e.name.toLowerCase().contains(search) || e.category.toLowerCase().contains(search);
    }).toList();

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
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
                    onPressed: () => context.pop(),
                  ),
                  Text('Settings', style: textStyles.titleLarge?.copyWith(color: theme.primaryText)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isEmpty ? 'C' : userName[0].toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.surface, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName.isEmpty ? 'Chef' : userName, style: textStyles.headlineSmall?.copyWith(color: theme.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: AppSpacing.xs),
                          Text(userEmail.isEmpty ? 'user@example.com' : userEmail, style: textStyles.bodyMedium?.copyWith(color: theme.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              authProvider.togglePremium();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.isPremium ? 'Premium activated!' : 'Switched to free plan'),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPremium ? theme.colorScheme.secondary : theme.hint,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(isPremium ? 'Premium Member' : 'Free Plan', style: textStyles.labelSmall?.copyWith(color: theme.colorScheme.surface)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Price Estimation Basis', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Your City', style: textStyles.labelMedium?.copyWith(color: theme.secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          items: ['San Francisco, CA', 'New York, NY', 'Austin, TX', 'Chicago, IL']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: textStyles.bodyMedium?.copyWith(color: theme.primaryText))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCity = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Preferred Store Type', style: textStyles.labelMedium?.copyWith(color: theme.secondaryText)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildStoreChip('Supermarket', Icons.local_mall_rounded),
                        _buildStoreChip('Organic/Eco', Icons.eco_rounded),
                        _buildStoreChip('Discount', Icons.payments_rounded),
                        _buildStoreChip('Local Market', Icons.store_rounded),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outlined, color: theme.colorScheme.secondary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'We use your location and store preference to provide more accurate price totals for your grocery lists.',
                            style: textStyles.bodySmall?.copyWith(color: theme.secondaryText, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Price Book', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search items (e.g. eggs, milk...)',
                              prefixIcon: Icon(Icons.search_rounded, color: theme.secondaryText),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        InkWell(
                          onTap: () => _showEditPriceBookEntrySheet(context, initial: null),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                            alignment: Alignment.center,
                            child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outlined, color: theme.colorScheme.secondary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Prices are stored locally on this device for now. When you add items manually, we\u2019ll use these values to estimate totals.',
                            style: textStyles.bodySmall?.copyWith(color: theme.secondaryText, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!dataProvider.priceBookLoaded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Loading price book\u2026', style: textStyles.bodySmall?.copyWith(color: theme.secondaryText)),
                          ],
                        ),
                      )
                    else if (priceEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No matches. Tap + to add an item.', style: textStyles.bodySmall?.copyWith(color: theme.secondaryText)),
                      )
                    else
                      ...priceEntries.take(12).map((e) => _PriceBookRow(
                            entry: e,
                            onTap: () => _showEditPriceBookEntrySheet(context, initial: e),
                            onDelete: () => context.read<DataProvider>().removePriceBookEntry(e.name),
                          )),
                    if (priceEntries.length > 12)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text('Showing 12 of ${priceEntries.length}. Refine your search to find more.', style: textStyles.labelSmall?.copyWith(color: theme.hint)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Account & App', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
              const SizedBox(height: AppSpacing.md),
              _buildSettingsItem(Icons.notifications_none_rounded, 'Notifications', subtitle: 'Reminders for shared lists', context: context, onTap: () => _showComingSoon('Notification settings')),
              _buildSettingsItem(Icons.group_add_rounded, 'Collaboration', subtitle: 'Manage who can see your lists', context: context, onTap: () => context.push(AppRoutes.share)),
              _buildSettingsItem(Icons.security_rounded, 'Privacy & Security', context: context, onTap: () => _showComingSoon('Privacy & Security')),
              _buildSettingsItem(Icons.help_outline_rounded, 'Help Center', context: context, onTap: () => _showComingSoon('Help Center')),
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go(AppRoutes.login);
                },
                icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                label: Text('Sign Out', style: textStyles.titleMedium?.copyWith(color: theme.colorScheme.error)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Column(
                  children: [
                    Text('Kitchenly v1.0.0', style: textStyles.labelSmall?.copyWith(color: theme.hint)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Crafted for a calm kitchen', style: textStyles.labelSmall?.copyWith(color: theme.hint, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), backgroundColor: theme.colorScheme.primary),
    );
  }

  Widget _buildStoreChip(String label, IconData icon) {
    final theme = Theme.of(context);
    final selected = _selectedStore == label;
    return InkWell(
      onTap: () => setState(() => _selectedStore = label),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm, bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? theme.colorScheme.onPrimary : theme.secondaryText),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? theme.colorScheme.onPrimary : theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? subtitle, required BuildContext context, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
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
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.secondaryText)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hint, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPriceBookEntrySheet(BuildContext context, {required PriceBookEntry? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final priceController = TextEditingController(text: initial == null ? '' : initial.unitPrice.toStringAsFixed(2));
    String category = initial?.category ?? 'Other';

    Future<void> save() async {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text.trim());
      if (name.isEmpty || price == null || price.isNaN || price.isInfinite || price < 0) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Enter a valid name and price.'), backgroundColor: theme.primaryText),
        );
        return;
      }
      await context.read<DataProvider>().upsertPriceBookEntry(name: name, unitPrice: price, category: category);
      if (context.mounted) context.pop();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final theme = Theme.of(context);
              final textStyles = theme.textTheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(initial == null ? 'Add Price' : 'Edit Price', style: textStyles.titleLarge?.copyWith(color: theme.primaryText)),
                      IconButton(icon: Icon(Icons.close_rounded, color: theme.secondaryText), onPressed: () => ctx.pop()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: theme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: theme.dividerColor)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Unit price (USD)',
                      prefixText: '\$',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: theme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: theme.dividerColor)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Category', style: textStyles.labelMedium?.copyWith(color: theme.secondaryText)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Meat', 'Seafood', 'Other'].map((c) {
                      final selected = category == c;
                      return InkWell(
                        onTap: () => setSheetState(() => category = c),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
                          ),
                          child: Text(
                            c,
                            style: textStyles.labelLarge?.copyWith(color: selected ? theme.colorScheme.onPrimary : theme.primaryText, fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  InkWell(
                    onTap: save,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                      alignment: Alignment.center,
                      child: Text('Save', style: textStyles.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PriceBookRow extends StatelessWidget {
  final PriceBookEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PriceBookRow({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: textStyles.bodyLarge?.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text(entry.category, style: textStyles.labelSmall?.copyWith(color: theme.secondaryText)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('\$${entry.unitPrice.toStringAsFixed(2)}', style: textStyles.titleMedium?.copyWith(color: theme.primaryText, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: Icon(Icons.delete_outline_rounded, color: theme.secondaryText), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
