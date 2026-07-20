import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentProfile = ref.read(myProfileProvider).valueOrNull;
      if (currentProfile != null) {
        setState(() {
          _nameController.text = currentProfile.fullName;
          _currentAvatarUrl = currentProfile.avatarUrl;
          _emailController.text = currentProfile.email ?? '';
          _phoneController.text = currentProfile.phoneNumber ?? '';

          // LƯU Ý: Bạn cần vào class Profile (trong profile_repository.dart hoặc file model)
          // và thêm thuộc tính: final bool? isPhoneVerified;
          // Sau đó bỏ comment dòng bên dưới. Tạm thời set false để code không báo lỗi đỏ.
          // _isPhoneVerified = currentProfile.isPhoneVerified ?? false;
          _isPhoneVerified = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // CHỨC NĂNG 1: CHỌN VÀ UPLOAD FILE ẢNH AVATAR THỰC TẾ LÊN BACKEND
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      String path = pickedFile.path;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(path, filename: pickedFile.name),
      });

      final response = await DioClient.instance.post('/Profiles/me/avatar', data: formData);

      // Chặn lỗi BuildContext across async gaps
      if (!mounted) return;

      setState(() {
        _currentAvatarUrl = response.data['avatarUrl'];
      });

      ref.invalidate(myProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!'), backgroundColor: kSecondary)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload file: $e'), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  // CHỨC NĂNG 2: XÁC THỰC SỐ ĐIỆN THOẠI QUA SĐT VÀ OTP DIALOG
  Future<void> _handleVerifyPhoneFlow() async {
    try {
      await DioClient.instance.post('/Auth/send-phone-otp');

      // Chặn lỗi BuildContext across async gaps
      if (!mounted) return;

      final otpController = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xác thực SMS OTP'),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'Nhập mã 6 số OTP'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy')
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DioClient.instance.post('/Auth/verify-phone', data: {
                    'phoneNumber': _phoneController.text.trim(),
                    'otpCode': otpController.text.trim(),
                  });

                  // Chặn lỗi BuildContext across async gaps
                  if (!mounted) return;

                  setState(() => _isPhoneVerified = true);
                  ref.invalidate(myProfileProvider);

                  Navigator.pop(dialogContext); // Đóng dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xác thực số điện thoại thành công!'), backgroundColor: kSecondary)
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mã OTP sai hoặc hết hạn.'))
                  );
                }
              },
              child: const Text('Xác nhận'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi OTP: $e'))
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        fullName: _nameController.text.trim(),
        avatarUrl: _currentAvatarUrl,
      );

      // Chặn lỗi BuildContext across async gaps
      if (!mounted) return;

      ref.invalidate(myProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: kSecondary)
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: kPrimaryContainer,
                    backgroundImage: _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty ? NetworkImage(_currentAvatarUrl!) : null,
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator()
                        : (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty ? const Icon(Icons.person_rounded, size: 50, color: kPrimary) : null),
                  ),
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Họ và tên', prefixIcon: const Icon(Icons.person_outline_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: _isPhoneVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(onPressed: _handleVerifyPhoneFlow, child: const Text('Xác minh', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: _isLoading ? null : _handleSave,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi'),
          ),
        ),
      ),
    );
  }
}