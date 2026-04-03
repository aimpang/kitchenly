import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/data_provider.dart';

/// Opens the Quick Add experience as a modal bottom sheet.
///
/// This replaces the previous full-page route so Quick Add stays "quick".
void showQuickAddSheet(BuildContext context) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.7),
          child: _QuickAddSheetScaffold(rootContextForNav: context),
        ),
      );
    },
  );
}

class _QuickAddSheetScaffold extends StatelessWidget {
  final BuildContext rootContextForNav;

  const _QuickAddSheetScaffold({required this.rootContextForNav});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.secondaryText.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: QuickAddScreen(rootContextForNav: rootContextForNav)),
        ],
      ),
    );
  }
}

class QuickAddScreen extends StatefulWidget {
  final BuildContext rootContextForNav;

  const QuickAddScreen({super.key, required this.rootContextForNav});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final List<String> _addedItems = [];

  TextEditingController? _activeController;

  static const List<String> _kOptions = <String>[
    'Apples',
    'Avocados',
    'Bananas',
    'Bread',
    'Butter',
    'Cheese',
    'Chicken Breasts',
    'Coffee',
    'Eggs',
    'Garlic',
    'Greek Yogurt',
    'Milk',
    'Olive Oil',
    'Onions',
    'Pasta',
    'Potatoes',
    'Rice',
    'Sea Salt',
    'Spinach',
    'Tomatoes',
    'Whole Milk',
  ];

  void _addItem([String? text]) {
    final effectiveText = text ?? _activeController?.text ?? '';
    if (effectiveText.isNotEmpty) {
      setState(() {
        _addedItems.insert(0, effectiveText);
        if (text == null) _activeController?.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
  }

  void _addSuggestionItems(String category, String itemsStr) {
    final items = itemsStr.split(', ').map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final item in items) {
        if (!_addedItems.contains(item)) {
          _addedItems.insert(0, item);
        }
      }
    });
  }

  void _submitItems() async {
    if (_addedItems.isEmpty) return;

    final provider = context.read<DataProvider>();
    await provider.ensurePriceBookLoaded();
    final items = _addedItems.map(provider.createItemFromInput).toList();
    final activeList = provider.activeList;

    if (activeList != null) {
      provider.addItemsToList(activeList.id, items);
    } else {
      final listId = provider.generateId();
      provider.addList(
        GroceryList(
          id: listId,
          title: 'New List',
          date: 'Just now',
          isShared: false,
          isDone: false,
          items: items,
          owner: 'me',
          collaborators: [],
        ),
      );
      provider.setActiveList(listId);
    }

    if (!context.mounted) return;

    // Close the bottom sheet.
    context.pop();

    if (!widget.rootContextForNav.mounted) return;
    widget.rootContextForNav.push(AppRoutes.activeList);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final activeList = context.select<DataProvider, GroceryList?>((p) => p.activeList);
    final buttonLabel = activeList != null
        ? 'Add to ${activeList.title} (${_addedItems.length} items)'
        : 'Review List (${_addedItems.length} items)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: theme.primaryText),
                onPressed: () => context.pop(),
              ),
              Text('Quick Add', style: textStyles.titleLarge?.copyWith(color: theme.primaryText)),
              IconButton(
                icon: Icon(Icons.history_rounded, color: theme.secondaryText),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Purchase history coming soon!'), backgroundColor: theme.colorScheme.primary),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    Container(
                      padding: AppSpacing.paddingXl,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                        children: [
                          Text('What\'s on your list?', style: textStyles.headlineMedium?.copyWith(color: theme.primaryText), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Tap the mic and say things like "6 organic eggs" or "a gallon of whole milk"', style: textStyles.bodyMedium?.copyWith(color: theme.secondaryText), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            button: true,
                            label: 'Voice input',
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Voice input coming soon!'), backgroundColor: theme.colorScheme.primary),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.13), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.27), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.mic_rounded, color: theme.colorScheme.onPrimary, size: 32),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Or type items manually', style: textStyles.labelLarge?.copyWith(color: theme.secondaryText)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return _kOptions.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              _addItem(selection);
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              final theme = Theme.of(context);
                              _activeController = controller;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Bananas, Bread...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    borderSide: BorderSide(color: theme.dividerColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    borderSide: BorderSide(color: theme.dividerColor),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  _addItem(value);
                                  controller.clear();
                                },
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              final theme = Theme.of(context);
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  color: theme.colorScheme.surface,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final String option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(option, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryText)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Semantics(
                          button: true,
                          label: 'Add item',
                          child: InkWell(
                            onTap: _addItem,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Added just now', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
                        TextButton(
                          onPressed: () => setState(() => _addedItems.clear()),
                          child: Text('Clear all', style: textStyles.labelMedium?.copyWith(color: theme.colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_addedItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('No items added yet. Type or speak to add items.', style: textStyles.bodySmall?.copyWith(color: theme.hint), textAlign: TextAlign.center),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _addedItems.asMap().entries.map((entry) {
                          return _buildInputChip(entry.value, () => _removeItem(entry.key), context);
                        }).toList(),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Frequently added', style: textStyles.titleMedium?.copyWith(color: theme.primaryText)),
                    const SizedBox(height: AppSpacing.md),
                    _buildSuggestion(context, Icons.add_circle_outline_rounded, 'Fresh Produce', 'Apples, Spinach, Tomatoes'),
                    _buildSuggestion(context, Icons.add_circle_outline_rounded, 'Pantry Essentials', 'Coffee, Olive Oil, Sea Salt'),
                    _buildSuggestion(context, Icons.add_circle_outline_rounded, 'Dairy & Eggs', 'Butter, Greek Yogurt, Cheese'),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
        Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: InkWell(
            onTap: _addedItems.isEmpty ? null : _submitItems,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _addedItems.isEmpty ? theme.hint : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(buttonLabel, style: textStyles.titleMedium?.copyWith(color: theme.colorScheme.onPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputChip(String label, VoidCallback onRemove, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryText)),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Add $title items: $subtitle',
      child: GestureDetector(
        onTap: () => _addSuggestionItems(title, subtitle),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                alignment: Alignment.center,
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.secondaryText)),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
