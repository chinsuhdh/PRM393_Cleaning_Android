import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/user_address.dart';

class BookingAddressStep extends StatelessWidget {
  const BookingAddressStep({
    super.key,
    required this.addressesAsync,
    required this.selectedAddress,
    required this.onAddressSelected,
    required this.onAddAddressPressed,
    required this.onRetryAddresses,
  });

  final AsyncValue<List<UserAddress>> addressesAsync;
  final UserAddress? selectedAddress;
  final ValueChanged<UserAddress> onAddressSelected;
  final VoidCallback onAddAddressPressed;
  final VoidCallback onRetryAddresses;

  Widget _addressTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String addressText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: isSelected ? kPrimaryContainer : Colors.grey.shade100,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? kPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(icon, color: isSelected ? kPrimary : Colors.grey),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? kOnPrimaryContainer : Colors.black,
              ),
            ),
            subtitle: Text(
              addressText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: kPrimary) : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn địa chỉ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: addressesAsync.when(
            data: (addresses) {
              if (addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bạn chưa có địa chỉ để đặt dịch vụ.'),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onAddAddressPressed,
                        child: const Text('Thêm địa chỉ'),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                children: [
                  ...List.generate(addresses.length, (index) {
                    final address = addresses[index];
                    final isSelected = selectedAddress?.id == address.id;

                    return _addressTile(
                      context: context,
                      icon: Icons.location_on_rounded,
                      label: address.label.isEmpty ? 'Địa chỉ' : address.label,
                      addressText: address.addressText,
                      isSelected: isSelected,
                      onTap: () => onAddressSelected(address),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: onAddAddressPressed,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm địa chỉ mới'),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không thể tải danh sách địa chỉ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onRetryAddresses,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
