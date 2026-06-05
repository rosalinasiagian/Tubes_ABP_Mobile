import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';
import 'tema_screen.dart'; // Import TemaData
import 'task_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../services/app_notifier.dart';

class TopNavigation extends StatefulWidget implements PreferredSizeWidget {
  final bool isAtProfileScreen;

  const TopNavigation({
    super.key,
    this.isAtProfileScreen = false,
  });

  @override
  State<TopNavigation> createState() => _TopNavigationState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopNavigationState extends State<TopNavigation> {
  int _pendingCount = 0;
  String? _photoUrl;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    AppNotifier.instance.addListener(_onGlobalStateChanged);
    _fetchNotificationCount();
    _fetchUserData();
  }

  void _onGlobalStateChanged() {
    if (mounted) {
      _fetchNotificationCount();
      _fetchUserData();
    }
  }

  @override
  void dispose() {
    AppNotifier.instance.removeListener(_onGlobalStateChanged);
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await ApiService.getUser();
      if (mounted) {
        setState(() {
          _photoUrl = user['photo_url'];
          _userName = user['first_name'] ?? user['name'] ?? 'U';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final tasks = await ApiService.getTasks();
      if (mounted) {
        setState(() {
          _pendingCount = tasks.where((t) => t['status'] != 'done').length;
        });
      }
    } catch (_) {}
  }

  // Fungsi untuk memunculkan popup Notifikasi (Dialog)
  void _showNotificationPopup(BuildContext context, TemaData t) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: t.surface,
          child: FutureBuilder<List<dynamic>>(
            future: ApiService.getTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: t.accent),
                      const SizedBox(height: 16),
                      Text('Memuat notifikasi...', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }

              final allTasks = snapshot.data ?? [];
              final pendingTasks = allTasks.where((task) => task['status'] != 'done').toList();
              
              if (pendingTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 56, color: t.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Belum ada notifikasi', style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Semua pemberitahuan aktivitas akan muncul di sini.', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.accent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const TaskScreen()),
                            );
                          },
                          child: Text('Lihat Aktivitas', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      )
                    ],
                  ),
                );
              }

              return Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Kotak Masuk', style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(10)),
                          child: Text('${pendingTasks.length}', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: pendingTasks.length,
                        separatorBuilder: (context, index) => Divider(color: t.border),
                        itemBuilder: (context, index) {
                          final task = pendingTasks[index];
                          final title = task['title'] ?? 'No Title';
                          final priorityVal = task['priority']?.toString().toLowerCase() ?? 'medium';
                          final displayPriority = priorityVal == 'high' ? 'HIGH' : (priorityVal == 'low' ? 'LOW' : 'MEDIUM');
                          final pColor = priorityVal == 'high' ? Colors.red : (priorityVal == 'low' ? Colors.teal : Colors.orange);
                          
                          String deadlineText = '';
                          if (task['deadline'] != null) {
                            try {
                              final deadlineDate = DateTime.parse(task['deadline'].toString());
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final tomorrow = today.add(const Duration(days: 1));
                              final taskDate = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
                              
                              if (taskDate == today) {
                                deadlineText = 'Hari ini';
                              } else if (taskDate == tomorrow) {
                                deadlineText = 'Besok';
                              } else {
                                deadlineText = '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
                              }
                            } catch (_) {}
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: BoxDecoration(color: pColor, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Text(displayPriority, style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (deadlineText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: deadlineText == 'Hari ini' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(deadlineText, style: GoogleFonts.montserrat(color: deadlineText == 'Hari ini' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.isDark ? const Color(0xFF263C70) : const Color(0xFF1E40AF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const TaskScreen()),
                          );
                        },
                        child: Text('Lihat Aktivitas', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder memastikan TopNav otomatis rebuild saat tema berubah
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();

        return AppBar(
          backgroundColor: t.surface,
          elevation: 0,
          title: Row(
            children: [
              Text('Go',
                  style: GoogleFonts.montserrat(
                      color: t.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              Text('Done',
                  style: GoogleFonts.montserrat(
                      color: t.accent,
                      fontWeight: FontWeight.w500,
                      fontSize: 20)),
            ],
          ),
          actions: [
            // ====== TOMBOL DARK MODE ======
            IconButton(
              icon: Icon(
                t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: t.textSecondary,
                size: 24,
              ),
              tooltip: t.isDark ? 'Mode Terang' : 'Mode Gelap',
              onPressed: () {
                t.toggleTheme(); // Langsung ubah tema secara global
              },
            ),

            // ====== NOTIFIKASI ======
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none, color: t.textSecondary, size: 24),
                  if (_pendingCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _pendingCount > 9 ? '9+' : '$_pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                _showNotificationPopup(context, t);
                _fetchNotificationCount(); // Refresh count after opening popup
              },
            ),
            const SizedBox(width: 10),

            // ====== AVATAR ======
            GestureDetector(
              onTap: widget.isAtProfileScreen
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                      _fetchUserData(); // Reload photo if changed in profile
                    },
              child: CircleAvatar(
                backgroundColor: const Color(0xFF364C84),
                radius: 16,
                backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null || _photoUrl!.isEmpty
                    ? Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),

            // ====== LOGOUT ======
            IconButton(
              icon: Icon(Icons.logout, color: t.isDark ? const Color(0xFFFC8181) : Colors.red[400], size: 24),
              tooltip: 'Keluar',
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 10),
          ],
        );
      },
    );
  }
}

