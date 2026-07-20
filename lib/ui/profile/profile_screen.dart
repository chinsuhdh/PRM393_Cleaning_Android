import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../shared/reauth_dialog.dart';
import '../shared/logout_action.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) {
          final name = authState.userName ?? 'User';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
          return _ProfileBody(
            name: name,
            email: '',
            phone: '',
            initials: initials,
            avatarUrl: null,
            bookingCount: 0,
            savedCount: 0,
          );
        },
        data: (profile) => _ProfileBody(
          name: profile.fullName,
          email: profile.email ?? '',
          phone: profile.phoneNumber ?? '',
          initials: profile.initials,
          avatarUrl: profile.avatarUrl,
          bookingCount: profile.bookingCount ?? 0,
          savedCount: profile.savedCount ?? 0,
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final String name;
  final String email;
  final String phone;
  final String initials;
  final String? avatarUrl;

  final int bookingCount;
  final int savedCount;

  const _ProfileBody({
    required this.name,
    required this.email,
    required this.phone,
    required this.initials,
    this.avatarUrl,
    required this.bookingCount,
    required this.savedCount,
  });

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final reauthToken = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReauthDialog(),
    );

    if (reauthToken == null) return;

    try {
      final response = await DioClient.instance.delete(
        '/Profiles/delete-account',
        options: Options(
          headers: {
            'X-Reauth-Token': reauthToken
          },
        ),
      );

      if (response.statusCode == 200 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài khoản thành công')),
        );
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.response?.data['message'] ?? 'Không thể xóa tài khoản'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceBottomSheet(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Giao diện',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildThemeOption(context, ref, 'Mặc định hệ thống', ThemeMode.system, currentTheme, Icons.settings_suggest_outlined),
            _buildThemeOption(context, ref, 'Chế độ sáng', ThemeMode.light, currentTheme, Icons.light_mode_outlined),
            _buildThemeOption(context, ref, 'Chế độ tối', ThemeMode.dark, currentTheme, Icons.dark_mode_outlined),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String title, ThemeMode mode, ThemeMode currentTheme, IconData icon) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentTheme,
      title: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      onChanged: (ThemeMode? value) {
        if (value != null) {
          ref.read(themeModeProvider.notifier).state = value;
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    final currentTheme = ref.watch(themeModeProvider);
    final themeSubtitle = currentTheme == ThemeMode.system
        ? 'Mặc định hệ thống'
        : currentTheme == ThemeMode.light
        ? 'Chế độ sáng'
        : 'Chế độ tối';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: kPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => confirmAndLogout(context, ref),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: kPrimary,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                    child: !hasAvatar
                        ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kOnPrimaryContainer,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: kOnPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: kOnPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: bookingCount.toString(),
                label: 'Đơn đặt lịch',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                value: savedCount.toString(),
                label: 'Đã lưu',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _SectionHeader(title: 'Tài khoản'),
        _ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Chỉnh sửa hồ sơ',
          onTap: () => context.push('/profile/edit'),
        ),
        _ProfileMenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Đổi mật khẩu',
          onTap: () => context.push('/profile/change-password'),
        ),
        _ProfileMenuItem(
          icon: Icons.location_on_outlined,
          title: 'Địa chỉ đã lưu',
          onTap: () => context.push('/address'),
        ),
        _ProfileMenuItem(
          icon: Icons.history_rounded,
          title: 'Lịch sử đặt lịch',
          onTap: () => context.push('/bookings'),
        ),

        const SizedBox(height: 8),

        _SectionHeader(title: 'Tùy chọn'),
        _ProfileMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Thông báo',
          onTap: () => context.push('/notifications'),
        ),
        _ProfileMenuItem(
          icon: Icons.dark_mode_outlined,
          title: 'Giao diện',
          subtitle: themeSubtitle,
          onTap: () => _showAppearanceBottomSheet(context, ref),
        ),

        const SizedBox(height: 8),

        _SectionHeader(title: 'Hỗ trợ'),
        _ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Trợ giúp & Hỗ trợ',
          onTap: () {
            _showInfoDialog(
                context,
                'Trợ giúp & Hỗ trợ',
                'Nếu bạn gặp bất kỳ sự cố nào khi sử dụng CleanAI, vui lòng liên hệ với chúng tôi qua:\n\nEmail: support@cleanai.com\nHotline: 1900-xxxx\n\nThời gian làm việc: 8:00 - 17:00 (Thứ 2 - Thứ 6)'
            );
          },
        ),
        _ProfileMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Chính sách bảo mật',
          onTap: () {
            _showInfoDialog(
                context,
                'Chính sách bảo mật',
                'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn. Dữ liệu của bạn (email, số điện thoại, địa chỉ) chỉ được sử dụng cho mục đích cung cấp dịch vụ vệ sinh và kết nối với Worker.\n\nCleanAI không chia sẻ dữ liệu này cho bên thứ ba vì mục đích quảng cáo mà không có sự đồng ý của bạn.'
            );
          },
        ),

        _ProfileMenuItem(
          icon: Icons.delete_forever_rounded,
          title: 'Xóa tài khoản',
          itemColor: Colors.red,
          onTap: () => _handleDeleteAccount(context, ref),
        ),

        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? itemColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.itemColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = itemColor ?? theme.colorScheme.onSurfaceVariant;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: itemColor != null
              ? itemColor!.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: displayColor, size: 22),
      ),
      title: Text(title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: itemColor,
          )),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}