import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/service_catalog_repository.dart';

part 'service_detail_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> servicesByCategory(Ref ref, String categoryId) async {
  return ref.read(serviceCatalogRepositoryProvider).getServicesByCategory(categoryId);
}

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  Map<String, dynamic>? _selectedService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesByCategoryProvider(widget.serviceId));

    if (_selectedService == null && servicesAsync.hasValue && servicesAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedService = servicesAsync.value!.first);
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: kPrimaryContainer,
                child: const Center(child: Icon(Icons.cleaning_services_rounded, size: 80, color: kPrimary)),
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.arrow_back_rounded, color: Colors.black)),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: servicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Lỗi tải dịch vụ: $e', style: const TextStyle(color: Colors.red)),
                data: (services) {
                  if (services.isEmpty) {
                    return const Center(child: Text('Danh mục này chưa có dịch vụ nào trong Database.'));
                  }

                  final name = _selectedService?['name'] ?? 'Đang tải...';
                  final price = _selectedService?['basePrice'] ?? _selectedService?['price'] ?? 0;
                  final description = _selectedService?['description'] ?? 'Chưa có mô tả.';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chọn gói dịch vụ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services.map((s) {
                          final isSelected = _selectedService?['id'] == s['id'];
                          return ChoiceChip(
                            label: Text(s['name'] ?? ''),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedService = s);
                            },
                            selectedColor: kPrimaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Text('Giá: $price VND / giờ', style: theme.textTheme.titleLarge?.copyWith(color: kPrimary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      Text('Mô tả', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(description, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          onPressed: _selectedService == null ? null : () => context.push('/booking/create/${_selectedService!['id']}'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Đặt dịch vụ này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}