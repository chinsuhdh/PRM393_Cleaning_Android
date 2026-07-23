import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/user_address.dart';

part 'user_address_repository.g.dart';

abstract class UserAddressRepository {
  Future<List<UserAddress>> getAddresses();
  Future<UserAddress> createAddress(UserAddress address);
  Future<void> updateAddress(String id, UserAddress address);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);
}

class ApiUserAddressRepository implements UserAddressRepository {
  ApiUserAddressRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<UserAddress>> getAddresses() => guardApiCall(() async {
    final response = await _dio.get('/UserAddresses');
    final raw = response.data;
    if (raw is! List) return [];
    final addresses = raw.whereType<Map<String, dynamic>>().map(UserAddress.fromJson).toList();
    addresses.sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
    return addresses;
  });

  @override
  Future<UserAddress> createAddress(UserAddress address) => guardApiCall(() async {
    final response = await _dio.post('/UserAddresses', data: address.toJson());
    return UserAddress.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> updateAddress(String id, UserAddress address) => guardApiCall(() async {
    await _dio.put('/UserAddresses/$id', data: address.toJson());
  });

  @override
  Future<void> deleteAddress(String id) => guardApiCall(() async {
    await _dio.delete('/UserAddresses/$id');
  });

  @override
  Future<void> setDefaultAddress(String id) => guardApiCall(() async {
    await _dio.patch('/UserAddresses/$id/set-default');
  });
}

@Riverpod(keepAlive: true)
UserAddressRepository userAddressRepository(Ref ref) {
  return ApiUserAddressRepository(ref.read(dioProvider));
}

@riverpod
Future<List<UserAddress>> savedAddresses(Ref ref) async {
  return ref.read(userAddressRepositoryProvider).getAddresses();
}
