import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../screens/tema_screen.dart';

class EditTaskSheet {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> task,
    required List<dynamic> categories,
    required VoidCallback onTaskUpdated,
    required Future<void> Function() onCategoriesUpdated,
  }) {
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
                          _showCategorySelector(context, selectedCategoryId, categories, onCategoriesUpdated, (val) {
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
                                  ? (categories.firstWhere((c) => c['category_id'] == selectedCategoryId, orElse: () => {'category_name': 'Pilih Kategori'})['category_name'])
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
                                    onTaskUpdated();
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

  static void _showCategorySelector(BuildContext context, int? currentCategoryId, List<dynamic> categories, Future<void> Function() onCategoriesUpdated, Function(int?) onSelected, TemaData t) {
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
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
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
                    if (categories.isNotEmpty) const Divider(),
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
                              await onCategoriesUpdated();
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

  static Widget _inputField(TextEditingController controller, String hint, IconData icon, TemaData t, {int maxLines = 1}) {
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
          alignLabelWithHint: false,
          prefixIcon: Icon(icon, color: t.textSecondary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month - 1];
  }

  static String _dateKey(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  static Color _colorForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'tinggi':
        return const Color(0xFFE53935);
      case 'low':
      case 'rendah':
        return const Color(0xFF43A047);
      case 'medium':
      case 'sedang':
      default:
        return const Color(0xFF1E88E5);
    }
  }
}
