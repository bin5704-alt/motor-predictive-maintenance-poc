import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Settings',
            size: AppTextSize.xl,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: 24),

          // Profile Card
          FutureBuilder<Map<String, dynamic>>(
            future: user != null
                ? Supabase.instance.client
                      .from('profiles')
                      .select()
                      .eq('id', user.id)
                      .single()
                : null,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final name = profile?['full_name'] as String? ?? 'User';
              final email =
                  profile?['email'] as String? ?? user?.email ?? 'No Email';

              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.user,
                        size: 32,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            name,
                            size: AppTextSize.lg,
                            weight: FontWeight.w600,
                          ),
                          AppText(email, isMuted: true),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Edit',
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        // TODO: Implement Edit Profile
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Settings Sections
          const AppText(
            'Preferences',
            size: AppTextSize.lg,
            weight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(context, 'Notifications', LucideIcons.bell),
          _buildSettingsTile(context, 'Appearance', LucideIcons.moon),
          _buildSettingsTile(context, 'Language', LucideIcons.languages),

          const SizedBox(height: 32),
          const AppText(
            'Support',
            size: AppTextSize.lg,
            weight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(context, 'Help Center', LucideIcons.info),
          _buildSettingsTile(context, 'Privacy Policy', LucideIcons.shield),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Log Out',
              variant: AppButtonVariant.ghost,
              icon: const Icon(LucideIcons.log_out, size: 16),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                // AuthGate handles redirection
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 16),
            Expanded(child: AppText(title, weight: FontWeight.w500)),
            const Icon(LucideIcons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
