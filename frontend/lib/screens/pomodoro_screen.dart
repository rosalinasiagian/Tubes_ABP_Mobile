import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class _PomodoroController extends ChangeNotifier {
  static final _PomodoroController instance = _PomodoroController._();

  _PomodoroController._();

  int timeLeft = 25 * 60;
  bool isRunning = false;
  String currentMode = 'Pomodoro';
  Timer? _timer;

  int pomodoroDuration = 25;
  int shortBreakDuration = 5;
  int longBreakDuration = 15;

  int longBreakAfter = 4;
  int completedPomodoroSessions = 0;
  bool autoStartNext = false;
  bool soundNotification = true;
  bool notificationsGranted = false;
  bool _notificationsInitialized = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    if (_notificationsInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    try {
      await _notificationsPlugin.initialize(settings: initSettings);
      _notificationsInitialized = true;
    } catch (_) {}
  }

  Future<bool> refreshNotificationPermission({bool notify = true}) async {
    await initNotifications();

    var granted = true;
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      granted = await androidPlugin.areNotificationsEnabled() ?? false;
    } else {
      final iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final permissions = await iosPlugin.checkPermissions();
        granted = permissions?.isEnabled ?? false;
      }
    }

    final changed = notificationsGranted != granted;
    notificationsGranted = granted;
    if (notify && changed) notifyListeners();
    return notificationsGranted;
  }

  Future<bool> requestNotificationPermission() async {
    await initNotifications();

    if (await refreshNotificationPermission()) {
      return true;
    }

    final iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      notificationsGranted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      notifyListeners();
      return notificationsGranted;
    }

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      notificationsGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      notificationsGranted = await refreshNotificationPermission(notify: false);
      notifyListeners();
      return notificationsGranted;
    }

    notificationsGranted = true;
    notifyListeners();
    return true;
  }

  Future<void> showNotification(String title, String body) async {
    final wasGranted = notificationsGranted;
    if (!await refreshNotificationPermission(notify: false)) {
      if (wasGranted) notifyListeners();
      return;
    }
    await initNotifications();

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifikasi untuk timer Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundNotification,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundNotification,
    );
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  void startTimer() {
    _timer?.cancel();
    isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeft > 0) {
        timeLeft--;
        notifyListeners();
        return;
      }

      _completeCurrentSession();
    });
  }

  void stopTimer({bool notify = true}) {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    if (notify) notifyListeners();
  }

  void resetTimer() {
    stopTimer(notify: false);
    timeLeft = _durationForMode(currentMode) * 60;
    notifyListeners();
  }

  void skipTimer() {
    stopTimer(notify: false);
    _moveToNextMode(countCompletedPomodoro: false);
    notifyListeners();
  }

  void setMode(String mode, int timeInSeconds) {
    stopTimer(notify: false);
    currentMode = mode;
    timeLeft = timeInSeconds;
    notifyListeners();
  }

  void changeDuration(String type, int delta) {
    if (type == 'Pomodoro') {
      pomodoroDuration = (pomodoroDuration + delta).clamp(1, 60);
      if (currentMode == 'Pomodoro') {
        stopTimer(notify: false);
        timeLeft = pomodoroDuration * 60;
      }
    } else if (type == 'Istirahat Pendek') {
      shortBreakDuration = (shortBreakDuration + delta).clamp(1, 30);
      if (currentMode == 'Short Break') {
        stopTimer(notify: false);
        timeLeft = shortBreakDuration * 60;
      }
    } else if (type == 'Istirahat Panjang') {
      longBreakDuration = (longBreakDuration + delta).clamp(1, 60);
      if (currentMode == 'Long Break') {
        stopTimer(notify: false);
        timeLeft = longBreakDuration * 60;
      }
    }

    notifyListeners();
  }

  void setLongBreakAfter(int value) {
    longBreakAfter = value.clamp(2, 8);
    notifyListeners();
  }

  void toggleAutoStartNext() {
    autoStartNext = !autoStartNext;
    notifyListeners();
  }

  void toggleSoundNotification() {
    soundNotification = !soundNotification;
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _completeCurrentSession() {
    final completedMode = currentMode;
    stopTimer(notify: false);
    unawaited(
      showNotification('Waktu Habis!', 'Sesi $completedMode telah selesai.'),
    );
    _moveToNextMode(countCompletedPomodoro: completedMode == 'Pomodoro');

    if (autoStartNext) {
      startTimer();
    } else {
      notifyListeners();
    }
  }

  void _moveToNextMode({required bool countCompletedPomodoro}) {
    if (currentMode == 'Pomodoro') {
      if (countCompletedPomodoro) {
        completedPomodoroSessions++;
      }

      final useLongBreak = countCompletedPomodoro &&
          completedPomodoroSessions > 0 &&
          completedPomodoroSessions % longBreakAfter == 0;
      currentMode = useLongBreak ? 'Long Break' : 'Short Break';
      timeLeft = _durationForMode(currentMode) * 60;
      return;
    }

    currentMode = 'Pomodoro';
    timeLeft = pomodoroDuration * 60;
  }

  int _durationForMode(String mode) {
    if (mode == 'Short Break') return shortBreakDuration;
    if (mode == 'Long Break') return longBreakDuration;
    return pomodoroDuration;
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final _controller = _PomodoroController.instance;

  int get _timeLeft => _controller.timeLeft;
  bool get _isRunning => _controller.isRunning;
  String get _currentMode => _controller.currentMode;

  int get _pomodoroDuration => _controller.pomodoroDuration;
  int get _shortBreakDuration => _controller.shortBreakDuration;
  int get _longBreakDuration => _controller.longBreakDuration;

  int get _longBreakAfter => _controller.longBreakAfter;
  bool get _autoStartNext => _controller.autoStartNext;
  bool get _soundNotification => _controller.soundNotification;
  bool get _browserNotifGranted => _controller.notificationsGranted;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTimerChanged);
    unawaited(_controller.refreshNotificationPermission());
  }

  void _onTimerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _activateNotifications() async {
    final granted = await _controller.requestNotificationPermission();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notifikasi perangkat aktif'
              : 'Izin notifikasi belum diberikan',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showNotification(String title, String body) =>
      _controller.showNotification(title, body);

  void _startTimer() {
    _controller.startTimer();
  }

  void _stopTimer() {
    _controller.stopTimer();
  }

  void _resetTimer() {
    _controller.resetTimer();
  }

  void _skipTimer() {
    _controller.skipTimer();
  }

  void _setMode(String mode, int timeInSeconds) {
    _controller.setMode(mode, timeInSeconds);
  }

  void _changeDuration(String type, int delta) {
    _controller.changeDuration(type, delta);
  }

  String _formatTime(int seconds) {
    return _controller.formatTime(seconds);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTimerChanged);
    super.dispose();
  }

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
                Text(
                  'Timer Fokus',
                  style: GoogleFonts.montserrat(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTimerCard(t),
                const SizedBox(height: 32),

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
           
            color: const Color(0xFF60A5FA)
                .withValues(alpha: t.isDark ? 0.0 : 0.10),
            blurRadius: 50,
            spreadRadius: 0,
          ),
        ],
        gradient: t.isDark
            ? LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.center,
                colors: [
                 
                  const Color(0xff00428e).withValues(alpha: 0.03),
                  t.surface,
                ],
              )
            : const LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.center,
                colors: [
                  Color(0xFFDBEAFE),
                  Colors.white,
                ],
              ),
      ),
      child: Column(
        children: [
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleOutlineBtn(
                icon: Icons.refresh_rounded,
                size: 56,
                iconSize: 26,
                onTap: _resetTimer,
                t: t,
              ),
              const SizedBox(width: 20),

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
                        color: t.accent.withValues(alpha: 0.3),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _longBreakAfter.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              onChanged: (val) => _controller.setLongBreakAfter(val.round()),
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
        GestureDetector(
          onTap: _controller.toggleAutoStartNext,
          child: _buildColoredToggleCard(
            icon: Icons.bolt_outlined,
            title: 'Mulai sesi berikutnya otomatis',
            isOn: _autoStartNext,
            colorScheme: const Color(0xFF1D4ED8),
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            t: t,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: _controller.toggleSoundNotification,
          child: _buildColoredToggleCard(
            icon: Icons.volume_up_outlined,
            title: 'Suara notifikasi',
            isOn: _soundNotification,
            colorScheme: const Color(0xFF047857),
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            t: t,
          ),
        ),
        const SizedBox(height: 12),

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
                  GestureDetector(
                    onTap:
                        _browserNotifGranted ? null : _activateNotifications,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.isDark ? t.background : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.border),
                      ),
                      child: Text(
                        _browserNotifGranted ? 'Aktif' : 'Aktifkan',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _browserNotifGranted
                              ? const Color(0xFF16A34A)
                              : t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final granted =
                          await _controller.refreshNotificationPermission();
                      if (!mounted) return;

                      if (granted) {
                        await _showNotification('Tes Notifikasi',
                            'Ini adalah tes notifikasi dari Pomodoro Godone.');
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
                        color: const Color(0xFF2563EB),
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
                      color:
                          Colors.black.withValues(alpha: t.isDark ? 0.2 : 0.05),
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
                        color: t.textSecondary.withValues(alpha: 0.6),
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
