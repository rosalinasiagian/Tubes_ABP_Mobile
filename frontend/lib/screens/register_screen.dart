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

  final TextEditingController _namaDepanController = TextEditingController();
  final TextEditingController _namaBelakangController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _namaDepanController.dispose();
    _namaBelakangController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final namaDepan = _namaDepanController.text.trim();
    final namaBelakang = _namaBelakangController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (namaDepan.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.register(
        firstName: namaDepan,
        lastName: namaBelakang,
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dibuat! Silakan masuk.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.montserrat(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
            onPressed: toggleObscure,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 30.0, right: 30.0, bottom: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset('assets/images/register_img.png', height: 200, fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          Text('Daftar', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
          const SizedBox(height: 5),
          Text('Buat akun baru untuk melanjutkan.', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // Nama Depan & Nama Belakang
          Row(
            children: [
              Expanded(child: _buildInputField(hint: 'Nama Depan', icon: Icons.person_outline, controller: _namaDepanController)),
              const SizedBox(width: 15),
              Expanded(child: _buildInputField(hint: 'Nama Belakang', icon: Icons.person_outline, controller: _namaBelakangController)),
            ],
          ),
          const SizedBox(height: 15),

          _buildInputField(hint: 'Username', icon: Icons.person, controller: _usernameController),
          const SizedBox(height: 15),

          _buildInputField(hint: 'Masukkan Email', icon: Icons.mail_outline, controller: _emailController),
          const SizedBox(height: 15),

          _buildInputField(
            hint: 'Masukkan Password',
            icon: Icons.lock,
            controller: _passwordController,
            isPassword: true,
            isObscure: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 15),

          _buildInputField(
            hint: 'Konfirmasi Password',
            icon: Icons.lock,
            controller: _confirmPasswordController,
            isPassword: true,
            isObscure: _obscureConfirmPassword,
            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF364C84).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF364C84),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Daftar', style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Wrap(
              children: [
                Text('Sudah punya akun? ', style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12)),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Text('Masuk', style: GoogleFonts.montserrat(color: const Color(0xFF364C84), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }
}