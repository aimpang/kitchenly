import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:kitchenly/nav.dart';
import 'package:kitchenly/providers/data_provider.dart';
import 'package:kitchenly/theme.dart';

class AddDishScreen extends StatefulWidget {
  const AddDishScreen({super.key});

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  bool _useSmartAi = true;
  TextEditingController? _dishController;

  @override
  void dispose() {
    _dishController?.dispose();
    super.dispose();
  }

  void _generateForDish(BuildContext context, String dish) {
    final trimmed = dish.trim();
    if (trimmed.isEmpty) return;
    context.read<DataProvider>().createListFromDish(dishName: trimmed, useSmartAi: _useSmartAi);
    context.push(AppRoutes.activeList);
  }

  String get _dishText => _dishController?.text ?? '';

  List<String> _rankedDishOptions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return DataProvider.knownDishes.take(8).toList();

    int score(String dish) {
      final d = dish.toLowerCase();
      if (d == q) return 0;
      if (d.startsWith(q)) return 1;
      if (d.contains(q)) return 2;

      // Token-level match gets a better score than random contains.
      final qTokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final dTokens = d.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final tokenHits = qTokens.where((qt) => dTokens.any((dt) => dt.startsWith(qt) || dt.contains(qt))).length;
      if (tokenHits == 0) return 999;
      return 10 - tokenHits;
    }

    final results = DataProvider.knownDishes
        .map((d) => MapEntry(d, score(d)))
        .where((e) => e.value != 999)
        .toList()
      ..sort((a, b) {
        final byScore = a.value.compareTo(b.value);
        if (byScore != 0) return byScore;
        return a.key.length.compareTo(b.key.length);
      });
    return results.map((e) => e.key).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;

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
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF8C7E6F)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('How it works'),
                          content: const Text('Type a dish name or tap a suggestion, and we\'ll generate a grocery list with the ingredients you need. Toggle "Smart AI" for more precise quantities.'),
                          actions: [
                            TextButton(onPressed: () => ctx.pop(), child: const Text('Got it')),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('What\'s on the menu?', style: textStyles.headlineMedium?.copyWith(color: const Color(0xFF4A3728))),
              const SizedBox(height: AppSpacing.xs),
              Text('Enter a dish name and we\'ll help you find the ingredients.', style: textStyles.bodyLarge?.copyWith(color: const Color(0xFF8C7E6F))),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E3),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4423).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Dish Name', style: textStyles.labelLarge?.copyWith(color: const Color(0xFF4A3728))),
                    const SizedBox(height: AppSpacing.sm),
                    Autocomplete<String>(
                      optionsBuilder: (value) => _rankedDishOptions(value.text),
                      onSelected: (dish) {
                        _dishController?.text = dish;
                        _dishController?.selection = TextSelection.collapsed(offset: dish.length);
                        FocusScope.of(context).unfocus();
                        _generateForDish(context, dish);
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        _dishController ??= textEditingController;

                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) => _generateForDish(context, val),
                          decoration: InputDecoration(
                            hintText: 'e.g. Lemon Garlic Butter Salmon',
                            filled: true,
                            fillColor: const Color(0xFFFFFBF5),
                            prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFC4785A)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: const BorderSide(color: Color(0xFFE8DFD0)),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        final theme = Theme.of(context);
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 520),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF5),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: const Color(0xFFE8DFD0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6B4423).withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFFE8DFD0).withValues(alpha: 0.6)),
                                itemBuilder: (context, index) {
                                  final dish = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(dish),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFC4785A)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              dish,
                                              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text('Generate', style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: const Color(0xFFFDF6E3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(color: Color(0xFFFFF5F0), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(Icons.psychology_rounded, color: Color(0xFFF08080), size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('Use Smart AI', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
                                    _buildPremiumBadge(context),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Get precise quantities & substitutions', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useSmartAi,
                            activeColor: const Color(0xFFF08080),
                            onChanged: (val) => setState(() => _useSmartAi = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFC4785A), size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Popular right now', style: textStyles.titleSmall?.copyWith(color: const Color(0xFF8C7E6F))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildSuggestionChip('Spaghetti Carbonara', context),
                  _buildSuggestionChip('Chicken Tikka Masala', context),
                  _buildSuggestionChip('Avocado Toast', context),
                  _buildSuggestionChip('Beef Stir Fry', context),
                  _buildSuggestionChip('Quinoa Salad', context),
                ],
              ),
              const SizedBox(height: 60),
              InkWell(
                onTap: () => _generateForDish(context, _dishText),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4785A),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC4785A).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Generate Grocery List', style: textStyles.titleMedium?.copyWith(color: const Color(0xFFFFFFFF))),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFFFFFFF), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('AI estimates may vary based on local store availability', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFBDB2A7)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: const Color(0xFFF08080)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF08080)),
          const SizedBox(width: 4),
          Text('PREMIUM', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFF08080))),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, BuildContext context) {
    return InkWell(
      onTap: () {
        _dishController?.text = label;
        _dishController?.selection = TextSelection.collapsed(offset: label.length);
        FocusScope.of(context).unfocus();
        _generateForDish(context, label);
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFE8DFD0)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A3728))),
      ),
    );
  }
}
