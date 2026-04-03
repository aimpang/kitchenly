import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/data_provider.dart';
import '../screens/quick_add_screen.dart';

class ActiveListScreen extends StatefulWidget {
  const ActiveListScreen({super.key});

  @override
  State<ActiveListScreen> createState() => _ActiveListScreenState();
}

class _ActiveListScreenState extends State<ActiveListScreen> {
  String _selectedCategory = 'All Items';
  bool _hasShownDonePrompt = false;

  void _showReceiptScanSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) {
        final textStyles = theme.textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.document_scanner_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Scan receipt', style: textStyles.titleLarge?.copyWith(color: theme.primaryText))),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.25)),
                              ),
                              child: Text('Pro', style: textStyles.labelMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Snap a receipt to auto-fill item prices for this list.', style: textStyles.bodyMedium?.copyWith(color: theme.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // Backend/subscription not connected yet — keep this as a lightweight entry point for now.
                    ctx.pop();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Receipt scan is a Pro feature — coming soon.'),
                        backgroundColor: theme.primaryText,
                      ),
                    );
                  },
                  icon: Icon(Icons.lock_rounded, color: theme.colorScheme.onPrimary),
                  label: Text('Unlock receipt scan', style: TextStyle(color: theme.colorScheme.onPrimary)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => ctx.pop(),
                  child: Text('Not now', style: TextStyle(color: theme.secondaryText)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMarkAsDonePrompt(GroceryList list) {
    if (_hasShownDonePrompt || list.isDone) return;
    _hasShownDonePrompt = true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF8BA888), size: 48),
        title: const Text('All items purchased!'),
        content: Text('Would you like to mark "${list.title}" as done?'),
        actions: [
          TextButton(
            onPressed: () {
              ctx.pop();
              _hasShownDonePrompt = false; // Reset if user says not now
            },
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              ctx.pop();
              context.read<DataProvider>().markListDone(list.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(list.isShared ? 'Marked done — collaborators were notified' : 'Marked done'),
                  backgroundColor: const Color(0xFF8BA888),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BA888)),
            child: const Text('Mark as Done'),
          ),
        ],
      ),
    );
  }

  void _handleItemToggle(String listId, String itemId) {
    final provider = context.read<DataProvider>();
    provider.toggleItemBought(listId, itemId);
    
    // Check if all items are now purchased
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final list = provider.activeList;
      if (list == null || list.items.isEmpty) return;
      
      final allBought = list.items.every((item) => item.isBought);
      if (allBought && !list.isDone) {
        _showMarkAsDonePrompt(list);
      }
    });
  }

  List<_ActiveListRow> _buildRows({required List<GroceryItem> unboughtItems, required List<GroceryItem> boughtItems}) {
    final rows = <_ActiveListRow>[];
    if (unboughtItems.isNotEmpty) {
      rows.add(const _ActiveListRow.header(keyValue: 'hdr_to_buy', title: 'To Buy', showDivider: false));
      for (final item in unboughtItems) {
        rows.add(_ActiveListRow.item(item));
      }
    }
    if (boughtItems.isNotEmpty) {
      rows.add(const _ActiveListRow.header(keyValue: 'hdr_purchased', title: 'Purchased', showDivider: true));
      for (final item in boughtItems) {
        rows.add(_ActiveListRow.item(item));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final dataProvider = context.watch<DataProvider>();
    final activeList = dataProvider.activeList ?? (dataProvider.myLists.isNotEmpty ? dataProvider.myLists.first : null);
    if (activeList == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Active List')),
        body: const Center(child: Text('No list selected')),
      );
    }

    final filteredItems = _selectedCategory == 'All Items'
        ? activeList.items
        : activeList.items.where((i) => i.category == _selectedCategory).toList();
    final unboughtItems = filteredItems.where((i) => !i.isBought).toList();
    final boughtItems = filteredItems.where((i) => i.isBought).toList();

    final allItemsBought = activeList.items.isNotEmpty && activeList.items.every((i) => i.isBought);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A3728)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(activeList.title, style: textStyles.headlineMedium?.copyWith(color: const Color(0xFF4A3728))),
                        ],
                      ),
                      if (activeList.isShared)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text('Shared with ${activeList.collaborators.join(", ")}', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                        child: _ServingsInput(
                          servings: activeList.servings,
                          onChanged: (val) => context.read<DataProvider>().setListServings(activeList.id, val),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Scan receipt',
                        icon: const Icon(Icons.document_scanner_rounded, color: Color(0xFFC4785A)),
                        onPressed: _showReceiptScanSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined, color: Color(0xFFC4785A)),
                        onPressed: () => context.push(AppRoutes.share),
                      ),
                      if (!activeList.isDone)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: allItemsBought
                                ? FilledButton.icon(
                                    key: const ValueKey('mark_done_cta'),
                                    onPressed: () => _showMarkAsDonePrompt(activeList),
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                    label: const Text('Done', style: TextStyle(color: Colors.white)),
                                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BA888), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  )
                                : const SizedBox.shrink(key: ValueKey('mark_done_cta_empty')),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3728)),
                        onSelected: (value) {
                          if (value == 'done') {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Mark list as done?'),
                                content: Text('This will mark "${activeList.title}" as completed.'),
                                actions: [
                                  TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      ctx.pop();
                                      context.read<DataProvider>().markListDone(activeList.id);
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(activeList.isShared ? 'Marked done — collaborators were notified' : 'Marked done'),
                                          backgroundColor: const Color(0xFF8BA888),
                                        ),
                                      );
                                    },
                                    child: const Text('Mark as Done'),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete List'),
                                content: Text('Are you sure you want to delete "${activeList.title}"?'),
                                actions: [
                                  TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      ctx.pop();
                                      context.read<DataProvider>().removeList(activeList.id);
                                      context.pop();
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Color(0xFFD9534F))),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'rename') {
                            final controller = TextEditingController(text: activeList.title);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Rename List'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(hintText: 'List name'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      final newTitle = controller.text.trim();
                                      if (newTitle.isNotEmpty) {
                                        context.read<DataProvider>().renameList(activeList.id, newTitle);
                                      }
                                      ctx.pop();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (!activeList.isDone) const PopupMenuItem(value: 'done', child: Text('Mark as Done')),
                          const PopupMenuItem(value: 'rename', child: Text('Rename')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFD9534F)))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!activeList.isDone && allItemsBought)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BA888).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: const Color(0xFF8BA888).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF8BA888)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Everything’s checked off. Mark this list as done?', style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600))),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: () => _showMarkAsDonePrompt(activeList),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BA888), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        child: const Text('Mark done', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

            // Make receipt scan discoverable at the moment it matters:
            // when the user starts checking items off (or has purchased items).
            if (!activeList.isDone && boughtItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: _ReceiptScanCallout(onTap: _showReceiptScanSheet),
              ),
            Builder(
              builder: (context) {
                final categories = <String>{'All Items'};
                for (final item in activeList.items) {
                  categories.add(item.category);
                }
                return SizedBox(
                  height: 52,
                  child: ClipRect(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      children: categories.map((cat) => _buildCategoryChip(cat, _selectedCategory == cat)).toList(),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final rows = _buildRows(unboughtItems: unboughtItems, boughtItems: boughtItems);
                  if (rows.isEmpty) {
                    return Center(
                      child: Text(
                        'No items yet',
                        style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF8C7E6F)),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.paddingLg,
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return switch (row) {
                        _ActiveListHeaderRow() => Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.md, bottom: AppSpacing.sm),
                            child: KeyedSubtree(
                              key: ValueKey(row.keyValue),
                              child: _ActiveListHeader(
                                title: row.title,
                                showDivider: row.showDivider,
                              ),
                            ),
                          ),
                        _ActiveListItemRow() => _buildGroceryItem(row.item, activeList.id, context),
                      };
                    },
                  );
                },
              ),
            ),
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6E3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                border: Border(top: BorderSide(color: theme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4423).withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Total', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('\$${activeList.boughtPrice.toStringAsFixed(2)}', style: textStyles.headlineSmall?.copyWith(color: const Color(0xFF4A3728))),
                          const SizedBox(width: 4),
                          Text('/ \$${activeList.totalPrice.toStringAsFixed(2)}', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFBDB2A7))),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => showQuickAddSheet(context),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4785A),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4423).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, color: Color(0xFFFFFFFF), size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Add Item', style: textStyles.labelLarge?.copyWith(color: const Color(0xFFFFFFFF))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC4785A) : const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE8DFD0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF8C7E6F),
              ),
        ),
      ),
    );
  }

  Widget _buildGroceryItem(GroceryItem item, String listId, BuildContext context) {
    final isBought = item.isBought;
    return Dismissible(
      // Keep the key stable across rebuilds. Changing keys (e.g. based on isBought)
      // can trigger framework assertions when the item moves between sections.
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373)),
      ),
      onDismissed: (direction) {
        final provider = context.read<DataProvider>();
        // Find the index before removing so undo can reinsert at the right spot
        final activeListRef = provider.activeList;
        final originalIndex = activeListRef?.items.indexOf(item) ?? -1;
        provider.removeItem(listId, item.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            backgroundColor: const Color(0xFF4A3728),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFFFDF6E3),
              onPressed: () {
                provider.reAddItem(listId, item, originalIndex);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isBought ? Colors.transparent : const Color(0xFFE8DFD0)),
          boxShadow: isBought
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6B4423).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isBought ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isBought ? const Color(0xFF8BA888) : const Color(0xFF8C7E6F),
                size: 28,
              ),
              onPressed: () => _handleItemToggle(listId, item.id),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isBought ? const Color(0xFF8C7E6F) : const Color(0xFF4A3728),
                          decoration: isBought ? TextDecoration.lineThrough : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isBought) Text(item.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF8C7E6F))),
                ],
              ),
            ),
            if (!isBought) ...[
              _QuantityControl(item: item, listId: listId),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 60,
                child: Text(
                  '\$${(item.price * item.qty).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (isBought)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8C7E6F), size: 20),
                onPressed: () => context.read<DataProvider>().removeItem(listId, item.id),
              ),
          ],
        ),
      ),
    );
  }
}

