import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../widgets/edit_task_sheet.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import 'top_navigation.dart';

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
  List<Map<String, dynamic>> _tasks = [];
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadData();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        ApiService.getUser(),
        ApiService.getTaskStats(),
        ApiService.getTasks(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final stats = results[1] as Map<String, dynamic>;
      final tasks = (results[2] as List<dynamic>)
          .map((task) => Map<String, dynamic>.from(task as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _userName = user['first_name'] ?? user['name'] ?? 'Pengguna';
        _totalTasks = stats['total'] ?? tasks.length;
        _completedTasks = stats['completed'] ??
            tasks.where((t) => t['status'] == 'done').length;
        _highPriority = stats['high_pending'] ?? 0;
        _mediumPriority = stats['medium_pending'] ?? 0;
        _lowPriority = stats['low_pending'] ?? 0;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat dashboard: $e')),
      );
    }
  }

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final wasDone = task['status'] == 'done';
    final newStatus = wasDone ? 'pending' : 'done';

    setState(() => task['status'] = newStatus);

    try {
      await ApiService.updateTask(_taskId(task), {'status': newStatus});
      AppNotifier.instance.notifyAll();
      _loadData(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => task['status'] = wasDone ? 'done' : 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update task: $e')),
      );
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = TemaData();
        return AlertDialog(
          backgroundColor: t.surface,
          title: Text('Hapus task?', style: TextStyle(color: t.textPrimary)),
          content: Text(
            'Task ini akan dihapus permanen.',
            style: TextStyle(color: t.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteTask(_taskId(task));
      await _loadData(showLoader: false);
      AppNotifier.instance.notifyAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus task: $e')),
      );
    }
  }

  void _openEditTask(Map<String, dynamic> task) {
    EditTaskSheet.show(
      context: context,
      task: task,
      categories: _categories,
      onTaskUpdated: () => _loadData(showLoader: false),
      onCategoriesUpdated: _fetchCategories,
    );
  }

  int _taskId(Map<String, dynamic> task) {
    return int.parse((task['task_id'] ?? task['id']).toString());
  }

  int? _daysUntil(String? deadline) {
    if (deadline == null || deadline.isEmpty) return null;
    try {
      final clean = deadline.split('T')[0].split(' ')[0];
      final parts = clean.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final today = DateTime(_now.year, _now.month, _now.day);
      return date.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String _deadlineLabel(String? deadline) {
    final days = _daysUntil(deadline);
    if (days == null) return 'Tanpa deadline';
    if (days < 0) return '${-days} hari terlambat';
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    if (days <= 7) return '$days hari lagi';

    final clean = deadline!.split('T')[0].split(' ')[0];
    final parts = clean.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Color _priorityColor(String priority, TemaData t) {
    final p = priority.toLowerCase();
    if (p == 'high' || p == 'tinggi') return t.danger;
    if (p == 'low' || p == 'rendah') return t.success;
    return t.warning;
  }

  String get _greeting {
    final hour = _now.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  double get _completionRate {
    if (_totalTasks == 0) return 0;
    return (_completedTasks / _totalTasks).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();
        final todayTasks = _tasks
            .where((task) =>
                _daysUntil(task['deadline']?.toString()) == 0 &&
                task['status'] != 'done')
            .toList();
        final upcomingTasks = _tasks.where((task) {
          final days = _daysUntil(task['deadline']?.toString());
          return days != null &&
              days > 0 &&
              days <= 7 &&
              task['status'] != 'done';
        }).toList();
        final overdueTasks = _tasks.where((task) {
          final days = _daysUntil(task['deadline']?.toString());
          return days != null && days < 0 && task['status'] != 'done';
        }).toList();

        return Scaffold(
          backgroundColor: t.background,
          extendBody: true,
          appBar: const TopNavigation(),
          bottomNavigationBar: const BotNavigation(currentIndex: 0),
          body: _isLoading && _tasks.isEmpty
              ? Center(child: CircularProgressIndicator(color: t.accent))
              : RefreshIndicator(
                  onRefresh: () => _loadData(showLoader: false),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 116),
                    children: [
                      _HeroCard(
                        t: t,
                        greeting: _greeting,
                        userName: _userName,
                        completionRate: _completionRate,
                        completedTasks: _completedTasks,
                        totalTasks: _totalTasks,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              t: t,
                              icon: Icons.local_fire_department_outlined,
                              label: 'Prioritas',
                              value: '$_highPriority',
                              color: t.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              t: t,
                              icon: Icons.hourglass_top_rounded,
                              label: 'Sedang',
                              value: '$_mediumPriority',
                              color: t.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              t: t,
                              icon: Icons.eco_outlined,
                              label: 'Ringan',
                              value: '$_lowPriority',
                              color: t.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _TaskSection(
                        t: t,
                        title: 'Fokus hari ini',
                        subtitle: '${todayTasks.length} task aktif',
                        emptyTitle: 'Hari ini bersih',
                        emptySubtitle: 'Tidak ada task jatuh tempo hari ini.',
                        tasks: todayTasks,
                        onToggle: _toggleTaskStatus,
                        onEdit: _openEditTask,
                        onDelete: _deleteTask,
                        deadlineLabel: _deadlineLabel,
                        priorityColor: _priorityColor,
                      ),
                      const SizedBox(height: 18),
                      _TaskSection(
                        t: t,
                        title: 'Akan datang',
                        subtitle: '7 hari ke depan',
                        emptyTitle: 'Tidak ada yang mendesak',
                        emptySubtitle: 'Deadline terdekat akan muncul di sini.',
                        tasks: upcomingTasks.take(5).toList(),
                        onToggle: _toggleTaskStatus,
                        onEdit: _openEditTask,
                        onDelete: _deleteTask,
                        deadlineLabel: _deadlineLabel,
                        priorityColor: _priorityColor,
                      ),
                      const SizedBox(height: 18),
                      _TaskSection(
                        t: t,
                        title: 'Terlambat',
                        subtitle: '${overdueTasks.length} butuh perhatian',
                        emptyTitle: 'Tidak ada yang terlambat',
                        emptySubtitle: 'Bagus, semua deadline masih aman.',
                        tasks: overdueTasks.take(4).toList(),
                        onToggle: _toggleTaskStatus,
                        onEdit: _openEditTask,
                        onDelete: _deleteTask,
                        deadlineLabel: _deadlineLabel,
                        priorityColor: _priorityColor,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final TemaData t;
  final String greeting;
  final String userName;
  final double completionRate;
  final int completedTasks;
  final int totalTasks;

  const _HeroCard({
    required this.t,
    required this.greeting,
    required this.userName,
    required this.completionRate,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: t.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: t.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$completedTasks dari $totalTasks task selesai',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completionRate,
                  strokeWidth: 9,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(completionRate * 100).round()}%',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final TemaData t;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.t,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: t.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: t.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final TemaData t;
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final List<Map<String, dynamic>> tasks;
  final Future<void> Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final String Function(String?) deadlineLabel;
  final Color Function(String, TemaData) priorityColor;

  const _TaskSection({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.deadlineLabel,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: t.accentLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.done_all_rounded, color: t.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emptyTitle,
                        style: GoogleFonts.montserrat(
                          color: t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        emptySubtitle,
                        style: GoogleFonts.montserrat(
                          color: t.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskRow(
                t: t,
                task: task,
                onToggle: onToggle,
                onEdit: onEdit,
                onDelete: onDelete,
                deadlineLabel: deadlineLabel,
                priorityColor: priorityColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TemaData t;
  final Map<String, dynamic> task;
  final Future<void> Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final String Function(String?) deadlineLabel;
  final Color Function(String, TemaData) priorityColor;

  const _TaskRow({
    required this.t,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.deadlineLabel,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task['status'] == 'done';
    final priority = task['priority']?.toString() ?? 'medium';
    final color = priorityColor(priority, t);

    return InkWell(
      onTap: () => onEdit(task),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => onToggle(task),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? t.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? t.success : t.border,
                    width: 1.6,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 17)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title']?.toString() ?? 'Task',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: isDone ? t.textSecondary : t.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deadlineLabel(task['deadline']?.toString()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: t.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (task['category_name'] != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task['category_name'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: t.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                priority.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: t.textSecondary),
              color: t.surface,
              onSelected: (value) {
                if (value == 'edit') onEdit(task);
                if (value == 'delete') onDelete(task);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'edit',
                    child:
                        Text('Edit', style: TextStyle(color: t.textPrimary))),
                PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Hapus', style: TextStyle(color: t.textPrimary))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
