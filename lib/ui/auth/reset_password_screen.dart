import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/dio_client.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'email': _emailController.text.trim(),
        'otpCode': _otpController.text.trim(),
        'newPassword': _passwordController.text
      };

      await DioClient.instance.post('/Auth/reset-password', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP không chính xác hoặc đã hết hạn.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đặt lại mật khẩu', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary)),
                const SizedBox(height: 8),
                Text('Nhập mã OTP được gửi tới email cùng mật khẩu mới của bạn.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập Email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                  decoration: InputDecoration(counterText: "", hintText: "Nhập mã OTP 6 số", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  validator: (v) => v == null || v.length < 6 ? 'Vui lòng nhập đủ 6 số OTP' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Mật khẩu phải chứa ít nhất 6 ký tự' : null,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận đặt lại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}