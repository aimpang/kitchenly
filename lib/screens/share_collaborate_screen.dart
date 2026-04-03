import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/data_provider.dart';

class ShareCollaborateScreen extends StatefulWidget {
  const ShareCollaborateScreen({super.key});

  @override
  State<ShareCollaborateScreen> createState() => _ShareCollaborateScreenState();
}

class _ShareCollaborateScreenState extends State<ShareCollaborateScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isPairing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handlePairing() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isPairing = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final dataProvider = context.read<DataProvider>();
      final success = dataProvider.pairWithDevice(code);
      
      setState(() => _isPairing = false);
      
      if (success) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device paired successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid pairing code. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textTheme;
    final dataProvider = context.watch<DataProvider>();
    
    // Using the first list as the active one for demonstration
    final activeList = dataProvider.myLists.isNotEmpty ? dataProvider.myLists.first : null;

    if (activeList == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Active List')),
        body: const Center(child: Text('No list selected')),
      );
    }

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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Text('Sync Devices', style: textStyles.titleLarge?.copyWith(color: const Color(0xFF4A3728))),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Your Code Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 48, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Your Pairing Code', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF8C7E6F))),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6E3),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: const Color(0xFFE8DFD0), width: 2),
                      ),
                      child: Text(
                        dataProvider.myPairingCode,
                        style: textStyles.headlineMedium?.copyWith(
                          color: const Color(0xFF4A3728),
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Share this code with your partner to sync lists.',
                      style: textStyles.bodySmall?.copyWith(color: const Color(0xFF8C7E6F)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Pair New Device Section
              Text('Pair a Device', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4423).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Enter partner\'s code',
                        prefixIcon: const Icon(Icons.devices_rounded),
                        filled: true,
                        fillColor: const Color(0xFFFDF6E3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _isPairing ? null : _handlePairing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4785A),
                        foregroundColor: const Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: _isPairing 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Text('Connect Device'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              
              // Paired Devices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Paired Devices', style: textStyles.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DFD0),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${dataProvider.pairedDevices.length}', 
                      style: textStyles.labelSmall?.copyWith(color: const Color(0xFF4A3728))
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              if (dataProvider.pairedDevices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No devices paired yet.',
                      style: textStyles.bodyMedium?.copyWith(color: const Color(0xFF8C7E6F)),
                    ),
                  ),
                )
              else
                ...dataProvider.pairedDevices.map((device) => _buildPairedDeviceCard(device, activeList, dataProvider, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPairedDeviceCard(String deviceName, GroceryList activeList, DataProvider dataProvider, BuildContext context) {
    final bool isSynced = activeList.collaborators.contains(deviceName);
    
    return Container(
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
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFC4785A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smartphone_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deviceName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF4A3728))),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isSynced ? 'Syncing this list' : 'Ready to sync',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSynced ? const Color(0xFF2E7D32) : const Color(0xFF8C7E6F)
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: isSynced ? null : () => dataProvider.syncListWithDevice(activeList.id, deviceName),
            style: OutlinedButton.styleFrom(
              foregroundColor: isSynced ? const Color(0xFF8C7E6F) : const Color(0xFFC4785A),
              side: BorderSide(color: isSynced ? const Color(0xFFE8DFD0) : const Color(0xFFC4785A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            child: Text(isSynced ? 'Synced' : 'Sync'),
          ),
        ],
      ),
    );
  }
}
