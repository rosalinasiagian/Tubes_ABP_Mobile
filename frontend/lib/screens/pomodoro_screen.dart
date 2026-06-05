import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // ── State Timer ──────────────────────────────────────────
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  String _currentMode = 'Pomodoro';
  Timer? _timer;

  // ── Durasi (menit) ───────────────────────────────────────
  int _pomodoroDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  // ── Pengaturan Sesi ──────────────────────────────────────
  int _longBreakAfter = 4; // sesi sebelum long break (slider)
  bool _autoStartNext = false; // Mulai sesi berikutnya otomatis
  bool _soundNotification = true; // Suara notifikasi
  bool _browserNotifGranted = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings: initSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    if (!_browserNotifGranted) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifikasi untuk timer Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  // ── Timer Logic ──────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _stopTimer();
          if (_soundNotification || _browserNotifGranted) {
             _showNotification("Waktu Habis!", "Sesi $_currentMode telah selesai.");
          }
          if (_autoStartNext) {
             _skipTimer();
             _startTimer();
          } else {
             _skipTimer();
          }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      if (_currentMode == 'Pomodoro') {
        _timeLeft = _pomodoroDuration * 60;
      } else if (_currentMode == 'Short Break') {
        _timeLeft = _shortBreakDuration * 60;
      } else {
        _timeLeft = _longBreakDuration * 60;
      }
    });
  }

  void _skipTimer() {
    _stopTimer();
    setState(() {
      if (_currentMode == 'Pomodoro') {
        _currentMode = 'Short Break';
        _timeLeft = _shortBreakDuration * 60;
      } else if (_currentMode == 'Short Break') {
        _currentMode = 'Pomodoro';
        _timeLeft = _pomodoroDuration * 60;
      } else {
        _currentMode = 'Pomodoro';
        _timeLeft = _pomodoroDuration * 60;
      }
    });
  }

  void _setMode(String mode, int timeInSeconds) {
    _stopTimer();
    setState(() {
      _currentMode = mode;
      _timeLeft = timeInSeconds;
    });
  }

  void _changeDuration(String type, int delta) {
    setState(() {
      if (type == 'Pomodoro') {
        _pomodoroDuration = (_pomodoroDuration + delta).clamp(1, 60);
        if (_currentMode == 'Pomodoro') {
          _timeLeft = _pomodoroDuration * 60;
          _stopTimer();
        }
      } else if (type == 'Istirahat Pendek') {
        _shortBreakDuration = (_shortBreakDuration + delta).clamp(1, 30);
        if (_currentMode == 'Short Break') {
          _timeLeft = _shortBreakDuration * 60;
          _stopTimer();
        }
      } else if (type == 'Istirahat Panjang') {
        _longBreakDuration = (_longBreakDuration + delta).clamp(1, 60);
        if (_currentMode == 'Long Break') {
          _timeLeft = _longBreakDuration * 60;
          _stopTimer();
        }
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();

        return Scaffold(
          backgroundColor: t.background,
          extendBody: true,
          appBar: const TopNavigation(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
                top: 20, left: 20, right: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Judul ──────────────────────────────────
                Text(
                  'Timer Fokus',
                  style: GoogleFonts.montserrat(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Kartu Timer ────────────────────────────
                _buildTimerCard(t),
                const SizedBox(height: 32),

                // ── Durasi Sesi ────────────────────────────
                _buildSectionTitle('Durasi Sesi', t),
                const SizedBox(height: 16),
                _buildDurationCard(
                  label: 'Pomodoro',
                  value: _pomodoroDuration,
                  t: t,
                  onDecrement: () => _changeDuration('Pomodoro', -1),
                  onIncrement: () => _changeDuration('Pomodoro', 1),
                ),
                _buildDurationCard(
                  label: 'Istirahat Pendek',
                  value: _shortBreakDuration,
                  t: t,
                  onDecrement: () => _changeDuration('Istirahat Pendek', -1),
                  onIncrement: () => _changeDuration('Istirahat Pendek', 1),
                ),
                _buildDurationCard(
                  label: 'Istirahat Panjang',
                  value: _longBreakDuration,
                  t: t,
                  onDecrement: () => _changeDuration('Istirahat Panjang', -1),
                  onIncrement: () => _changeDuration('Istirahat Panjang', 1),
                ),
                const SizedBox(height: 32),

                // ── Fitur Cerdas & Target ──────────────────
                _buildSectionTitle('Fitur Cerdas & Target', t),
                const SizedBox(height: 16),
                _buildLongBreakSlider(t),
                const SizedBox(height: 16),
                _buildSmartFeaturesCards(t),
              ],
            ),
          ),
          bottomNavigationBar: const BotNavigation(currentIndex: 4),
        );
      },
    );
  }

  // ── WIDGET: Kartu Timer ──────────────────────────────────
  Widget _buildTimerCard(TemaData t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            // Glow biru faint — mempertahankan nuansa web
            color: const Color(0xFF60A5FA).withOpacity(t.isDark ? 0.0 : 0.10),
            blurRadius: 50,
            spreadRadius: 0,
          ),
        ],
        gradient: t.isDark
            ? LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.center,
                colors: [
                  // Biru sangat tipis agar tidak terlalu mencolok di dark
                  const Color(0xff00428e).withOpacity(0.03),
                  t.surface,
                ],
              )
            : const LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.center,
                colors: [
                  Color(0xFFDBEAFE), // blue-100 — biru pastel lembut
                  Colors.white,
                ],
              ),
      ),
      child: Column(
        children: [
          // Toggle mode tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.isDark ? t.background : t.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                _buildModeTab('Pomodoro', _pomodoroDuration * 60, t),
                _buildModeTab('Short Break', _shortBreakDuration * 60, t),
                _buildModeTab('Long Break', _longBreakDuration * 60, t),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Waktu
          Text(
            _formatTime(_timeLeft),
            style: GoogleFonts.montserrat(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: t.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isRunning ? 'Fokus! Kamu pasti bisa.' : 'Siap untuk mulai?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 40),

          // Tombol: Reset | Play/Pause | Skip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Tombol Reset ──────────────────────────
              _buildCircleOutlineBtn(
                icon: Icons.refresh_rounded,
                size: 56,
                iconSize: 26,
                onTap: _resetTimer,
                t: t,
              ),
              const SizedBox(width: 20),

              // ── Tombol Play / Pause ───────────────────
              GestureDetector(
                onTap: _isRunning ? _stopTimer : _startTimer,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // ── Tombol Skip ───────────────────────────
              _buildCircleOutlineBtn(
                icon: Icons.skip_next_rounded,
                size: 56,
                iconSize: 28,
                onTap: _skipTimer,
                t: t,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Fitur Cerdas & Target ──────────────────────
  Widget _buildLongBreakSlider(TemaData t) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Long Break Setelah:',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.isDark ? t.background : t.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: Text(
                  '$_longBreakAfter Sesi',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: t.accent,
              inactiveTrackColor: t.border,
              thumbColor: t.accent,
              overlayColor: t.accent.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _longBreakAfter.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              onChanged: (val) =>
                  setState(() => _longBreakAfter = val.round()),
            ),
          ),
          Text(
            'Atur kapan kamu ingin istirahat panjang.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFeaturesCards(TemaData t) {
    return Column(
      children: [
        // ── Card 1: Mulai sesi otomatis (Biru) ───
        GestureDetector(
          onTap: () => setState(() => _autoStartNext = !_autoStartNext),
          child: _buildColoredToggleCard(
            icon: Icons.bolt_outlined,
            title: 'Mulai sesi berikutnya otomatis',
            isOn: _autoStartNext,
            colorScheme: const Color(0xFF1D4ED8), // Biru gelap
            bgColor: const Color(0xFFEFF6FF), // Biru sangat muda
            borderColor: const Color(0xFFBFDBFE), // Biru muda border
            t: t,
          ),
        ),
        const SizedBox(height: 12),

        // ── Card 2: Suara notifikasi (Hijau) ───
        GestureDetector(
          onTap: () => setState(() => _soundNotification = !_soundNotification),
          child: _buildColoredToggleCard(
            icon: Icons.volume_up_outlined,
            title: 'Suara notifikasi',
            isOn: _soundNotification,
            colorScheme: const Color(0xFF047857), // Hijau gelap
            bgColor: const Color(0xFFF0FDF4), // Hijau sangat muda
            borderColor: const Color(0xFFBBF7D0), // Hijau muda border
            t: t,
          ),
        ),
        const SizedBox(height: 12),

        // ── Card 3: Notifikasi Perangkat ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Icon(
                _browserNotifGranted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: _browserNotifGranted ? t.textPrimary : t.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Perangkat',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _browserNotifGranted
                          ? 'Aktif dan siap dipakai'
                          : 'Belum diizinkan',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Tombol Aktifkan
                  GestureDetector(
                    onTap: () async {
                      // Request permission for iOS
                      final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
                          IOSFlutterLocalNotificationsPlugin>();
                      if (iosPlugin != null) {
                        final granted = await iosPlugin.requestPermissions(
                          alert: true,
                          badge: true,
                          sound: true,
                        );
                        setState(() => _browserNotifGranted = granted ?? true);
                      } else {
                        // For Android
                        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
                            AndroidFlutterLocalNotificationsPlugin>();
                        if (androidPlugin != null) {
                           final granted = await androidPlugin.requestNotificationsPermission();
                           setState(() => _browserNotifGranted = granted ?? true);
                        } else {
                           setState(() => _browserNotifGranted = true);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.isDark ? t.background : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.border),
                      ),
                      child: Text(
                        'Aktifkan',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Tes
                  GestureDetector(
                    onTap: () async {
                      if (_browserNotifGranted) {
                        await _showNotification('Tes Notifikasi', 'Ini adalah tes notifikasi dari Pomodoro Godone.');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🔔 Notifikasi tes dikirim!',
                                style: GoogleFonts.montserrat(fontSize: 13),
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Harap aktifkan notifikasi terlebih dahulu',
                              style: GoogleFonts.montserrat(fontSize: 13),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // Biru solid
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tes',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColoredToggleCard({
    required IconData icon,
    required String title,
    required bool isOn,
    required Color colorScheme,
    required Color bgColor,
    required Color borderColor,
    required TemaData t,
  }) {
    final bool useColor = isOn && !t.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: useColor ? bgColor : t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: useColor ? borderColor : t.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOn ? colorScheme : t.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOn ? colorScheme : t.textPrimary,
              ),
            ),
          ),
          Text(
            isOn ? 'ON' : 'OFF',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isOn ? colorScheme : t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET HELPERS ───────────────────────────────────────

  Widget _buildModeTab(String title, int time, TemaData t) {
    final bool isSelected = _currentMode == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(title, time),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? t.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(t.isDark ? 0.2 : 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title.split(' ')[0],
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? t.textPrimary : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, TemaData t) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: t.textPrimary,
      ),
    );
  }

  Widget _buildDurationCard({
    required String label,
    required int value,
    required TemaData t,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildStepBtn(Icons.remove, t, onDecrement),
              SizedBox(
                width: 65,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MNT',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStepBtn(Icons.add, t, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, TemaData t, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: t.isDark ? t.background : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.border),
        ),
        child: Icon(icon, size: 14, color: t.textSecondary),
      ),
    );
  }

  // Tombol bulat outline (Reset & Skip)
  Widget _buildCircleOutlineBtn({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required TemaData t,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: t.isDark ? t.background : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: t.border, width: 2),
        ),
        child: Icon(
          icon,
          color: t.textSecondary,
          size: iconSize,
        ),
      ),
    );
  }

}
