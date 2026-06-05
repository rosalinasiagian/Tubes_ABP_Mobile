import 'package:flutter/material.dart';

class TemaData extends ChangeNotifier {
  // Singleton pattern agar state tema sama persis di seluruh halaman aplikasi
  static final TemaData _instance = TemaData._internal();
  factory TemaData() => _instance;
  TemaData._internal();

  bool _isDark = false;
  bool get isDark => _isDark;

  // Fungsi untuk mengubah tema (dipanggil dari tombol bulan/matahari di Top Navigation)
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners(); // Memberitahu semua ListenableBuilder untuk me-refresh layar otomatis
  }

  // ==========================================
  // PALET WARNA DINAMIS (Light Mode & Dark Mode)
  // ==========================================

  // Warna latar belakang utama Scaffold
  Color get background =>
      isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);

  // Warna latar belakang Kartu (Card), Bottom Nav, dll
  Color get surface => isDark ? const Color(0xFF18181B) : Colors.white;

  // Warna latar belakang alternatif (untuk textfield, dropdown, atau card minor)
  Color get surfaceVariant =>
      isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9);

  // Warna garis tepi (border)
  Color get border =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0);

  // Warna garis pemisah (divider)
  Color get divider =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0);

  // Warna teks utama (Judul, angka penting)
  Color get textPrimary =>
      isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1E293B);

  // Warna teks sekunder (Subtitle, deskripsi, placeholder)
  Color get textSecondary =>
      isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);

  // Warna aksen utama aplikasi (Biru GoDone)
  Color get accent => const Color(0xFF364C84);

  // Warna aksen versi pudar/transparan (untuk background icon atau badge)
  Color get accentLight => isDark
      ? const Color(0xFF364C84).withOpacity(0.25)
      : const Color(0xFFEEF1FB);
}
