import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qlct/core/theme/app_theme.dart';
import 'package:qlct/features/auth/data/auth_repository.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/settings/providers/settings_providers.dart';
import 'package:qlct/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountCard(
              context,
              user,
              isDark,
            ).animate().fadeIn(duration: 300.ms),
            const Gap(20),
            Text(
              l10n.theme,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const Gap(8),
            _buildThemeSelector(
              context,
              ref,
              themeMode,
              l10n,
              isDark,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const Gap(20),
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const Gap(8),
            _buildLanguageSelector(
              context,
              ref,
              locale,
              l10n,
              isDark,
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const Gap(20),
            _buildSettingsTile(
              context,
              icon: Icons.category_rounded,
              label: l10n.categoryManagement,
              color: AppColors.primary,
              isDark: isDark,
              onTap: () => context.push('/categories'),
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.savings_rounded,
              label: l10n.savingsGoals,
              color: AppColors.info,
              isDark: isDark,
              onTap: () => context.push('/savings'),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.handshake_rounded,
              label: l10n.debts,
              color: AppColors.accent,
              isDark: isDark,
              onTap: () => context.push('/debts'),
            ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_active_rounded,
              label: l10n.paymentReminders,
              color: AppColors.warning,
              isDark: isDark,
              onTap: () => context.push('/reminders'),
            ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline_rounded,
              label: l10n.about,
              color: AppColors.primary,
              isDark: isDark,
              onTap: () => context.push('/about'),
            ).animate().fadeIn(delay: 210.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.logout_rounded,
              label: l10n.signOut,
              color: AppColors.expense,
              isDark: isDark,
              onTap: () => _handleSignOut(context, ref, l10n),
            ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
            const Gap(12),
            _buildSettingsTile(
              context,
              icon: Icons.delete_forever_rounded,
              label: l10n.deleteAllData,
              color: AppColors.expense,
              isDark: isDark,
              onTap: () => _handleDeleteData(context, ref, l10n),
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
            const Gap(32),
            Center(
              child: Text(
                'QLCT v1.0.0',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, dynamic user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: user?.photoURL != null
                ? CachedNetworkImageProvider(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'User',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final options = [
      (ThemeMode.light, l10n.lightMode, Icons.light_mode_rounded),
      (ThemeMode.dark, l10n.darkMode, Icons.dark_mode_rounded),
      (ThemeMode.system, l10n.systemMode, Icons.settings_brightness_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: options.map((opt) {
          final isActive = opt.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(themeModeProvider.notifier).state = opt.$1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.$3,
                      size: 16,
                      color: isActive ? Colors.white : null,
                    ),
                    const Gap(4),
                    Flexible(
                      child: Text(
                        opt.$2,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale current,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final options = [
      (const Locale('vi'), l10n.vietnamese, '🇻🇳'),
      (const Locale('en'), l10n.english, '🇬🇧'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: options.map((opt) {
          final isActive = opt.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).state = opt.$1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(opt.$3, style: const TextStyle(fontSize: 18)),
                    const Gap(8),
                    Text(
                      opt.$2,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                .withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(16),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await signOutFromGoogle();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _handleDeleteData(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transactionDeleted),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
