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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A3728)),
                    onPressed: () => context.pop(),
                  ),
                  Text('Settings', style: textStyles.titleLarge?.copyWith(color: const Color(0xFF4A3728))),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E3),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4423).withValues(alpha: 0.1),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFC4785A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isEmpty ? 'C' : userName[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFFDF6E3), fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName.isEmpty ? 'Chef' : userName, style: textStyles.headlineSmall?.copyWith(color: const Color(0xFF4A3728))),
                          const SizedBox(height: AppSpacing.xs),
                          Text(userEmail.isEmpty ? 'user@example.com' : userEmail, style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              authProvider.togglePremium();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.isPremium ? 'Premium activated!' : 'Switched to free plan'),
                                  backgroundColor: const Color(0xFFC4785A),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPremium ? const Color(0xFF808055) : const Color(0xFFBDB2A7),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(isPremium ? 'Premium Member' : 'Free Plan', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFFDF6E3))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Price Estimation Basis', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E3),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: const Color(0xFFE8DFD0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Your City', style: textStyles.labelMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFE8DFD0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          items: ['San Francisco, CA', 'New York, NY', 'Austin, TX', 'Chicago, IL']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF4A3728)))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCity = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Preferred Store Type', style: textStyles.labelMedium?.copyWith(color: const Color(0xFF8C7E6F))),
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
                        const Icon(Icons.info_outlined, color: Color(0xFF808055), size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'We use your location and store preference to provide more accurate price totals for your grocery lists.',
                            style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Price Book', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E3),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: const Color(0xFFE8DFD0)),
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
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8C7E6F)),
                              filled: true,
                              fillColor: const Color(0xFFFFFBF5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
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
                            decoration: BoxDecoration(color: const Color(0xFFC4785A), borderRadius: BorderRadius.circular(AppRadius.lg)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.add_rounded, color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outlined, color: Color(0xFF808055), size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Prices are stored locally on this device for now. When you add items manually, we’ll use these values to estimate totals.',
                            style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F), height: 1.4),
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
                            Text('Loading price book…', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                          ],
                        ),
                      )
                    else if (priceEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No matches. Tap + to add an item.', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
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
                        child: Text('Showing 12 of ${priceEntries.length}. Refine your search to find more.', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFBDB2A7))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Account & App', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
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
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFD9534F)),
                label: Text('Sign Out', style: textStyles.titleMedium?.copyWith(color: const Color(0xFFD9534F))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Column(
                  children: [
                    Text('Kitchenly v1.0.0', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFBDB2A7))),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Crafted for a calm kitchen', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFBDB2A7), fontStyle: FontStyle.italic)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), backgroundColor: const Color(0xFFC4785A)),
    );
  }

  Widget _buildStoreChip(String label, IconData icon) {
    final selected = _selectedStore == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStore = label),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm, bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC4785A) : const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE8DFD0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF8C7E6F)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF4A3728),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {String? subtitle, required BuildContext context, VoidCallback? onTap}) {
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFFC4785A), size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDB2A7), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPriceBookEntrySheet(BuildContext context, {required PriceBookEntry? initial}) async {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final nameController = TextEditingController(text: initial?.name ?? '');
    final priceController = TextEditingController(text: initial == null ? '' : initial.unitPrice.toStringAsFixed(2));
    String category = initial?.category ?? 'Other';

    Future<void> save() async {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text.trim());
      if (name.isEmpty || price == null || price.isNaN || price.isInfinite || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid name and price.'), backgroundColor: Color(0xFF4A3728)),
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(initial == null ? 'Add Price' : 'Edit Price', style: textStyles.titleLarge?.copyWith(color: const Color(0xFF4A3728))),
                      IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF8C7E6F)), onPressed: () => ctx.pop()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      filled: true,
                      fillColor: const Color(0xFFFDF6E3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
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
                      fillColor: const Color(0xFFFDF6E3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Category', style: textStyles.labelMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Meat', 'Seafood', 'Other'].map((c) {
                      final selected = category == c;
                      return GestureDetector(
                        onTap: () => setSheetState(() => category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFC4785A) : const Color(0xFFFDF6E3),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE8DFD0)),
                          ),
                          child: Text(
                            c,
                            style: textStyles.labelLarge?.copyWith(color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF4A3728), fontWeight: FontWeight.w500),
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
                      decoration: BoxDecoration(color: const Color(0xFFC4785A), borderRadius: BorderRadius.circular(AppRadius.lg)),
                      alignment: Alignment.center,
                      child: Text('Save', style: textStyles.titleMedium?.copyWith(color: const Color(0xFFFFFFFF))),
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
    final textStyles = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFE8DFD0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: textStyles.bodyLarge?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFDF6E3), borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text(entry.category, style: textStyles.labelSmall?.copyWith(color: const Color(0xFF8C7E6F))),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('\$${entry.unitPrice.toStringAsFixed(2)}', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8C7E6F)), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
