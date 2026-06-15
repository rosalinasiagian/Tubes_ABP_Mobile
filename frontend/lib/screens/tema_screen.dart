import 'package:flutter/material.dart';

class TemaData extends ChangeNotifier {
  static final TemaData _instance = TemaData._internal();
  factory TemaData() => _instance;
  TemaData._internal();

  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  Color get background =>
      isDark ? const Color(0xFF08111F) : const Color(0xFFF6F8FC);

  Color get surface => isDark ? const Color(0xFF101826) : Colors.white;

  Color get surfaceVariant =>
      isDark ? const Color(0xFF172238) : const Color(0xFFEEF4FF);

  Color get border =>
      isDark ? const Color(0xFF25334A) : const Color(0xFFD8E1F0);

  Color get divider =>
      isDark ? const Color(0xFF223049) : const Color(0xFFE3EAF5);

  Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0E1726);

  Color get textSecondary =>
      isDark ? const Color(0xFF9AA8BD) : const Color(0xFF5B677A);

  Color get accent => const Color(0xFF2563EB);

  Color get accentDark => const Color(0xFF1E40AF);

  Color get accentLight =>
      isDark ? const Color(0xFF132C5B) : const Color(0xFFEAF1FF);

  Color get success => const Color(0xFF10B981);

  Color get warning => const Color(0xFFF59E0B);

  Color get danger => const Color(0xFFEF4444);

  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
      );

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}
