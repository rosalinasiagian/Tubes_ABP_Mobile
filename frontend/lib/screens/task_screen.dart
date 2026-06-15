import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../widgets/edit_task_sheet.dart';
import 'bot_navigation.dart';
import 'tema_screen.dart';
import 'top_navigation.dart';

class TaskScreen extends StatefulWidget {
  final Map<String, dynamic>? initialEditTask;

  const TaskScreen({super.key, this.initialEditTask});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _priorityFilter = 'Semua';
  String _statusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchCategories(), _fetchTasks()]);
    if (!mounted || widget.initialEditTask == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openEditTask(widget.initialEditTask!);
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _fetchTasks({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    try {
      final tasks = await ApiService.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks
            .map((task) => Map<String, dynamic>.from(task as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat task: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    final query = _searchQuery.toLowerCase();
    return _tasks.where((task) {
      final priority = task['priority']?.toString().toLowerCase() ?? 'medium';
      final status = task['status']?.toString() ?? 'pending';
      final title = task['title']?.toString().toLowerCase() ?? '';
      final description = task['description']?.toString().toLowerCase() ?? '';

      final matchSearch =
          query.isEmpty || title.contains(query) || description.contains(query);
      final matchPriority = _priorityFilter == 'Semua' ||
          (_priorityFilter == 'Tinggi' && priority == 'high') ||
          (_priorityFilter == 'Sedang' && priority == 'medium') ||
          (_priorityFilter == 'Rendah' && priority == 'low');
      final matchStatus = _statusFilter == 'Semua' ||
          (_statusFilter == 'Aktif' && status != 'done') ||
          (_statusFilter == 'Selesai' && status == 'done');

      return matchSearch && matchPriority && matchStatus;
    }).toList();
  }

  int get _activeCount =>
      _tasks.where((task) => task['status'] != 'done').length;

  int get _doneCount => _tasks.where((task) => task['status'] == 'done').length;

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final wasDone = task['status'] == 'done';
    final newStatus = wasDone ? 'pending' : 'done';
    setState(() => task['status'] = newStatus);

    try {
      await ApiService.updateTask(_taskId(task), {'status': newStatus});
      AppNotifier.instance.notifyAll();
      _fetchTasks(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => task['status'] = wasDone ? 'done' : 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update task: $e')),
      );
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final t = TemaData();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteTask(_taskId(task));
      await _fetchTasks(showLoader: false);
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
      onTaskUpdated: () => _fetchTasks(showLoader: false),
      onCategoriesUpdated: _fetchCategories,
    );
  }

  int _taskId(Map<String, dynamic> task) {
    return int.parse((task['task_id'] ?? task['id']).toString());
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _deadlineLabel(dynamic deadline) {
    if (deadline == null) return 'Tanpa deadline';
    try {
      final date = DateTime.parse(deadline.toString());
      final today = DateTime.now();
      final diff = DateTime(date.year, date.month, date.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      if (diff < 0) return 'Terlambat';
      if (diff == 0) return 'Hari ini';
      if (diff == 1) return 'Besok';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Tanpa deadline';
    }
  }

  Color _priorityColor(String priority, TemaData t) {
    final p = priority.toLowerCase();
    if (p == 'high' || p == 'tinggi') return t.danger;
    if (p == 'low' || p == 'rendah') return t.success;
    return t.warning;
  }

  String _priorityLabel(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return 'Tinggi';
    if (p == 'low') return 'Rendah';
    return 'Sedang';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();
        final filtered = _filteredTasks;

        return Scaffold(
          backgroundColor: t.background,
          extendBody: true,
          appBar: const TopNavigation(),
          bottomNavigationBar: const BotNavigation(currentIndex: 1),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddTaskSheet(t),
            backgroundColor: t.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Task',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => _fetchTasks(showLoader: false),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 126),
              children: [
                _TaskHeader(
                  t: t,
                  activeCount: _activeCount,
                  doneCount: _doneCount,
                ),
                const SizedBox(height: 16),
                _SearchField(
                  t: t,
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 14),
                _FilterRow(
                  t: t,
                  title: 'Prioritas',
                  value: _priorityFilter,
                  options: const ['Semua', 'Tinggi', 'Sedang', 'Rendah'],
                  onChanged: (value) => setState(() => _priorityFilter = value),
                ),
                const SizedBox(height: 10),
                _FilterRow(
                  t: t,
                  title: 'Status',
                  value: _statusFilter,
                  options: const ['Semua', 'Aktif', 'Selesai'],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                const SizedBox(height: 22),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: t.accent)),
                  )
                else if (filtered.isEmpty)
                  _EmptyTasks(t: t)
                else
                  ...filtered.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskTile(
                        t: t,
                        task: task,
                        priorityLabel: _priorityLabel,
                        priorityColor: _priorityColor,
                        deadlineLabel: _deadlineLabel,
                        onToggle: _toggleTaskStatus,
                        onEdit: _openEditTask,
                        onDelete: _deleteTask,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddTaskSheet(TemaData t) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedPriority = 'medium';
    int? selectedCategoryId = _categories.isNotEmpty
        ? int.tryParse(_categories.first['category_id'].toString())
        : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: TemaData(),
          builder: (context, child) {
            final theme = TemaData();
            return StatefulBuilder(
              builder: (ctx, setModal) {
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 22,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: theme.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Task baru',
                          style: GoogleFonts.montserrat(
                            color: theme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SheetField(
                          controller: titleController,
                          label: 'Judul task',
                          icon: Icons.title_rounded,
                          t: theme,
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: descriptionController,
                          label: 'Deskripsi',
                          icon: Icons.notes_rounded,
                          t: theme,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _DateButton(
                          t: theme,
                          date: selectedDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime(2032),
                            );
                            if (picked != null) {
                              setModal(() => selectedDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Prioritas',
                          style: GoogleFonts.montserrat(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _PriorityButton(
                              label: 'Tinggi',
                              value: 'high',
                              selected: selectedPriority,
                              t: theme,
                              onTap: () =>
                                  setModal(() => selectedPriority = 'high'),
                            ),
                            const SizedBox(width: 8),
                            _PriorityButton(
                              label: 'Sedang',
                              value: 'medium',
                              selected: selectedPriority,
                              t: theme,
                              onTap: () =>
                                  setModal(() => selectedPriority = 'medium'),
                            ),
                            const SizedBox(width: 8),
                            _PriorityButton(
                              label: 'Rendah',
                              value: 'low',
                              selected: selectedPriority,
                              t: theme,
                              onTap: () =>
                                  setModal(() => selectedPriority = 'low'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CategoryButton(
                          t: theme,
                          categories: _categories,
                          selectedCategoryId: selectedCategoryId,
                          onTap: () {
                            _selectCategory(
                              theme,
                              selectedCategoryId,
                              (value) =>
                                  setModal(() => selectedCategoryId = value),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final navigator = Navigator.of(ctx);
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final title =
                                              titleController.text.trim();
                                          if (title.isEmpty) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Judul task wajib diisi')),
                                            );
                                            return;
                                          }

                                          setModal(() => isSaving = true);
                                          try {
                                            await ApiService.createTask({
                                              'title': title,
                                              'description':
                                                  descriptionController.text
                                                      .trim(),
                                              if (selectedCategoryId != null)
                                                'category_id':
                                                    selectedCategoryId,
                                              'deadline':
                                                  _dateKey(selectedDate),
                                              'priority': selectedPriority,
                                              'status': 'pending',
                                            });
                                            if (!mounted) return;
                                            navigator.pop();
                                            await _fetchTasks(
                                                showLoader: false);
                                            AppNotifier.instance.notifyAll();
                                          } catch (e) {
                                            if (!mounted) return;
                                            setModal(() => isSaving = false);
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Gagal tambah task: $e')),
                                            );
                                          }
                                        },
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Simpan',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _selectCategory(
    TemaData t,
    int? selectedCategoryId,
    ValueChanged<int?> onSelected,
  ) {
    final controller = TextEditingController();
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: t.border),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih kategori',
                      style: GoogleFonts.montserrat(
                        color: t.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            textColor: t.textPrimary,
                            iconColor: t.textSecondary,
                            title: const Text('Tanpa kategori'),
                            trailing: selectedCategoryId == null
                                ? Icon(Icons.check_rounded, color: t.accent)
                                : null,
                            onTap: () {
                              onSelected(null);
                              Navigator.pop(ctx);
                            },
                          ),
                          ..._categories.map((category) {
                            final id = int.tryParse(
                                category['category_id'].toString());
                            return ListTile(
                              textColor: t.textPrimary,
                              title: Text(category['category_name'] ?? ''),
                              trailing: id == selectedCategoryId
                                  ? Icon(Icons.check_rounded, color: t.accent)
                                  : null,
                              onTap: () {
                                onSelected(id);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Kategori baru',
                              prefixIcon: Icon(Icons.add_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: isAdding
                              ? null
                              : () async {
                                  final name = controller.text.trim();
                                  if (name.isEmpty) return;
                                  setSheet(() => isAdding = true);
                                  try {
                                    final newCategory =
                                        await ApiService.createCategory(
                                            {'category_name': name});
                                    await _fetchCategories();
                                    onSelected(int.tryParse(
                                        newCategory['category_id'].toString()));
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    if (!mounted) return;
                                    setSheet(() => isAdding = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Gagal tambah kategori: $e')),
                                    );
                                  }
                                },
                          child: isAdding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TaskHeader extends StatelessWidget {
  final TemaData t;
  final int activeCount;
  final int doneCount;

  const _TaskHeader({
    required this.t,
    required this.activeCount,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.border),
        boxShadow: t.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Saya',
                  style: GoogleFonts.montserrat(
                    color: t.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$activeCount aktif, $doneCount selesai',
                  style: GoogleFonts.montserrat(
                    color: t.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: t.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.fact_check_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TemaData t;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.t,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Cari task...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: t.surface,
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final TemaData t;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.t,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: t.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final selected = value == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  label: Text(option),
                  selectedColor: t.accent,
                  backgroundColor: t.surface,
                  side: BorderSide(color: selected ? t.accent : t.border),
                  labelStyle: GoogleFonts.montserrat(
                    color: selected ? Colors.white : t.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => onChanged(option),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TemaData t;
  final Map<String, dynamic> task;
  final String Function(String) priorityLabel;
  final Color Function(String, TemaData) priorityColor;
  final String Function(dynamic) deadlineLabel;
  final Future<void> Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const _TaskTile({
    required this.t,
    required this.task,
    required this.priorityLabel,
    required this.priorityColor,
    required this.deadlineLabel,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task['status'] == 'done';
    final priority = task['priority']?.toString() ?? 'medium';
    final color = priorityColor(priority, t);

    return InkWell(
      onTap: () => onEdit(task),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => onToggle(task),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
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
                        color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 13),
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
                      fontWeight: FontWeight.w900,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaPill(
                        t: t,
                        icon: Icons.event_rounded,
                        label: deadlineLabel(task['deadline']),
                      ),
                      if (task['category_name'] != null)
                        _MetaPill(
                          t: t,
                          icon: Icons.folder_open_rounded,
                          label: task['category_name'].toString(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                priorityLabel(priority),
                style: GoogleFonts.montserrat(
                  color: color,
                  fontSize: 10,
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

class _MetaPill extends StatelessWidget {
  final TemaData t;
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.t,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: t.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: t.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final TemaData t;

  const _EmptyTasks({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: t.accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.inbox_outlined, color: t.accent, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada task',
            style: GoogleFonts.montserrat(
              color: t.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah filter atau buat task baru.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: t.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TemaData t;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.t,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.montserrat(color: t.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: t.surfaceVariant.withValues(alpha: t.isDark ? 0.5 : 0.8),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final TemaData t;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({
    required this.t,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: t.surfaceVariant.withValues(alpha: t.isDark ? 0.5 : 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, color: t.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: GoogleFonts.montserrat(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final TemaData t;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    final color = value == 'high'
        ? t.danger
        : value == 'low'
            ? t.success
            : t.warning;
    return Expanded(
      child: ChoiceChip(
        selected: active,
        showCheckmark: false,
        label: Center(child: Text(label)),
        selectedColor: color,
        backgroundColor:
            t.surfaceVariant.withValues(alpha: t.isDark ? 0.5 : 0.8),
        side: BorderSide(color: active ? color : t.border),
        labelStyle: GoogleFonts.montserrat(
          color: active ? Colors.white : t.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final TemaData t;
  final List<dynamic> categories;
  final int? selectedCategoryId;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.t,
    required this.categories,
    required this.selectedCategoryId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Map? category;
    if (selectedCategoryId != null) {
      for (final item in categories) {
        final candidate = item as Map;
        if (int.tryParse(candidate['category_id'].toString()) ==
            selectedCategoryId) {
          category = candidate;
          break;
        }
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: t.surfaceVariant.withValues(alpha: t.isDark ? 0.5 : 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.folder_open_rounded, color: t.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category?['category_name']?.toString() ?? 'Tanpa kategori',
                style: GoogleFonts.montserrat(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}
