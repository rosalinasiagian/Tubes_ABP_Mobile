import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hasPasswordLength(String password) => password.length >= 8;
  bool _hasPasswordLetter(String password) =>
      RegExp(r'[A-Za-z]').hasMatch(password);
  bool _hasPasswordNumber(String password) =>
      RegExp(r'[0-9]').hasMatch(password);
  bool _hasPasswordSymbol(String password) =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  int _passwordScore(String password) {
    var score = 0;
    if (_hasPasswordLength(password)) score++;
    if (_hasPasswordLetter(password)) score++;
    if (_hasPasswordNumber(password)) score++;
    if (_hasPasswordSymbol(password)) score++;
    return score;
  }

  bool _isPasswordValid(String password) => _passwordScore(password) == 4;

  String _passwordStrengthLabel(String password) {
    final score = _passwordScore(password);
    if (password.isEmpty) return 'Belum diisi';
    if (score <= 2) return 'Lemah';
    if (score == 3) return 'Sedang';
    return password.length >= 12 ? 'Sangat kuat' : 'Kuat';
  }

  Color _passwordStrengthColor(String password) {
    final score = _passwordScore(password);
    if (password.isEmpty) return const Color(0xFF94A3B8);
    if (score <= 2) return const Color(0xFFEF4444);
    if (score == 3) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  double _passwordStrengthProgress(String password) {
    final score = _passwordScore(password);
    if (password.isEmpty) return 0;
    if (score <= 2) return 0.33;
    if (score == 3) return 0.66;
    return 1;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;
    await _submitRegistration();
  }

  bool _validateForm() {
    final firstName = _firstNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Nama depan, username, email, dan password wajib diisi');
      return false;
    }

    if (password != confirmPassword) {
      _showMessage('Password dan konfirmasi password tidak cocok');
      return false;
    }

    if (!_isPasswordValid(password)) {
      _showMessage(
          'Password minimal 8 karakter dan harus berisi huruf, angka, serta simbol');
      return false;
    }

    return true;
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Akun berhasil dibuat. Silakan masuk.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF1FF), Color(0xFFF8FAFC), Color(0xFFE7FFF8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/images/GoDone Logo.png',
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.20),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/register_img.png',
                        height: 155,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Buat akun baru',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0F172A),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atur task, deadline, dan fokus harianmu dari satu app.',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _AuthField(
                                  controller: _firstNameController,
                                  icon: Icons.person_outline_rounded,
                                  label: 'Nama depan',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AuthField(
                                  controller: _lastNameController,
                                  icon: Icons.badge_outlined,
                                  label: 'Nama belakang',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _usernameController,
                            icon: Icons.alternate_email_rounded,
                            label: 'Username',
                          ),
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _emailController,
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _passwordController,
                            icon: Icons.lock_outline_rounded,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordStrengthPanel(),
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _confirmPasswordController,
                            icon: Icons.verified_user_outlined,
                            label: 'Konfirmasi password',
                            obscureText: _obscureConfirmPassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (!_isLoading) _handleRegister();
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Daftar',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun?',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Masuk',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthPanel() {
    final password = _passwordController.text;
    final color = _passwordStrengthColor(password);
    final rules = [
      ('Minimal 8 karakter', _hasPasswordLength(password)),
      ('Ada huruf', _hasPasswordLetter(password)),
      ('Ada angka', _hasPasswordNumber(password)),
      ('Ada simbol', _hasPasswordSymbol(password)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kekuatan password',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _passwordStrengthLabel(password),
                style: GoogleFonts.montserrat(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _passwordStrengthProgress(password),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: rules.map((rule) {
              final passed = rule.$2;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passed
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 15,
                    color: passed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    rule.$1,
                    style: GoogleFonts.montserrat(
                      color: passed
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const _AuthField({
    required this.controller,
    required this.icon,
    required this.label,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      style: GoogleFonts.montserrat(
        color: const Color(0xFF0F172A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
