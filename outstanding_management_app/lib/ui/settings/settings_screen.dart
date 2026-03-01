import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/appearance_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                        child: Text(
                          (user.companyName ?? user.displayName)[0].toUpperCase(),
                          style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.companyName ?? user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),

          // General
          Text('GENERAL', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _settingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle: 'Business name, logo, email, phone',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _settingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme & display preferences',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),

          const SizedBox(height: 24),
          Text('LEGAL', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _settingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showInfoDialog(context, 'Privacy Policy', 'Your data is stored securely in the cloud and is only accessible by you. We do not share your data with any third parties.'),
          ),
          _settingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => _showInfoDialog(context, 'Terms & Conditions', 'By using this app, you agree to use it responsibly for managing your business outstanding records. We are not liable for any data discrepancies.'),
          ),

          const SizedBox(height: 24),
          Text('ACCOUNT', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _settingsTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _confirmSignOut(context, ref),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('Outstanding Manager v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
