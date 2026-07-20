import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/worker_repository.dart';
import '../../data/services/worker_location_sender.dart';
import '../worker/worker_active_job_bar.dart';
import '../worker/widgets/worker_suspension_banner.dart';
import 'active_booking_bar.dart';

class ClientShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ClientShell({super.key, required this.navigationShell});

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Trang chủ',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt_rounded),
      label: 'Đơn đặt lịch',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Trợ lý AI',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: 'Thông báo',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Hồ sơ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ActiveBookingBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: _destinations,
            animationDuration: const Duration(milliseconds: 400),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ],
      ),
    );
  }
}

class WorkerShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const WorkerShell({super.key, required this.navigationShell});

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Tổng quan',
    ),
    NavigationDestination(
      icon: Icon(Icons.work_outline_rounded),
      selectedIcon: Icon(Icons.work_rounded),
      label: 'Công việc',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Thu nhập',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineStatus = ref.watch(workerOnlineStatusProvider).valueOrNull;
    if (onlineStatus != null && onlineStatus != WorkerOnlineStatus.offline) {
      ref.watch(workerLocationSenderProvider);
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkerSuspensionBanner(),
          const WorkerActiveJobBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: _destinations,
          ),
        ],
      ),
    );
  }
}
