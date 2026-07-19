import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

class ReauthDialog extends ConsumerStatefulWidget {
  const ReauthDialog({super.key});

  @override
  ConsumerState<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<ReauthDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Gọi hàm reauthenticate từ AuthNotifier
    final reauthToken = await ref.read(authProvider.notifier).reauthenticate(password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (reauthToken != null) {
        // Trả về token cho hàm gọi Dialog
        Navigator.of(context).pop(reauthToken);
      } else {
        setState(() => _errorMessage = 'Mật khẩu không chính xác.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác thực danh tính', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Vui lòng nhập lại mật khẩu của bạn để tiếp tục thực hiện hành động này.'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              errorText: _errorMessage,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
          )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}