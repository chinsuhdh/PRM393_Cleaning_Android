import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_helper.dart';
import '../../../data/models/user_address.dart';
import '../../../data/repositories/user_address_repository.dart';
import '../../shared/app_error_view.dart';
import '../../shared/app_loading_indicator.dart';
import '../../shared/app_snackbar.dart';
import '../../shared/popup_menu_action_item.dart';

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  Future<void> _deleteAddress(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(userAddressRepositoryProvider).deleteAddress(id);
      ref.invalidate(savedAddressesProvider);
      if (context.mounted) showAppSuccessSnackBar(context, 'Đã xóa!');
    } on AppException catch (e) {
      if (context.mounted) showAppErrorSnackBar(context, e);
    }
  }

  Future<void> _setDefaultAddress(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(userAddressRepositoryProvider).setDefaultAddress(id);
      ref.invalidate(savedAddressesProvider);
    } on AppException catch (e) {
      if (context.mounted) showAppErrorSnackBar(context, e);
    }
  }

  void _showAddressBottomSheet(BuildContext context, WidgetRef ref, {UserAddress? existingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => AddressBottomSheet(
        initialData: existingAddress,
        onAddressSaved: () => ref.invalidate(savedAddressesProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addressesAsync = ref.watch(savedAddressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Địa chỉ đã lưu', style: TextStyle(fontWeight: FontWeight.w800))),
      body: addressesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => AppErrorView(error: e, onRetry: () => ref.invalidate(savedAddressesProvider)),
        data: (addresses) => addresses.isEmpty
            ? const Center(child: Text('Bạn chưa có địa chỉ nào.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final addr = addresses[i];
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: kPrimaryContainer, borderRadius: BorderRadius.circular(12)),
                            child: Icon(addr.label.toLowerCase() == 'home' ? Icons.home_rounded : Icons.business_rounded, color: kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        addr.label.isEmpty ? 'Địa chỉ' : addr.label,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (addr.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Mặc định', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.bold)),
                                      )
                                    ]
                                  ],
                                ),
                                Text(addr.addressText, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteAddress(context, ref, addr.id);
                              } else if (value == 'set_default') {
                                _setDefaultAddress(context, ref, addr.id);
                              } else if (value == 'edit') {
                                _showAddressBottomSheet(context, ref, existingAddress: addr);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!addr.isDefault)
                                const PopupMenuItem(
                                  value: 'set_default',
                                  child: PopupMenuActionItem(icon: Icons.check_circle_outline_rounded, label: 'Đặt mặc định'),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: PopupMenuActionItem(icon: Icons.edit_outlined, label: 'Chỉnh sửa'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: PopupMenuActionItem(icon: Icons.delete_outline_rounded, label: 'Xóa', color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressBottomSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm địa chỉ'),
        backgroundColor: kPrimary,
      ),
    );
  }
}

class AddressBottomSheet extends ConsumerStatefulWidget {
  final UserAddress? initialData;
  final VoidCallback onAddressSaved;
  const AddressBottomSheet({super.key, this.initialData, required this.onAddressSaved});
  @override
  ConsumerState<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends ConsumerState<AddressBottomSheet> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  double? _lat, _lng;
  bool _isFetchingGPS = false, _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController.text = widget.initialData?.label ?? '';
    _addressController.text = widget.initialData?.addressText ?? '';
    _lat = widget.initialData?.latitude;
    _lng = widget.initialData?.longitude;
  }

  Future<void> _handleAutoLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      final loc = await LocationHelper.getCurrentAddress();
      if (loc != null) {
        setState(() {
          _addressController.text = loc['addressText'];
          _lat = loc['latitude'];
          _lng = loc['longitude'];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingGPS = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ trước khi lưu!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final address = UserAddress(
      id: widget.initialData?.id ?? '',
      label: _labelController.text.trim(),
      addressText: _addressController.text.trim(),
      latitude: _lat,
      longitude: _lng,
      isDefault: widget.initialData?.isDefault ?? false,
    );

    try {
      final repository = ref.read(userAddressRepositoryProvider);
      if (widget.initialData != null) {
        await repository.updateAddress(widget.initialData!.id, address);
      } else {
        await repository.createAddress(address);
      }
      widget.onAddressSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    } on AppException catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Nhãn')),
            TextField(
                controller: _addressController,
                decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    suffixIcon: _isFetchingGPS
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                    )
                        : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _handleAutoLocation
                    )
                )
            ),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu')
            ),
          ]
      ),
    );
  }
}