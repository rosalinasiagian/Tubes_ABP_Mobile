import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import komponen navigasi, tema, dan sumber data
import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
// For TaskUtils
import '../services/api_service.dart';

class PriorityScreen extends StatefulWidget {
  const PriorityScreen({super.key});

  @override
  State<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends State<PriorityScreen> {
  List<Map<String, dynamic>> _allTasks = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String? _expandedTaskId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchTasks();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {}
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await ApiService.getTasks();
      if (!mounted) return;
      setState(() {
        _allTasks = tasks.map((t) => Map<String, dynamic>.from(t)).toList();
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper untuk memformat tanggal (misal: "2026-05-20" -> "May 20")
  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kelompokkan task yang belum selesai berdasarkan prioritas
    List<Map<String, dynamic>> highTasks = _allTasks
        .where((t) =>
            t['priority']?.toLowerCase() == 'high' && t['status'] != 'done')
        .toList();
    List<Map<String, dynamic>> medTasks = _allTasks
        .where((t) =>
            t['priority']?.toLowerCase() == 'medium' && t['status'] != 'done')
        .toList();
    List<Map<String, dynamic>> lowTasks = _allTasks
        .where((t) =>
            t['priority']?.toLowerCase() == 'low' && t['status'] != 'done')
        .toList();

    int totalActive = highTasks.length + medTasks.length + lowTasks.length;

    // Membungkus dengan ListenableBuilder agar otomatis refresh saat tema diubah
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData(); // Ambil instance tema saat ini

        return Scaffold(
          backgroundColor: t.background, // Background dinamis

          // Memanggil Top Navigation
          appBar: const TopNavigation(),

          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
                top: 20, left: 20, right: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // HEADER OVERVIEW CARD
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: t.surface, // Background card dinamis
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.border), // Border dinamis
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(t.isDark ? 0.3 : 0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVERVIEW',
                        style: GoogleFonts.montserrat(
                          color: t.accent, // Warna aksen dinamis
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Task Priorities',
                        style: GoogleFonts.montserrat(
                          color: t.textPrimary, // Warna teks dinamis
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$totalActive task aktif di semua prioritas', // <-- Data Dinamis
                        style: GoogleFonts.montserrat(
                          color: t.textSecondary, // Warna teks sekunder dinamis
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // KARTU PRIORITAS
                // ==========================================

                // 1. Prioritas Tinggi (Merah)
                _buildPriorityCard(
                  t: t,
                  title: 'Prioritas Tinggi',
                  tasks: highTasks,
                  emptyText: 'Tidak ada task prioritas high',
                  dotColor: const Color(0xFFEF4444),
                ),

                // 2. Prioritas Sedang (Kuning/Amber)
                _buildPriorityCard(
                  t: t,
                  title: 'Prioritas Sedang',
                  tasks: medTasks,
                  emptyText: 'Tidak ada task prioritas medium',
                  dotColor: const Color(0xFFF59E0B),
                ),

                // 3. Prioritas Rendah (Hijau)
                _buildPriorityCard(
                  t: t,
                  title: 'Prioritas Rendah',
                  tasks: lowTasks,
                  emptyText: 'Tidak ada task prioritas low',
                  dotColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // Memanggil Bot Navigation, currentIndex = 2 (Prioritas)
          bottomNavigationBar: const BotNavigation(currentIndex: 2),
        );
      },
    );
  }

  // ==========================================
  // WIDGET BUILDER UNTUK KARTU PRIORITAS
  // ==========================================
  Widget _buildPriorityCard({
    required TemaData t,
    required String title,
    required List<Map<String, dynamic>> tasks,
    required String emptyText,
    required Color dotColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: t.surface, // Base color container luar
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        // Overlay Gradasi
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.55],
            colors: [
              dotColor.withOpacity(0.12),
              dotColor.withOpacity(0.0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Memastikan lebar penuh
          children: [
            // --- 1. HEADER KARTU ---
            Padding(
              // Jarak bawah diperkecil sedikit karena divider sudah tidak ada
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dotColor.withOpacity(0.15)),
                    ),
                    child: Text(
                      tasks.length.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: dotColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. DIVIDER DIHAPUS ---

            // --- 3. KONTEN (TASK LIST ATAU EMPTY STATE) ---
            Padding(
              // Padding top disesuaikan agar menyatu dengan baik tanpa ada sekat
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 4, bottom: 20),
              child: tasks.isEmpty
                  ? _buildEmptyStateBox(t, dotColor, emptyText)
                  : Column(
                      children: tasks
                          .map((task) => _buildTaskItemBox(t, task, dotColor))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk List Task (Jika ada isinya)
  Widget _buildTaskItemBox(
      TemaData t, Map<String, dynamic> task, Color dotColor) {
    final String taskId = task['task_id']?.toString() ?? task['id']?.toString() ?? '';
    final bool isExpanded = _expandedTaskId == taskId;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedTaskId == taskId) {
            _expandedTaskId = null;
          } else {
            _expandedTaskId = taskId;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.isDark ? t.background : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? dotColor.withOpacity(0.5) : t.border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded ? [
            BoxShadow(
              color: dotColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['title'] ?? 'Tanpa Judul',
              style: GoogleFonts.montserrat(
                color: t.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  task['category_name'] ?? task['category'] ?? 'Pribadi',
                  style: GoogleFonts.montserrat(
                    color: t.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•',
                      style: TextStyle(color: t.textSecondary, fontSize: 11)),
                ),
                Text(
                  _formatDateString(task['deadline']),
                  style: GoogleFonts.montserrat(
                    color: dotColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: t.border),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: t.textSecondary),
                    onPressed: () => _showEditTaskSheet(context, task),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: t.textSecondary),
                    onPressed: () => _deleteTask(task),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, size: 20, color: t.textSecondary),
                    onPressed: () => _toggleTaskStatus(task),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Widget untuk Empty State (Jika tidak ada task)
  Widget _buildEmptyStateBox(TemaData t, Color dotColor, String emptyText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: t.isDark ? t.background : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: t.textSecondary.withOpacity(t.isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          emptyText,
          style: GoogleFonts.montserrat(
            color: t.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ACTION HELPERS (EDIT, HAPUS, SELESAI)
  // ==========================================

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final bool isCurrentlyDone = task['status'] == 'done';
    setState(() {
      task['status'] = isCurrentlyDone ? 'pending' : 'done';
    });
    try {
      await ApiService.updateTask(task['task_id'] ?? task['id'], {
        'status': isCurrentlyDone ? 'pending' : 'done',
      });
      _fetchTasks();
    } catch (e) {
      setState(() {
        task['status'] = isCurrentlyDone ? 'done' : 'pending';
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyelesaikan task')));
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaData().surface,
        title: Text('Hapus Task', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: TemaData().textPrimary)),
        content: Text('Apakah Anda yakin ingin menghapus task ini?', style: GoogleFonts.montserrat(color: TemaData().textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.montserrat(color: TemaData().textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteTask(task['task_id'] ?? task['id']);
      await _fetchTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus task')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategorySelector(BuildContext context, int? currentCategoryId, Function(int?) onSelected, TemaData t) {
    final TextEditingController newCatController = TextEditingController();
    bool isAdding = false;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: t.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pilih Kategori', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = cat['category_id'] == currentCategoryId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(cat['category_name'] ?? '', style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            trailing: isSelected ? Icon(Icons.check, color: t.accent, size: 18) : null,
                            onTap: () {
                              onSelected(cat['category_id']);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                    if (_categories.isNotEmpty) const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCatController,
                            style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'New category...',
                              hintStyle: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(12),
                            minimumSize: Size.zero,
                          ),
                          onPressed: isAdding ? null : () async {
                            final text = newCatController.text.trim();
                            if (text.isEmpty) return;
                            setDialogState(() => isAdding = true);
                            try {
                              final newCat = await ApiService.createCategory({'category_name': text});
                              await _fetchCategories();
                              if (ctx.mounted) {
                                onSelected(newCat['category_id']);
                                Navigator.pop(ctx);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Gagal tambah kategori')));
                                setDialogState(() => isAdding = false);
                              }
                            }
                          },
                          child: isAdding 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon, TemaData t, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(fontSize: 13, color: t.textPrimary),
        textAlignVertical: maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 13, color: t.textSecondary),
          prefixIcon: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: maxLines > 1 ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(icon, color: t.textSecondary, size: 18),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Color _colorForPriority(String priority) {
    switch (priority) {
      case 'Tinggi': return Colors.red;
      case 'Sedang': return Colors.orange;
      case 'Rendah': return Colors.teal;
      default: return Colors.grey;
    }
  }
  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month - 1];
  }

  void _showEditTaskSheet(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    
    final priorityVal = task['priority']?.toString().toLowerCase() ?? 'medium';
    String selectedPriority = priorityVal == 'high' ? 'Tinggi' : (priorityVal == 'low' ? 'Rendah' : 'Sedang');
    
    int? selectedCategoryId = task['category_id'] != null ? int.tryParse(task['category_id'].toString()) : null;
    
    DateTime selectedDate = DateTime.now();
    if (task['deadline'] != null) {
      try {
        selectedDate = DateTime.parse(task['deadline'].toString());
      } catch (_) {}
    }
    
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: TemaData(),
          builder: (ctx, child) {
            final t = TemaData();

            return Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StatefulBuilder(builder: (ctx, setModal) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Edit Task', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: t.textPrimary)),
                      const SizedBox(height: 20),

                      _inputField(titleController, 'Judul task...', Icons.title, t),
                      const SizedBox(height: 12),

                      Text('Kategori', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showCategorySelector(context, selectedCategoryId, (val) {
                            setModal(() => selectedCategoryId = val);
                          }, t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: t.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedCategoryId != null 
                                  ? (_categories.firstWhere((c) => c['category_id'] == selectedCategoryId, orElse: () => {'category_name': 'Pilih Kategori'})['category_name'])
                                  : 'Pilih Kategori...',
                                style: GoogleFonts.montserrat(fontSize: 13, color: t.textPrimary, fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: t.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _inputField(descriptionController, 'Deskripsi task...', Icons.description, t, maxLines: 3),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: t.isDark
                                    ? const ColorScheme.dark(primary: Color(0xFF364C84), onPrimary: Colors.white, surface: Color(0xFF1E293B), onSurface: Colors.white)
                                    : const ColorScheme.light(primary: Color(0xFF364C84)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModal(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: t.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: t.textSecondary),
                              const SizedBox(width: 10),
                              Text('${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}', style: GoogleFonts.montserrat(fontSize: 13, color: t.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text('Prioritas', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Tinggi', 'Sedang', 'Rendah'].map((p) {
                          final isActive = selectedPriority == p;
                          final color = _colorForPriority(p);
                          return GestureDetector(
                            onTap: () => setModal(() => selectedPriority = p),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? color.withOpacity(0.15) : t.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: isActive ? Border.all(color: color, width: 1.5) : Border.all(color: t.border, width: 1.0),
                              ),
                              child: Text(p, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? color : t.textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: t.accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () async {
                                if (titleController.text.trim().isEmpty) return;
                                setModal(() => isSaving = true);
                                try {
                                  await ApiService.updateTask(task['task_id'] ?? task['id'], {
                                    'title': titleController.text.trim(),
                                    'description': descriptionController.text.trim(),
                                    if (selectedCategoryId != null) 'category_id': selectedCategoryId,
                                    'deadline': _dateKey(selectedDate),
                                    'priority': selectedPriority == 'Tinggi' ? 'high' : (selectedPriority == 'Rendah' ? 'low' : 'medium'),
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    _fetchTasks();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal edit task')));
                                    setModal(() => isSaving = false);
                                  }
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Update Task', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: t.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              child: Text('Batal', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: t.textPrimary)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
