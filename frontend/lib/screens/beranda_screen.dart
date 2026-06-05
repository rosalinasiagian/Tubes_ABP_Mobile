import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// Import komponen navigasi dan tema
import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import 'task_screen.dart';
import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../widgets/edit_task_sheet.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  String _userName = 'Pengguna';
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _highPriority = 0;
  int _mediumPriority = 0;
  int _lowPriority = 0;
  bool _isLoading = true;
  List<dynamic> _categories = [];

  List<dynamic> _tasks = [];

  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final userFuture = ApiService.getUser();
      final statsFuture = ApiService.getTaskStats();
      final tasksFuture = ApiService.getTasks();

      final results = await Future.wait([userFuture, statsFuture, tasksFuture]);
      final user = results[0] as Map<String, dynamic>;
      final stats = results[1] as Map<String, dynamic>;
      final tasks = results[2] as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _userName = user['first_name'] ?? user['name'] ?? 'Pengguna';
        _totalTasks = stats['total'] ?? 0;
        _completedTasks = stats['completed'] ?? 0;
        _highPriority = stats['high_pending'] ?? 0;
        _mediumPriority = stats['medium_pending'] ?? 0;
        _lowPriority = stats['low_pending'] ?? 0;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final bool isCurrentlyDone = task['status'] == 'done';
    final t = TemaData();
    
    if (!isCurrentlyDone) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: t.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tandai Selesai?',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: t.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Task ini akan ditandai sebagai selesai.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 14, color: t.textSecondary),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Batal', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: t.isDark ? Colors.white : const Color(0xFF334155))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Ya, Selesaikan', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      task['status'] = isCurrentlyDone ? 'pending' : 'done';
      if (isCurrentlyDone) {
         _completedTasks--;
      } else {
         _completedTasks++;
      }
    });

    try {
      await ApiService.updateTask(task['task_id'] ?? task['id'], {
        'status': isCurrentlyDone ? 'pending' : 'done',
      });
      _loadData();
      AppNotifier.instance.notifyAll();

      if (!isCurrentlyDone && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: t.surface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.green, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Task Selesai',
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Task berhasil diselesaikan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 14, color: t.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        task['status'] = isCurrentlyDone ? 'done' : 'pending';
        if (isCurrentlyDone) {
           _completedTasks++;
        } else {
           _completedTasks--;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final t = TemaData();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Hapus Task?', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: t.textPrimary)),
        content: Text('Apakah Anda yakin ingin menghapus task ini? Tindakan ini tidak dapat dibatalkan.', style: GoogleFonts.montserrat(color: t.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.montserrat(color: t.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Hapus', style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      int id = int.parse((task['task_id'] ?? task['id']).toString());
      await ApiService.deleteTask(id);
      _loadData();
      AppNotifier.instance.notifyAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task berhasil dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus task: $e')),
        );
      }
    }
  }

  int? _getDaysUntilDeadline(String? deadline) {
    if (deadline == null || deadline.isEmpty) return null;
    final today = DateTime(_now.year, _now.month, _now.day);
    try {
      // Split by 'T' to remove time, then split by ' ' if needed, then '-'
      final cleanDate = deadline.split('T')[0].split(' ')[0];
      final parts = cleanDate.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final dDate = DateTime(year, month, day);
      return dDate.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String _formatDeadlineText(String? deadline) {
    if (deadline == null || deadline.isEmpty) return "Tanpa deadline";
    final days = _getDaysUntilDeadline(deadline);
    if (days == null) return "Tanpa deadline";
    if (days < 0) return "${-days} hari terlambat";
    if (days == 0) return "Hari ini";
    if (days == 1) return "Besok";
    if (days <= 7) return "$days hari lagi";
    
    try {
      final cleanDate = deadline.split('T')[0].split(' ')[0];
      final parts = cleanDate.split('-');
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (_) {
      return deadline;
    }
  }

  Color _colorForPriority(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high' || p == 'tinggi') return Colors.red;
    if (p == 'medium' || p == 'sedang') return Colors.orange;
    if (p == 'low' || p == 'rendah') return Colors.teal;
    return Colors.grey;
  }

  String get _formattedDate {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[_now.weekday % 7]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  String get _formattedTime {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  String get _greeting {
    final hour = _now.hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  double get _completionRate =>
      _totalTasks == 0 ? 0 : _completedTasks / _totalTasks;

  Widget _buildCard({required TemaData t, required Widget child, Gradient? gradient}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? t.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.3 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTaskItem(TemaData t, Map<String, dynamic> task, {bool showDelete = false, bool isUpcoming = false}) {
    final bool isDone = task['status'] == 'done';
    final priorityColor = _colorForPriority(task['priority']?.toString() ?? 'medium');
    
    return StatefulBuilder(
      builder: (context, setCardState) {
        bool showArrow = task['_showArrow'] ?? false;
        
        return GestureDetector(
          onTap: () {
            if (isUpcoming) {
              setCardState(() {
                task['_showArrow'] = !showArrow;
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: showDelete ? const Color(0xFFFFF5F5) : (t.isDark ? t.surfaceVariant : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: showDelete ? const Color(0xFFFFCDD2) : (showArrow ? t.accent : t.border)),
            ),
            child: Row(
              children: [
          if (!showDelete) ...[
            StatefulBuilder(
              builder: (context, setState) {
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (ctx, setHoverState) {
                    return MouseRegion(
                      onEnter: (_) => setHoverState(() => isHovered = true),
                      onExit: (_) => setHoverState(() => isHovered = false),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _toggleTaskStatus(task),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: (isDone || isHovered) ? Colors.green.withOpacity(0.15) : Colors.transparent,
                            border: Border.all(
                              color: (isDone || isHovered) ? Colors.green : t.textSecondary.withOpacity(0.5),
                              width: 1.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: (isDone || isHovered) ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontWeight: showDelete ? FontWeight.w800 : FontWeight.w600,
                    fontSize: showDelete ? 15 : 13,
                    color: showDelete ? const Color(0xFF900020) : (isDone ? t.textSecondary : t.textPrimary),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task['category_name'] != null || task['deadline'] != null)
                  const SizedBox(height: 4),
                Row(
                  children: [
                    if (task['category_name'] != null && !showDelete) ...[
                      Text(task['category_name'], style: GoogleFonts.montserrat(fontSize: 10, color: t.textSecondary)),
                      const SizedBox(width: 8),
                    ],
                    if (task['deadline'] != null)
                      Text(
                        showDelete ? _formatDeadlineText(task['deadline']).toUpperCase() : _formatDeadlineText(task['deadline']),
                        style: GoogleFonts.montserrat(
                          fontSize: showDelete ? 11 : 10,
                          fontWeight: showDelete ? FontWeight.bold : FontWeight.normal,
                          color: showDelete ? const Color(0xFFE53935) : t.textSecondary,
                          letterSpacing: showDelete ? 0.5 : 0,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showDelete) ...[
            GestureDetector(
              onTap: () => _deleteTask(task),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: const Color(0xFFD0D5DD), width: 1.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleTaskStatus(task),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: const Color(0xFFD0D5DD), width: 1.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, size: 18, color: Color(0xFF64748B)),
              ),
            ),
          ] else if (isUpcoming && (task['_showArrow'] == true))
            GestureDetector(
              onTap: () {
                EditTaskSheet.show(
                  context: context,
                  task: task,
                  categories: _categories,
                  onTaskUpdated: _loadData,
                  onCategoriesUpdated: _fetchCategories,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.border, width: 1.2),
                ),
                child: Icon(Icons.arrow_forward, size: 18, color: t.textSecondary),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (task['priority']?.toString() ?? 'Medium').toUpperCase(),
                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
              ),
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
        
        final todayTasks = _tasks.where((task) {
          return _getDaysUntilDeadline(task['deadline']) == 0 && task['status'] != 'done';
        }).toList();
        
        final upcomingTasks = _tasks.where((task) {
          final d = _getDaysUntilDeadline(task['deadline']);
          return d != null && d > 0 && d <= 7 && task['status'] != 'done';
        }).toList();
        
        final overdueTasks = _tasks.where((task) {
          final d = _getDaysUntilDeadline(task['deadline']);
          return d != null && d < 0 && task['status'] != 'done';
        }).toList();

        return Scaffold(
          backgroundColor: t.background,
          extendBody: true,
          appBar: const TopNavigation(),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: t.accent))
              : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // WIDGET HARI & WAKTU
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: t.accent),
                            const SizedBox(width: 6),
                            Text(
                              _formattedDate,
                              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: t.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: t.accentLight, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            _formattedTime,
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: t.accent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // CARD PUSAT PRODUKTIVITAS
                  // ==========================================
                  _buildCard(
                    t: t,
                    gradient: t.isDark
                        ? LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [t.surfaceVariant, t.surface])
                        : const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.white, Color(0xffeff9ff)]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PUSAT PRODUKTIVITAS', style: GoogleFonts.montserrat(color: t.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                '$_greeting,\n$_userName',
                                style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
                              ),
                              const SizedBox(height: 5),
                              Text('Kelola harimu dengan pusat kendali pribadimu.', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(t.isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _completionRate,
                                      strokeWidth: 5,
                                      backgroundColor: t.border,
                                      color: t.accent,
                                    ),
                                    Center(
                                      child: Text(
                                        '${(_completionRate * 100).toInt()}%',
                                        style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('TARGET HARIAN', style: GoogleFonts.montserrat(color: t.accent, fontSize: 8, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$_completedTasks task selesai', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: t.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // CARD AREA FOKUS
                  // ==========================================
                  _buildCard(
                    t: t,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.adjust, color: t.isDark ? Colors.blue.shade300 : Colors.blue.shade400, size: 20),
                                const SizedBox(width: 8),
                                Text('Area Fokus', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: t.textPrimary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: t.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${todayTasks.length} Aktif',
                                style: GoogleFonts.montserrat(fontSize: 10, color: t.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (todayTasks.isEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: t.surface,
                              border: Border.all(color: t.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
                                const SizedBox(height: 10),
                                Text('Semua task hari ini beres', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Lanjut santai atau ke rencana berikutnya.', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 11)),
                              ],
                            ),
                          )
                        ] else ...[
                          const SizedBox(height: 10),
                          ...todayTasks.map((task) => _buildTaskItem(t, task)),
                        ],
                      ],
                    ),
                  ),

                  // ==========================================
                  // CARD RADAR PRIORITAS
                  // ==========================================
                  _buildCard(
                    t: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.show_chart, color: Colors.orange.shade400, size: 20),
                            const SizedBox(width: 8),
                            Text('Radar Prioritas', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: t.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildPriorityRow(t, Colors.red.shade400, 'TINGGI', '$_highPriority'),
                        Divider(height: 20, color: t.divider),
                        _buildPriorityRow(t, Colors.orange.shade400, 'SEDANG', '$_mediumPriority'),
                        Divider(height: 20, color: t.divider),
                        _buildPriorityRow(t, Colors.teal.shade400, 'RENDAH', '$_lowPriority'),
                      ],
                    ),
                  ),

                  // ==========================================
                  // CARD AKAN DATANG & TERLAMBAT
                  // ==========================================
                  _buildCard(
                    t: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text('Akan Datang', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        if (upcomingTasks.isEmpty) ...[
                          const SizedBox(height: 15),
                          Text(
                            'Tidak ada deadline dalam 7 hari kedepan.',
                            style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ] else ...[
                          const SizedBox(height: 5),
                          ...upcomingTasks.take(5).map((task) => _buildTaskItem(t, task, isUpcoming: true)),
                        ],
                      ],
                    ),
                  ),

                  _buildCard(
                    t: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text('Terlambat', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        if (overdueTasks.isEmpty) ...[
                          const SizedBox(height: 15),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade400, size: 24),
                                const SizedBox(height: 5),
                                Text('Semua task aman', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                Text('Tidak ada yang lewat deadline.', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 11)),
                              ],
                            ),
                          )
                        ] else ...[
                          const SizedBox(height: 5),
                          ...overdueTasks.take(4).map((task) => _buildTaskItem(t, task, showDelete: true)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BotNavigation(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildPriorityRow(TemaData t, Color dotColor, String label, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
          ],
        ),
        Text(count, style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}