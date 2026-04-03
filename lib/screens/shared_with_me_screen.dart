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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8DFD0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shared with Me', style: textStyles.headlineMedium?.copyWith(color: const Color(0xFF4A3728))),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Collaborative shopping lists', style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6E3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4423).withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF4A3728)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications coming soon!'), backgroundColor: Color(0xFFC4785A)),
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
                        fillColor: const Color(0xFFFDF6E3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6E3),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: const Color(0xFFE8DFD0)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF4A3728)),
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
                          const Icon(Icons.group_outlined, color: Color(0xFFBDB2A7), size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text('No shared lists yet', style: textStyles.bodyLarge?.copyWith(color: const Color(0xFF8C7E6F))),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Share a list with friends or family to get started', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFBDB2A7))),
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
                              Text('Active Collaborations', style: textStyles.labelLarge?.copyWith(color: const Color(0xFF8C7E6F))),
                              Text('${sharedLists.length} Total', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFBDB2A7))),
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
                            color: const Color(0xFF808055),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFDF6E3), size: 24),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pro Tip', style: textStyles.labelLarge?.copyWith(color: const Color(0xFFFDF6E3))),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Any changes you make to these lists are visible to all collaborators in real-time.', style: textStyles.bodySmall?.copyWith(color: const Color(0xFFFDF6E3).withValues(alpha: 0.9))),
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
                              color: const Color(0xFFFDF6E3),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: const Color(0xFFF08080)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: const Color(0xFFF08080).withValues(alpha: 0.22), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.mail_outline_rounded, color: Color(0xFFF08080)),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('New Invitation', style: textStyles.labelSmall?.copyWith(color: const Color(0xFFF08080))),
                                      Text('Office Snacks by Mike', style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF4A3728), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Row(
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
                                          const SnackBar(content: Text('Invitation accepted!'), backgroundColor: Color(0xFF8BA888)),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF08080),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(64, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: textStyles.labelLarge,
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8C7E6F), size: 18),
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
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF4A3728)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8C7E6F)),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Shared by $owner', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8C7E6F))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF6E3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFFC4785A).withValues(alpha: 0.3)),
                  ),
                  child: Text('$itemCount items', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFC4785A))),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(color: Theme.of(context).dividerColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(collabText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF8C7E6F))),
                TextButton.icon(
                  onPressed: () {
                    context.read<DataProvider>().setActiveList(listId);
                    context.push(AppRoutes.activeList);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Open List'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC4785A),
                    textStyle: Theme.of(context).textTheme.labelLarge,
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
