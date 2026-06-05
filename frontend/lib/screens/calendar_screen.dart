import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import komponen navigasi dan tema
import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart'; // Wajib diimport untuk mengambil TemaData

import '../services/api_service.dart'; // Import ApiService

// ==========================================
// SHARED UTILS
// ==========================================
class TaskUtils {
  static Color colorForPriority(String priority) {
    switch (priority.toUpperCase()) {
      case 'TINGGI':
      case 'HIGH':
        return const Color(0xFFEF4444); // Merah
      case 'SEDANG':
      case 'MEDIUM':
        return const Color(0xFFF59E0B); // Kuning/Orange
      case 'RENDAH':
      case 'LOW':
        return const Color(0xFF10B981); // Hijau
      default:
        return Colors.grey;
    }
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ==========================================
// CALENDAR SCREEN
// ==========================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  Map<String, List<Map<String, dynamic>>> _tasksByDate = {};
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoading = false;
  bool _showAllEvents = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await ApiService.getTasks();
      final Map<String, List<Map<String, dynamic>>> map = {};
      final List<Map<String, dynamic>> allList = [];
      for (var t in tasks) {
        allList.add(Map<String, dynamic>.from(t));
        String? date = t['deadline']?.toString();
        if (date != null && date.length >= 10) {
          date = date.substring(0, 10);
          if (map[date] == null) map[date] = [];
          map[date]!.add(Map<String, dynamic>.from(t));
        }
      }
      if (!mounted) return;
      setState(() {
        _tasksByDate = map;
        _allTasks = allList;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _tasksForDay(DateTime day) =>
      _tasksByDate[TaskUtils.dateKey(day)] ?? [];

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
  int _firstWeekdayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData(); // Ambil instance tema aktif

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
                  'Kalender',
                  style: GoogleFonts.montserrat(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // CARD KALENDER (DENGAN GRADASI PILIHAN ANDA)
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(t.isDark ? 0.30 : 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    // Penerapan Gradasi Sesuai Request Anda: Bottom Right ke Center
                    gradient: t.isDark
                        ? LinearGradient(
                            begin: Alignment
                                .bottomRight, // Mulai dari pojok kanan bawah
                            end: Alignment.center, // Menuju ke tengah kartu
                            colors: [t.surfaceVariant, t.surface],
                          )
                        : const LinearGradient(
                            begin: Alignment
                                .bottomRight, // Mulai dari pojok kanan bawah
                            end: Alignment.center, // Menuju ke tengah kartu
                            colors: [
                              Color(0xffeff9ff),
                              Colors.white
                            ], // Biru faint khas login screen Anda
                          ),
                  ),
                  child: Column(
                    children: [
                      // Header Bulan & Navigasi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: t.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              _navButton(Icons.chevron_left, _prevMonth, t),
                              const SizedBox(width: 8),
                              _navButton(Icons.chevron_right, _nextMonth, t),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Label Hari (SUN, MON, ...)
                      Row(
                        children: [
                          'SUN',
                          'MON',
                          'TUE',
                          'WED',
                          'THU',
                          'FRI',
                          'SAT'
                        ]
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: t.textSecondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      // Grid Tanggal
                      _buildCalendarGrid(t),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // PANEL DETAIL HARI
                // ==========================================
                if (_selectedDay != null) _buildDayPanel(_selectedDay!, t),
              ],
            ),
          ),
          bottomNavigationBar: const BotNavigation(currentIndex: 3),
        );
      },
    );
  }

  // ==========================================
  // GRID KALENDER BUILDER
  // ==========================================
  Widget _buildCalendarGrid(TemaData t) {
    final daysInMonth = _daysInMonth(_focusedMonth);
    final firstWeekday = _firstWeekdayOfMonth(_focusedMonth);
    final rows = ((firstWeekday + daysInMonth) / 7).ceil();
    final now = DateTime.now();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final dayNumber = cellIndex - firstWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 56));
            }

            final thisDate =
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);

            final isToday = thisDate.year == now.year &&
                thisDate.month == now.month &&
                thisDate.day == now.day;

            final isSelected = _selectedDay != null &&
                thisDate.year == _selectedDay!.year &&
                thisDate.month == _selectedDay!.month &&
                thisDate.day == _selectedDay!.day;

            final tasks = _tasksForDay(thisDate);

            BoxDecoration? circleDeco;
            Color textColor = t.textPrimary;
            FontWeight textWeight = FontWeight.w500;

            if (isToday) {
              circleDeco =
                  BoxDecoration(color: t.accent, shape: BoxShape.circle);
              textColor = Colors.white;
              textWeight = FontWeight.bold;
            } else if (isSelected) {
              circleDeco = BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: t.accent, width: 1.5),
                shape: BoxShape.circle,
              );
              textColor = t.accent;
              textWeight = FontWeight.bold;
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedDay = thisDate),
                child: SizedBox(
                  height: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: circleDeco,
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: textWeight,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      if (tasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: tasks
                                .take(3)
                                .map((task) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: TaskUtils.colorForPriority(
                                            task['priority']),
                                        shape: BoxShape.circle,
                                      ),
                                    ))
                                .toList(),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ==========================================
  // PANEL DETAIL HARI / EVENTS
  // ==========================================
  Widget _buildDayPanel(DateTime day, TemaData t) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: t.accent));
    }
    final tasks = _showAllEvents ? _allTasks : _tasksForDay(day);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SEGMENTED CONTROL
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: t.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showAllEvents = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showAllEvents ? const Color(0xFF1E40AF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('All Events', style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: _showAllEvents ? Colors.white : t.textSecondary,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showAllEvents = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showAllEvents ? const Color(0xFF1E40AF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Selected', style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: !_showAllEvents ? Colors.white : t.textSecondary,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: t.border),
          
          // 2. CONTENT (TANGGAL & DAFTAR TASK)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showAllEvents ? 'Semua Task' : '${_monthName(day.month)} ${day.day}, ${day.year}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                if (tasks.isEmpty)
                  _emptyTaskCard(t)
                else
                  ...tasks.map((taskData) => _taskCard(taskData, t)),
              ],
            ),
          ),

          // 3. PRIORITY LEGEND
          Divider(height: 1, color: t.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIORITY LEGEND',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: t.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _legendItem('High', TaskUtils.colorForPriority('high'), t),
                    const SizedBox(width: 16),
                    _legendItem('Medium', TaskUtils.colorForPriority('medium'), t),
                    const SizedBox(width: 16),
                    _legendItem('Low', TaskUtils.colorForPriority('low'), t),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color, TemaData t) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
      ],
    );
  }

  // ==========================================
  // TASK CARD
  // ==========================================
  Widget _taskCard(Map<String, dynamic> task, TemaData t) {
    final priority = task['priority'] ?? 'Sedang';
    final color = TaskUtils.colorForPriority(priority);
    final title = task['title'] ?? 'Tanpa Judul';
    final category = task['category'] ?? 'Kerja';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: t.textSecondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: TextStyle(color: t.textSecondary, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTaskCard(TemaData t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              color: t.textSecondary.withOpacity(0.4), size: 40),
          const SizedBox(height: 16),
          Text(_showAllEvents ? 'Tidak ada task sama sekali' : 'No tasks on this date',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: t.textSecondary)),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, TemaData t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: t.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border)),
        child: Icon(icon, size: 18, color: t.textPrimary),
      ),
    );
  }

  String _monthName(int month) => [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ][month - 1];
  String _dayName(int weekday) => [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ][weekday - 1];
}
