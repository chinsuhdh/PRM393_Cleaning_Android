import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/app_snackbar.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _oldVisible = false;
  bool _newVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryProvider).changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      if (mounted) {
        showAppSuccessSnackBar(context, 'Đổi mật khẩu thành công!');
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi Mật Khẩu', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: !_oldVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: const Icon(Icons.lock_open_rounded),
                  suffixIcon: IconButton(icon: Icon(_oldVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _oldVisible = !_oldVisible)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_newVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(icon: Icon(_newVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _newVisible = !_newVisible)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Mật khẩu mới tối thiểu 6 kí tự' : null,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isLoading ? null : _handleChangePassword,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật mật khẩu'),
              )
            ],
          ),
        ),
      ),
    );
  }
}