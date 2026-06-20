import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static final RegExp _numberRegExp = RegExp(r'[0-9]');
  static final RegExp _specialCharRegExp = RegExp(
    r'''[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/+=;'`~]''',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.trim().length >= 8;

  bool get _hasNumber => _numberRegExp.hasMatch(_passwordController.text);

  bool get _hasSpecialChar =>
      _specialCharRegExp.hasMatch(_passwordController.text);

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  bool get _isPasswordStrong => _hasMinLength && _hasNumber && _hasSpecialChar;

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Masukkan email yang valid';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password wajib diisi';
    if (password.length < 8) return 'Minimal 8 karakter';
    if (!_numberRegExp.hasMatch(password))
      return 'Harus mengandung minimal 1 angka';
    if (!_specialCharRegExp.hasMatch(password)) {
      return 'Harus mengandung minimal 1 karakter khusus';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password wajib diisi';
    if (!_passwordsMatch) return 'Password tidak sama';
    return null;
  }

  void _showTopNotification(String message, {bool isError = true}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
            },
            child: const Text('TUTUP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .createUserWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      // Supaya tidak otomatis login dan pindah ke halaman utama,
      // kita sign out akun yang baru jadi ini segera setelah registrasi.
      await ref.read(authServiceProvider).signOut();

      if (mounted) {
        _showTopNotification(
          'Akun berhasil dibuat! Silakan login kembali.',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification(e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordRules = [
      (label: 'Minimal 8 karakter', isMet: _hasMinLength),
      (label: 'Minimal 1 angka', isMet: _hasNumber),
      (label: 'Minimal 1 karakter khusus', isMet: _hasSpecialChar),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FBFF), Color(0xFFF3F6FB)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 92,
                            height: 92,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Image.asset('lib/assets/logo_ra.png'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10203D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Buat akun baru dengan password yang lebih aman untuk melindungi data kendaraanmu.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF667085),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _emailValidator,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: _passwordValidator,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText:
                                'Gunakan kombinasi huruf, angka, dan karakter khusus.',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5EAF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Syarat password',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10203D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...passwordRules.map(
                                (rule) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: rule.isMet
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                        child: Icon(
                                          rule.isMet
                                              ? Icons.check
                                              : Icons.close,
                                          size: 13,
                                          color: rule.isMet
                                              ? Colors.white
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          rule.label,
                                          style: TextStyle(
                                            color: rule.isMet
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value:
                                    [
                                      _hasMinLength,
                                      _hasNumber,
                                      _hasSpecialChar,
                                    ].where((item) => item).length /
                                    3,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: _isPasswordStrong
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: _confirmPasswordValidator,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isLoading
                                  ? [
                                      const Color(0xFF7A8FAF),
                                      const Color(0xFF587197),
                                    ]
                                  : const [
                                      Color(0xFF0052CC),
                                      Color(0xFF0A7AFE),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0052CC,
                                ).withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Buat Akun',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Sudah punya akun? Masuk'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
