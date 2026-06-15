import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../services/notification_prefs.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'task_screen.dart';
import 'tema_screen.dart';

class TopNavigation extends StatefulWidget implements PreferredSizeWidget {
  final bool isAtProfileScreen;

  const TopNavigation({
    super.key,
    this.isAtProfileScreen = false,
  });

  @override
  State<TopNavigation> createState() => _TopNavigationState();

  @override
  Size get preferredSize => const Size.fromHeight(74);
}

class _TopNavigationState extends State<TopNavigation> {
  int _pendingCount = 0;
  String? _photoUrl;
  String _userName = 'U';

  @override
  void initState() {
    super.initState();
    AppNotifier.instance.addListener(_onGlobalStateChanged);
    NotificationPrefs.instance.addListener(_fetchNotificationCount);
    _fetchUserData();
    _fetchNotificationCount();
  }

  @override
  void dispose() {
    AppNotifier.instance.removeListener(_onGlobalStateChanged);
    NotificationPrefs.instance.removeListener(_fetchNotificationCount);
    super.dispose();
  }

  void _onGlobalStateChanged() {
    _fetchUserData();
    _fetchNotificationCount();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await ApiService.getUser();
      if (!mounted) return;
      setState(() {
        _photoUrl = user['profile_picture'] ?? user['photo_url'];
        _userName = user['first_name'] ?? user['name'] ?? 'U';
      });
    } catch (_) {}
  }

  Future<void> _fetchNotificationCount() async {
    if (!NotificationPrefs.instance.enabled) {
      if (mounted) setState(() => _pendingCount = 0);
      return;
    }
    try {
      final tasks = await ApiService.getTasks();
      if (!mounted) return;
      setState(() {
        _pendingCount = tasks.where(_isUrgentTask).length;
      });
    } catch (_) {}
  }

  bool _isUrgentTask(dynamic task) {
    if (task is! Map || task['status'] == 'done') return false;
    final days = _daysUntil(task['deadline']);
    return days != null && days <= 1;
  }

  int? _daysUntil(dynamic deadline) {
    if (deadline == null) return null;
    try {
      final date = DateTime.parse(deadline.toString());
      final today = DateTime.now();
      return DateTime(date.year, date.month, date.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
    } catch (_) {
      return null;
    }
  }

  void _openNotifications(TemaData t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _NotificationSheet(t: t);
      },
    ).whenComplete(_fetchNotificationCount);
  }

  void _openAccountSheet(TemaData t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: t.border),
              boxShadow: t.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Avatar(photoUrl: _photoUrl, userName: _userName, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: t.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Akun GoDone',
                            style: GoogleFonts.montserrat(
                              color: t.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.person_outline,
                  label: widget.isAtProfileScreen
                      ? 'Sedang di Profil'
                      : 'Buka Profil',
                  color: t.accent,
                  enabled: !widget.isAtProfileScreen,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    _fetchUserData();
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  color: t.danger,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    Navigator.pop(sheetContext);
                    await ApiService.logout();
                    if (!mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();

        return AppBar(
          toolbarHeight: 74,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: t.background,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: t.brandGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: t.softShadow,
                ),
                child: const Icon(Icons.done_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GoDone',
                    style: GoogleFonts.montserrat(
                      color: t.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Focus dashboard',
                    style: GoogleFonts.montserrat(
                      color: t.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            _TopActionButton(
              icon: t.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              tooltip: t.isDark ? 'Mode Terang' : 'Mode Gelap',
              onTap: t.toggleTheme,
              t: t,
            ),
            const SizedBox(width: 8),
            _NotificationButton(
              count: _pendingCount,
              onTap: () => _openNotifications(t),
              t: t,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openAccountSheet(t),
              child:
                  _Avatar(photoUrl: _photoUrl, userName: _userName, size: 38),
            ),
            const SizedBox(width: 18),
          ],
        );
      },
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  final TemaData t;

  const _NotificationSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      maxChildSize: 0.9,
      minChildSize: 0.38,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: t.border),
          ),
          child: FutureBuilder<List<dynamic>>(
            future: NotificationPrefs.instance.enabled
                ? ApiService.getTasks()
                : Future.value(const <dynamic>[]),
            builder: (context, snapshot) {
              final pendingTasks = (snapshot.data ?? [])
                  .where((task) => task is Map && task['status'] != 'done')
                  .map((task) => Map<String, dynamic>.from(task as Map))
                  .toList()
                ..sort(
                  (a, b) => _deadlineSortValue(a['deadline'])
                      .compareTo(_deadlineSortValue(b['deadline'])),
                );

              return Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Kotak Masuk',
                          style: GoogleFonts.montserrat(
                            color: t.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TaskScreen()),
                          );
                        },
                        child: const Text('Lihat Task'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: t.accent),
                      ),
                    )
                  else if (pendingTasks.isEmpty)
                    Expanded(
                      child: NotificationPrefs.instance.enabled
                          ? _EmptyState(
                              icon: Icons.notifications_none_rounded,
                              title: 'Semua aman',
                              subtitle:
                                  'Tidak ada task aktif yang perlu dikejar sekarang.',
                              t: t,
                            )
                          : _EmptyState(
                              icon: Icons.notifications_off_rounded,
                              title: 'Notifikasi dimatikan',
                              subtitle:
                                  'Aktifkan di Profil → Preferensi untuk melihat pengingat task.',
                              t: t,
                            ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: pendingTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = pendingTasks[index];
                          final priority =
                              task['priority']?.toString().toLowerCase() ??
                                  'medium';
                          final color = priority == 'high'
                              ? t.danger
                              : priority == 'low'
                                  ? t.success
                                  : t.warning;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.surfaceVariant.withValues(
                                alpha: t.isDark ? 0.5 : 0.75,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: t.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title']?.toString() ?? 'Task',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          color: t.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _deadlineText(task['deadline']),
                                        style: GoogleFonts.montserrat(
                                          color: t.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: t.textSecondary),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _deadlineText(dynamic deadline) {
    final days = _daysUntil(deadline);
    if (days == null) return 'Tanpa deadline';
    if (days < 0) return '${-days} hari terlambat';
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    if (days <= 7) return '$days hari lagi';

    try {
      final date = DateTime.parse(deadline.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Tanpa deadline';
    }
  }

  int _deadlineSortValue(dynamic deadline) {
    final days = _daysUntil(deadline);
    if (days == null) return 99999;
    return days;
  }

  int? _daysUntil(dynamic deadline) {
    if (deadline == null) return null;
    try {
      final date = DateTime.parse(deadline.toString());
      final today = DateTime.now();
      return DateTime(date.year, date.month, date.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
    } catch (_) {
      return null;
    }
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final TemaData t;

  const _TopActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
            ),
            child: Icon(
              icon,
              key: ValueKey<IconData>(icon),
              color: t.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final TemaData t;

  const _NotificationButton({
    required this.count,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                color: t.textSecondary, size: 21),
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double size;

  const _Avatar({
    required this.photoUrl,
    required this.userName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF1D4ED8),
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaData();
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TemaData t;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: t.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: t.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: t.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