sealed class _ActiveListRow {
  const _ActiveListRow();

  const factory _ActiveListRow.header({required String keyValue, required String title, required bool showDivider}) = _ActiveListHeaderRow;
  const factory _ActiveListRow.item(GroceryItem item) = _ActiveListItemRow;
}

class _ActiveListHeaderRow extends _ActiveListRow {
  final String keyValue;
  final String title;
  final bool showDivider;

  const _ActiveListHeaderRow({required this.keyValue, required this.title, required this.showDivider});
}

class _ActiveListItemRow extends _ActiveListRow {
  final GroceryItem item;
  const _ActiveListItemRow(this.item);
}

class _ActiveListHeader extends StatelessWidget {
  final String title;
  final bool showDivider;

  const _ActiveListHeader({required this.title, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    if (!showDivider) {
      return Text(title, style: textStyles.labelLarge?.copyWith(color: const Color(0xFF8C7E6F)));
    }
    return Row(
      children: [
        Text(title, style: textStyles.labelLarge?.copyWith(color: const Color(0xFF8C7E6F))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }
}

class _ServingsInput extends StatefulWidget {
  final int servings;
  final ValueChanged<int> onChanged;

  const _ServingsInput({required this.servings, required this.onChanged});

  @override
  State<_ServingsInput> createState() => _ServingsInputState();
}

class _ServingsInputState extends State<_ServingsInput> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.servings.toString());
  }

  @override
  void didUpdateWidget(covariant _ServingsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.servings != widget.servings && _controller.text != widget.servings.toString()) {
      _controller.text = widget.servings.toString();
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1 || parsed > 99) {
      setState(() => _errorText = 'Enter 1–99');
      return;
    }
    if (_errorText != null) setState(() => _errorText = null);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _errorText == null ? const Color(0xFFE8DFD0) : const Color(0xFFE57373)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF8C7E6F)),
          const SizedBox(width: 8),
          Text('Servings', style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF8C7E6F))),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
              onEditingComplete: _commit,
              style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                isDense: true,
                hintText: '2',
                errorText: _errorText,
                errorStyle: const TextStyle(height: 0.01, fontSize: 0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: const Color(0xFFFFFBF5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: Color(0xFFC4785A)),
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptScanCallout extends StatelessWidget {
  final VoidCallback onTap;
  const _ReceiptScanCallout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFC4785A).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFC4785A).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFC4785A).withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: const Icon(Icons.document_scanner_rounded, color: Color(0xFFC4785A), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Scan receipt', style: textStyles.titleSmall?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w800))),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.25)),
                        ),
                        child: Text('Pro', style: textStyles.labelMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Auto-fill prices from your receipt (optional).', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C7E6F)),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatefulWidget {
  final GroceryItem item;
  final String listId;

  const _QuantityControl({required this.item, required this.listId});

  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<_QuantityControl> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatQty(widget.item.qty));
  }

  @override
  void didUpdateWidget(covariant _QuantityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty) {
      final next = _formatQty(widget.item.qty);
      if (_controller.text != next) {
        _controller.text = next;
        _errorText = null;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    final isInt = (value - value.roundToDouble()).abs() < 0.0001;
    if (isInt) return value.round().toString();
    final oneDp = value.toStringAsFixed(1);
    return oneDp.endsWith('.0') ? value.round().toString() : oneDp;
  }

  void _commit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0 || parsed > 999) {
      setState(() => _errorText = 'Enter 0.1–999');
      return;
    }
    if (_errorText != null) setState(() => _errorText = null);
    context.read<DataProvider>().setItemQty(widget.listId, widget.item.id, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.isToTaste) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFFFFBF5), borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Text('to taste', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF8C7E6F))),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _errorText == null ? const Color(0xFFE8DFD0) : const Color(0xFFE57373)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.read<DataProvider>().adjustItemQty(widget.listId, item.id, -1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFFC4785A)),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commit(),
                  onEditingComplete: _commit,
                  style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '1',
                    errorText: _errorText,
                    errorStyle: const TextStyle(height: 0.01, fontSize: 0),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    filled: true,
                    fillColor: const Color(0xFFFFFBF5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: const BorderSide(color: Color(0xFFE8DFD0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: const BorderSide(color: Color(0xFFC4785A))),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (item.unit.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(item.unit, style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF8C7E6F), fontWeight: FontWeight.w800)),
              ],
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.read<DataProvider>().adjustItemQty(widget.listId, item.id, 1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.add_rounded, size: 16, color: Color(0xFFC4785A)),
            ),
          ),
        ],
      ),
    );
  }
}


