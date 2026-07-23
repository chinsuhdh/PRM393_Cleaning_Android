import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/auth/auth_state.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/reauth_dialog.dart';
import '../../shared/logout_action.dart';
import 'widgets/appearance_bottom_sheet.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final authState = ref.watch(authNotifierProvider);

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
          bookingCount: profile.bookingCount,
          savedCount: profile.savedCount,
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
      await ref.read(profileRepositoryProvider).deleteAccount(reauthToken);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài khoản thành công')),
        );
        ref.read(authNotifierProvider.notifier).logout();
        context.go('/login');
      }
    } on AppException catch (e) {
      if (context.mounted) {
        showAppErrorSnackBar(context, e);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    final currentTheme = ref.watch(appThemeModeProvider);
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
              child: ProfileStatCard(
                value: bookingCount.toString(),
                label: 'Đơn đặt lịch',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ProfileStatCard(
                value: savedCount.toString(),
                label: 'Đã lưu',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ProfileSectionHeader(title: 'Tài khoản'),
        ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Chỉnh sửa hồ sơ',
          onTap: () => context.push('/profile/edit'),
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Đổi mật khẩu',
          onTap: () => context.push('/profile/change-password'),
        ),
        ProfileMenuItem(
          icon: Icons.location_on_outlined,
          title: 'Địa chỉ đã lưu',
          onTap: () => context.push('/address'),
        ),
        ProfileMenuItem(
          icon: Icons.history_rounded,
          title: 'Lịch sử đặt lịch',
          onTap: () => context.push('/bookings'),
        ),

        const SizedBox(height: 8),

        ProfileSectionHeader(title: 'Tùy chọn'),
        ProfileMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Thông báo',
          onTap: () => context.push('/notifications'),
        ),
        ProfileMenuItem(
          icon: Icons.dark_mode_outlined,
          title: 'Giao diện',
          subtitle: themeSubtitle,
          onTap: () => showAppearanceBottomSheet(context, ref),
        ),

        const SizedBox(height: 8),

        ProfileSectionHeader(title: 'Hỗ trợ'),
        ProfileMenuItem(
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
        ProfileMenuItem(
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

        ProfileMenuItem(
          icon: Icons.delete_forever_rounded,
          title: 'Xóa tài khoản',
          itemColor: Colors.red,
          onTap: () => _handleDeleteAccount(context, ref),
        ),

        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () {
            ref.read(authNotifierProvider.notifier).logout();
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

