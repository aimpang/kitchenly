import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/data_provider.dart';

class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  static const double _fabClearance = 96;
  final _searchController = TextEditingController();
  bool _invitationDismissed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final dataProvider = context.watch<DataProvider>();
    final query = _searchController.text.trim().toLowerCase();
    final sharedLists = dataProvider.sharedLists.where((l) {
      if (query.isEmpty) return true;
      return l.title.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shared with Me', style: textStyles.headlineMedium?.copyWith(color: theme.primaryText)),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Collaborative shopping lists', style: textStyles.bodySmall?.copyWith(color: theme.secondaryText)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications_none_rounded, color: theme.primaryText),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Notifications coming soon!'), backgroundColor: theme.colorScheme.primary),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search shared lists...',
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Filters coming soon!'), backgroundColor: theme.colorScheme.primary),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.tune_rounded, color: theme.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sharedLists.isEmpty && !_invitationDismissed
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_outlined, color: theme.hint, size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text('No shared lists yet', style: textStyles.bodyLarge?.copyWith(color: theme.secondaryText)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Share a list with friends or family to get started', style: textStyles.bodySmall?.copyWith(color: theme.hint)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: _fabClearance),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Active Collaborations', style: textStyles.labelLarge?.copyWith(color: theme.secondaryText)),
                              Text('${sharedLists.length} Total', style: textStyles.labelSmall?.copyWith(color: theme.hint)),
                            ],
                          ),
                        ),
                        ...sharedLists.map((list) => _buildSharedListCard(
                              context,
                              listId: list.id,
                              title: list.title,
                              owner: list.owner,
                              itemCount: list.items.length.toString(),
                              collabText: 'You & ${list.owner}',
                            )),

                        Container(
                          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          padding: AppSpacing.paddingLg,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.surface, size: 24),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pro Tip', style: textStyles.labelLarge?.copyWith(color: theme.colorScheme.surface)),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Changes you make to shared lists will be visible to collaborators once synced.', style: textStyles.bodySmall?.copyWith(color: theme.colorScheme.surface.withValues(alpha: 0.9))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_invitationDismissed)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            padding: AppSpacing.paddingMd,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: theme.accent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: theme.accent.withValues(alpha: 0.22), shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.mail_outline_rounded, color: theme.accent),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('New Invitation', style: textStyles.labelSmall?.copyWith(color: theme.accent)),
                                          Text('Office Snacks by Mike', style: textStyles.bodyMedium?.copyWith(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Accept: add a mock shared list
                                        final id = dataProvider.generateId();
                                        dataProvider.addSharedList(GroceryList(
                                          id: id,
                                          title: 'Office Snacks',
                                          date: 'Just now',
                                          isShared: true,
                                          isDone: false,
                                          baseServings: 2,
                                          owner: 'Mike',
                                          collaborators: ['me'],
                                          items: [
                                            GroceryItem(id: '${id}_1', name: 'Trail Mix', category: 'Pantry', qty: 3.0, unit: 'bag', price: 5.50),
                                            GroceryItem(id: '${id}_2', name: 'Granola Bars', category: 'Pantry', qty: 2.0, unit: 'box', price: 4.25),
                                          ],
                                        ));
                                        setState(() => _invitationDismissed = true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: const Text('Invitation accepted!'), backgroundColor: theme.success),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.accent,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        minimumSize: const Size(64, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: textStyles.labelLarge,
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    IconButton(
                                      icon: Icon(Icons.close_rounded, color: theme.secondaryText, size: 18),
                                      onPressed: () => setState(() => _invitationDismissed = true),
                                    ),
                                  ],
                                ),
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
          heroTag: 'shared_with_me_share_new_fab',
          tooltip: 'Share new',
          onPressed: () => context.push(AppRoutes.share),
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.person_add_rounded, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildSharedListCard(BuildContext context, {required String listId, required String title, required String owner, required String itemCount, required String collabText}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        context.read<DataProvider>().setActiveList(listId);
        context.push(AppRoutes.activeList);
      },
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
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: theme.secondaryText),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Shared by $owner', style: theme.textTheme.bodySmall?.copyWith(color: theme.secondaryText)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text('$itemCount items', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(color: theme.dividerColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(collabText, style: theme.textTheme.labelSmall?.copyWith(color: theme.secondaryText)),
                TextButton.icon(
                  onPressed: () {
                    context.read<DataProvider>().setActiveList(listId);
                    context.push(AppRoutes.activeList);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Open List'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
