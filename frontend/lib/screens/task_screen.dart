import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import komponen navigasi, tema, dan ApiService
import 'top_navigation.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import '../services/api_service.dart';
import '../services/app_notifier.dart';

// ==========================================
// LAYAR TASK UTAMA
// ==========================================
class TaskScreen extends StatefulWidget {
  final Map<String, dynamic>? initialEditTask;
  
  const TaskScreen({super.key, this.initialEditTask});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _selectedPriority = 'Semua Prioritas';
  String _selectedStatus = 'Semua Status';

  List<dynamic> _allTasks = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchTasks().then((_) {
      if (widget.initialEditTask != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEditTaskSheet(context, widget.initialEditTask!);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      // Silent error for categories
    }
  }

  // Helper untuk warna prioritas
  Color _colorForPriority(String priority) {
    switch (priority) {
      case 'Tinggi':
        return Colors.red;
      case 'Sedang':
        return Colors.orange;
      case 'Rendah':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Helper format tanggal (YYYY-MM-DD)
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ─── FUNGSI API ────────────────────────────────────────────────────────

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await ApiService.getTasks();
      setState(() {
        _allTasks = tasks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    });

    try {
      await ApiService.updateTask(task['task_id'] ?? task['id'], {
        'status': isCurrentlyDone ? 'pending' : 'done',
      });
      _fetchTasks();
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update task: $e')),
        );
      }
    }
  }

  // ─── FILTERING ─────────────────────────────────────────────────────────

  List<dynamic> get _filteredTasks {
    return _allTasks.where((t) {
      final String pVal = t['priority']?.toString().toLowerCase() ?? 'medium';
      final String taskPriority = pVal == 'high' ? 'Tinggi' : (pVal == 'low' ? 'Rendah' : 'Sedang');
      
      final matchPriority = _selectedPriority == 'Semua Prioritas' ||
          taskPriority == _selectedPriority;

      final bool isDone = t['status'] == 'done';

      final matchStatus = _selectedStatus == 'Semua Status' ||
          (_selectedStatus == 'Selesai' ? isDone : !isDone);

      final title = t['title']?.toString().toLowerCase() ?? '';
      final desc = t['description']?.toString().toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();
      final matchSearch = title.contains(searchLower) || desc.contains(searchLower);

      return matchPriority && matchStatus && matchSearch;
    }).toList();
  }

