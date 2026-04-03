import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/data_provider.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  String _selectedFilter = 'All Lists';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryList> _applyFilter(List<GroceryList> lists) {
    var filtered = lists;

    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((l) => l.title.toLowerCase().contains(query)).toList();
    }

    // Tab filter
    switch (_selectedFilter) {
      case 'Active':
        filtered = filtered.where((l) => !l.isDone).toList();
        break;
      case 'Shared':
        filtered = filtered.where((l) => l.isShared).toList();
        break;
      default:
        break;
    }

    return filtered;
  }

  void _createNewList() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'List name (e.g. Weekend BBQ)'),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              final id = context.read<DataProvider>().generateId();
              context.read<DataProvider>().addList(
                GroceryList(
                  id: id,
                  title: title,
                  date: 'Just now',
                  isShared: false,
                  isDone: false,
                  items: [],
                  owner: 'me',
                  collaborators: [],
                ),
              );
              context.read<DataProvider>().setActiveList(id);
              ctx.pop();
              context.push(AppRoutes.activeList);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final dataProvider = context.watch<DataProvider>();
    final activeLists = _applyFilter(dataProvider.myLists.where((l) => !l.isDone).toList());
    final completedLists = _selectedFilter == 'All Lists' ? _applyFilter(dataProvider.myLists.where((l) => l.isDone).toList()) : <GroceryList>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded, color: theme.primaryText, size: 28),
                        onPressed: () => context.go(AppRoutes.main),
                      ),
                      IconButton(
                        icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, color: theme.primaryText, size: 24),
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) _searchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showSearch) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search lists...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text('My Saved Lists', style: textStyles.headlineMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
                  Text('Manage your weekly essentials and shared plans', style: textStyles.bodyMedium?.copyWith(color: theme.secondaryText)),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ClipRect(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    _buildFilterChip('All Lists', _selectedFilter == 'All Lists'),
                    _buildFilterChip('Active', _selectedFilter == 'Active'),
                    _buildFilterChip('Shared', _selectedFilter == 'Shared'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: activeLists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, color: theme.hint, size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _searchController.text.isNotEmpty ? 'No lists match your search' : 'No lists yet',
                            style: textStyles.bodyLarge?.copyWith(color: theme.secondaryText),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _createNewList,
                            child: Text('Create your first list', style: textStyles.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: AppSpacing.paddingLg,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Active Shopping', style: textStyles.titleSmall?.copyWith(color: theme.colorScheme.secondary)),
                            Text('${activeLists.length} lists', style: textStyles.labelSmall?.copyWith(color: theme.secondaryText)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...activeLists.map((list) => _buildDismissibleCard(context, list)),
                        if (_selectedFilter == 'All Lists' && completedLists.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text('Recently Completed', style: textStyles.titleSmall?.copyWith(color: theme.colorScheme.secondary)),
                          const SizedBox(height: AppSpacing.sm),
                          ...completedLists.map((list) => _buildDismissibleCard(context, list)),
                        ],
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.5,
                                child: Icon(Icons.eco_rounded, color: theme.colorScheme.secondary, size: 32),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text('You\'ve reached the end of your recent lists', style: textStyles.bodySmall?.copyWith(color: theme.hint)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: FloatingActionButton.small(
          heroTag: 'my_lists_create_list_fab',
          tooltip: 'Create new list',
          onPressed: _createNewList,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.onPrimary : theme.secondaryText,
              ),
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(BuildContext context, GroceryList list) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(list.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
      ),
      onDismissed: (_) {
        final provider = context.read<DataProvider>();
        provider.removeList(list.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${list.title}" deleted'),
            backgroundColor: theme.primaryText,
            action: SnackBarAction(
              label: 'Undo',
              textColor: theme.colorScheme.surface,
              onPressed: () => provider.addList(list),
            ),
          ),
        );
      },
      child: _buildListCard(
        context,
        title: list.title,
        date: list.date,
        itemCount: list.items.length.toString(),
        progress: list.items.isEmpty ? 0 : list.boughtCount / list.items.length,
        totalPrice: '\$${list.totalPrice.toStringAsFixed(2)}',
        isShared: list.isShared,
        isDone: list.isDone,
        onTap: () {
          context.read<DataProvider>().setActiveList(list.id);
          context.push(AppRoutes.activeList);
        },
      ),
    );
  }

  Widget _buildListCard(BuildContext context, {required String title, required String date, required String itemCount, required double progress, required String totalPrice, required bool isShared, required bool isDone, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open list $title',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.secondaryText)),
                      ],
                    ),
                  ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: ListStatusBadges(isDone: isDone, isShared: isShared)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: theme.dividerColor),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$itemCount Items', style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryText)),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: theme.dividerColor,
                              color: theme.success,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Est. Total', style: theme.textTheme.labelSmall?.copyWith(color: theme.secondaryText)),
                          Text(totalPrice, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListStatusBadges extends StatelessWidget {
  final bool isDone;
  final bool isShared;

  const ListStatusBadges({super.key, required this.isDone, required this.isShared});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        runAlignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          if (isDone) const _DoneBadge(),
          _SharePrivacyBadge(isShared: isShared),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: theme.success),
          const SizedBox(width: AppSpacing.xs),
          Text('Done', style: theme.textTheme.labelSmall?.copyWith(color: theme.success, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SharePrivacyBadge extends StatelessWidget {
  final bool isShared;
  const _SharePrivacyBadge({required this.isShared});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isShared ? theme.colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isShared ? theme.colorScheme.primary : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isShared ? Icons.group_rounded : Icons.lock_outline_rounded, size: 14, color: isShared ? theme.colorScheme.primary : theme.secondaryText),
          const SizedBox(width: AppSpacing.xs),
          Text(isShared ? 'Shared' : 'Private', style: theme.textTheme.labelSmall?.copyWith(color: isShared ? theme.colorScheme.primary : theme.secondaryText)),
        ],
      ),
    );
  }
}
