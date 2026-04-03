import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/data_provider.dart';

/// Opens the Quick Add experience as a modal bottom sheet.
///
/// This replaces the previous full-page route so Quick Add stays “quick”.
void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFDF6E3),
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
              color: const Color(0xFF8C7E6F).withValues(alpha: 0.35),
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
    final activeList = context.watch<DataProvider>().activeList;
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
                icon: const Icon(Icons.close_rounded, color: Color(0xFF4A3728)),
                onPressed: () => context.pop(),
              ),
              Text('Quick Add', style: textStyles.titleLarge?.copyWith(color: const Color(0xFF4A3728))),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Color(0xFF8C7E6F)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase history coming soon!'), backgroundColor: Color(0xFFC4785A)),
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
                        color: const Color(0xFFFDF6E3),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                        children: [
                          Text('What\'s on your list?', style: textStyles.headlineMedium?.copyWith(color: const Color(0xFF4A3728)), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Tap the mic and say things like "6 organic eggs" or "a gallon of whole milk"', style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF8C7E6F)), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.lg),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voice input coming soon!'), backgroundColor: Color(0xFFC4785A)),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(color: const Color(0xFFC4785A).withValues(alpha: 0.13), shape: BoxShape.circle),
                                ),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(color: const Color(0xFFC4785A).withValues(alpha: 0.27), shape: BoxShape.circle),
                                ),
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC4785A),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6B4423).withValues(alpha: 0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.mic_rounded, color: Color(0xFFFFFFFF), size: 32),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Or type items manually', style: textStyles.labelLarge?.copyWith(color: const Color(0xFF8C7E6F))),
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
                              _activeController = controller;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Bananas, Bread...',
                                  filled: true,
                                  fillColor: const Color(0xFFFDF6E3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  _addItem(value);
                                  controller.clear();
                                },
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  color: const Color(0xFFFDF6E3),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width - (AppSpacing.lg * 2) - 72,
                                    constraints: const BoxConstraints(maxHeight: 200),
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
                                            child: Text(option, style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF4A3728))),
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
                        InkWell(
                          onTap: _addItem,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC4785A),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B4423).withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.send_rounded, color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Added just now', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
                        TextButton(
                          onPressed: () => setState(() => _addedItems.clear()),
                          child: Text('Clear all', style: textStyles.labelMedium?.copyWith(color: const Color(0xFFC4785A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_addedItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('No items added yet. Type or speak to add items.', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFBDB2A7)), textAlign: TextAlign.center),
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
                    Text('Frequently added', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
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
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF5),
            border: Border(top: BorderSide(color: Color(0xFFE8DFD0))),
          ),
          child: InkWell(
            onTap: _addedItems.isEmpty ? null : _submitItems,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _addedItems.isEmpty ? const Color(0xFFBDB2A7) : const Color(0xFFC4785A),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(buttonLabel, style: textStyles.titleMedium?.copyWith(color: const Color(0xFFFFFFFF))),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFFFFF)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputChip(String label, VoidCallback onRemove, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: const Color(0xFFE8DFD0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF4A3728))),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF8C7E6F)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () => _addSuggestionItems(title, subtitle),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              decoration: BoxDecoration(color: const Color(0xFFFDF6E3), borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFFC4785A), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.w600)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFC4785A), size: 20),
          ],
        ),
      ),
    );
  }
}