  int get _activeCount => _allTasks.where((t) => t['status'] != 'done').length;
  int get _doneCount => _allTasks.where((t) => t['status'] == 'done').length;

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
          body: _isLoading && _allTasks.isEmpty
              ? Center(child: CircularProgressIndicator(color: t.accent))
              : SingleChildScrollView(
            padding: const EdgeInsets.only(
                top: 20, left: 20, right: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER MANAJER TASK
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.surface,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MANAJER TASK',
                          style: GoogleFonts.montserrat(
                              color: t.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Task Saya',
                              style: GoogleFonts.montserrat(
                                  color: t.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.accent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                            ),
                            onPressed: () => _showAddTaskSheet(context),
                            icon: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                            label: Text('Task Baru',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$_activeCount aktif  •  $_doneCount selesai',
                        style: GoogleFonts.montserrat(
                            color: t.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SEARCH BAR & FILTER
                // (Bisa dikembangkan fungsionalitas search-nya nanti)
                Container(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: t.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari task...',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: t.textSecondary),
                      prefixIcon: Icon(Icons.search,
                          color: t.textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                        child: _buildDropdown(
                            _selectedPriority,
                            ['Semua Prioritas', 'Tinggi', 'Sedang', 'Rendah'],
                                (val) => setState(() => _selectedPriority = val!),
                            t)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildDropdown(
                            _selectedStatus,
                            ['Semua Status', 'Aktif', 'Selesai'],
                                (val) => setState(() => _selectedStatus = val!),
                            t)),
                  ],
                ),
                const SizedBox(height: 25),

                // DAFTAR TASK atau EMPTY STATE
                if (_isLoading)
                  Center(child: CircularProgressIndicator(color: t.accent))
                else if (_filteredTasks.isEmpty)
                  _emptyState(t)
                else
                  ..._filteredTasks.map((task) => _taskTile(task, t)),
              ],
            ),
          ),
          bottomNavigationBar: const BotNavigation(currentIndex: 1),
        );
      },
    );
  }

  // ==========================================
  // TASK TILE (Menyamakan dengan versi Web)
  // ==========================================
  Widget _taskTile(dynamic taskData, TemaData t) {
    final Map<String, dynamic> task = taskData as Map<String, dynamic>;
    final String priorityVal = task['priority']?.toString().toLowerCase() ?? 'medium';
    final String displayPriority = priorityVal == 'high' ? 'HIGH' : (priorityVal == 'low' ? 'LOW' : 'MEDIUM');
    final color = _colorForPriority(priorityVal == 'high' ? 'Tinggi' : (priorityVal == 'low' ? 'Rendah' : 'Sedang'));
    final bool isDone = task['status'] == 'done';

    // Format deadline
    String formattedDeadline = 'Tanpa deadline';
    if (task['deadline'] != null) {
      try {
        final date = DateTime.parse(task['deadline'].toString());
        final today = DateTime.now();
        final diff = DateTime(date.year, date.month, date.day).difference(DateTime(today.year, today.month, today.day)).inDays;
        if (diff == 0) {
          formattedDeadline = 'Hari ini';
        } else if (diff == 1) formattedDeadline = 'Besok';
        else if (diff < 0) formattedDeadline = 'Terlambat';
        else formattedDeadline = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {}
    }

    String categoryText = task['category_name'] != null && task['category_name'].toString().isNotEmpty ? task['category_name'] : 'Pribadi';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox (circle)
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
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: (isDone || isHovered) ? Colors.green : t.textSecondary.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: (isDone || isHovered)
                            ? const Icon(Icons.check, size: 16, color: Colors.green)
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Colored Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? 'No Title',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDone ? t.textSecondary : t.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      categoryText,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: t.textSecondary,
                      ),
                    ),
                    if (task['deadline'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                      ),
                      Text(
                        formattedDeadline,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: formattedDeadline == 'Terlambat' ? Colors.red : (formattedDeadline == 'Hari ini' ? Colors.orange : t.textSecondary),
                          fontWeight: formattedDeadline == 'Terlambat' || formattedDeadline == 'Hari ini' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Priority Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: t.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              displayPriority,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          
          // Dropdown Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: t.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            color: t.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditTaskSheet(context, task);
              } else if (value == 'delete') {
                _deleteTask(task);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: t.textPrimary),
                    const SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.montserrat(fontSize: 13, color: t.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Hapus', style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _emptyState(TemaData t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
            BoxDecoration(color: t.accentLight, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, color: t.accent, size: 30),
          ),
          const SizedBox(height: 15),
          Text('Belum ada task',
              style: GoogleFonts.montserrat(
                  color: t.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Buat task pertamamu untuk memulai.',
              style:
              GoogleFonts.montserrat(color: t.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // SELECTOR KATEGORI CUSTOM
  // ==========================================
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
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal tambah kategori: $e')));
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

  // ==========================================
  // BOTTOM SHEET TAMBAH TASK
  // ==========================================
  void _showAddTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'Sedang';
    int? selectedCategoryId = _categories.isNotEmpty ? _categories.first['category_id'] : null;
    DateTime selectedDate = DateTime.now();
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
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StatefulBuilder(builder: (ctx, setModal) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: t.border,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Task Baru',
                          style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: t.textPrimary)),
                      const SizedBox(height: 20),

                      _inputField(
                          titleController, 'Judul task...', Icons.title, t),
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

                      _inputField(
                          descriptionController,
                          'Deskripsi task...',
                          Icons.description,
                          t,
                          maxLines: 3),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: t.isDark
                                    ? const ColorScheme.dark(
                                  primary: Color(0xFF364C84),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                )
                                    : const ColorScheme.light(
                                  primary: Color(0xFF364C84),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModal(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: t.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: t.textSecondary),
                              const SizedBox(width: 10),
                              Text(
                                '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13, color: t.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text('Prioritas',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Tinggi', 'Sedang', 'Rendah'].map((p) {
                          final isActive = selectedPriority == p;
                          final color = _colorForPriority(p);
                          return GestureDetector(
                            onTap: () => setModal(() => selectedPriority = p),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? color.withOpacity(0.15)
                                    : t.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: isActive
                                    ? Border.all(color: color, width: 1.5)
                                    : Border.all(color: t.border, width: 1.0),
                              ),
                              child: Text(p,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? color : t.textSecondary,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Tombol simpan dan batal
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: t.accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSaving ? null : () async {
                                List<String> emptyFields = [];
                                if (titleController.text.trim().isEmpty) emptyFields.add('Judul task');
                                if (descriptionController.text.trim().isEmpty) emptyFields.add('Deskripsi task');
                                
                                if (emptyFields.isNotEmpty) {
                                  showDialog(
                                    context: ctx,
                                    builder: (dialogCtx) => AlertDialog(
                                      backgroundColor: t.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                          const SizedBox(width: 8),
                                          Text('Oops!', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Text('Anda belum mengisi: ${emptyFields.join(" & ")}', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: Text('Oke', style: GoogleFonts.montserrat(color: t.accent, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                setModal(() => isSaving = true);

                                try {
                                  await ApiService.createTask({
                                    'title': titleController.text.trim(),
                                    'description': descriptionController.text.trim(),
                                    if (selectedCategoryId != null) 'category_id': selectedCategoryId,
                                    'deadline': _dateKey(selectedDate),
                                    'priority': selectedPriority == 'Tinggi' ? 'high' : (selectedPriority == 'Rendah' ? 'low' : 'medium'),
                                    'status': 'pending',
                                  });
                                  _fetchTasks();
                                  AppNotifier.instance.notifyAll();

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    _fetchTasks(); // Refresh list setelah nambah
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal tambah task: $e')),
                                    );
                                    setModal(() => isSaving = false);
                                  }
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Simpan Task',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
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
                              child: Text('Batal',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: t.textPrimary)),
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

  // ==========================================
  // HAPUS TASK
  // ==========================================
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
      int id = int.parse((task['task_id'] ?? task['id']).toString());
      await ApiService.deleteTask(id);
      await _fetchTasks();
      AppNotifier.instance.notifyAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus task: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // EDIT TASK SHEET
  // ==========================================
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
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
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
                                List<String> emptyFields = [];
                                if (titleController.text.trim().isEmpty) emptyFields.add('Judul task');
                                if (descriptionController.text.trim().isEmpty) emptyFields.add('Deskripsi task');
                                
                                if (emptyFields.isNotEmpty) {
                                  showDialog(
                                    context: ctx,
                                    builder: (dialogCtx) => AlertDialog(
                                      backgroundColor: t.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                          const SizedBox(width: 8),
                                          Text('Oops!', style: GoogleFonts.montserrat(color: t.textPrimary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Text('Anda belum mengisi: ${emptyFields.join(" & ")}', style: GoogleFonts.montserrat(color: t.textSecondary, fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: Text('Oke', style: GoogleFonts.montserrat(color: t.accent, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
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
                                    AppNotifier.instance.notifyAll();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal edit task: $e')));
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

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _inputField(TextEditingController controller, String hint,
      IconData icon, TemaData t, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
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
          labelText: hint,
          labelStyle: GoogleFonts.montserrat(fontSize: 13, color: t.textSecondary),
          floatingLabelStyle: GoogleFonts.montserrat(fontSize: 12, color: t.accent, fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          alignLabelWithHint: false, // Ensures label is centered when empty
          prefixIcon: Icon(icon, color: t.textSecondary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String currentValue, List<String> items,
      Function(String?) onChanged, TemaData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: currentValue,
          dropdownColor: t.surface,
          icon:
          Icon(Icons.keyboard_arrow_down, color: t.textSecondary, size: 20),
          style: GoogleFonts.montserrat(
              fontSize: 12, color: t.textPrimary, fontWeight: FontWeight.w500),
          onChanged: onChanged,
          items: items
              .map((v) => DropdownMenuItem<String>(
              value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
              .toList(),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return names[month - 1];
  }
}