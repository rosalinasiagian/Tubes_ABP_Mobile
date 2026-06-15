import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../services/app_notifier.dart';
import '../services/notification_prefs.dart';
import 'tema_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? name;
  final String? email;

  const ProfileScreen({
    super.key,
    this.name,
    this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0;
  bool _isNotificationOn = true;
  bool _isLoadingUser = true;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String? _photoUrl;
  File? _localPhotoFile;
  bool _isLoadingPhoto = false;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  @override
  void initState() {
    super.initState();
    _isNotificationOn = NotificationPrefs.instance.enabled;
    _nameController = TextEditingController(text: widget.name ?? '');
    _usernameController = TextEditingController(text: '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUser();
      if (!mounted) return;
      setState(() {
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        _nameController.text = '$firstName $lastName'.trim();
        _usernameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        _photoUrl = user['profile_picture'] ?? user['photo_url'];
        _isLoadingUser = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _pickAndCropImage(TemaData t) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Foto',
            toolbarColor: t.surface,
            toolbarWidgetColor: t.textPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Edit Foto',
            aspectRatioLockEnabled: true,
            resetButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _isLoadingPhoto = true);
        if (mounted) Navigator.pop(context);

        await ApiService.uploadPhoto(croppedFile.path);

        setState(() {
          _localPhotoFile = File(croppedFile.path);
          _isLoadingPhoto = false;
        });

        if (mounted) {
          _showSuccessDialog(context, t, 'Foto profil berhasil diperbaharui!');
          AppNotifier.instance.notifyAll();
        }
      }
    } catch (e) {
      setState(() => _isLoadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah foto: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto(TemaData t) async {
    try {
      setState(() => _isLoadingPhoto = true);
      if (mounted) Navigator.pop(context);

      await ApiService.deletePhoto();

      setState(() {
        _localPhotoFile = null;
        _photoUrl = null;
        _isLoadingPhoto = false;
      });

      if (mounted) {
        _showSuccessDialog(context, t, 'Foto profil berhasil dihapus!');
      }
    } catch (e) {
      setState(() => _isLoadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus foto: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  ImageProvider? get _photoProvider {
    if (_localPhotoFile != null) return FileImage(_localPhotoFile!);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    return null;
  }

  void _openPhotoViewer(TemaData t) {
    final image = _photoProvider;
    if (image == null) {
      _showPhotoDialog(context, t);
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Foto Profil',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image(
                            image: image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.broken_image_outlined,
                                  color: Colors.white54, size: 64),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Tutup',
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, TemaData t, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF16A34A), size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Ya',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, TemaData t, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFD6DD), width: 1),
                      ),
                    ),
                  ),
                  const Icon(Icons.close_rounded,
                      color: Color(0xFFF43F5E), size: 40),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Mengerti, terima kasih',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, TemaData t) {
    final bool hasPhoto = _localPhotoFile != null || _photoUrl != null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hasPhoto ? 'Kelola Foto Profil' : 'Unggah Foto Profil',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: t.textPrimary)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickAndCropImage(t),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: t.accentLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: t.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                          hasPhoto
                              ? 'Ganti Foto (Galeri)'
                              : 'Pilih foto dari media',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: t.accent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto maks 4 MB',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary)),
                    const SizedBox(height: 8),
                    _infoLine('Format', 'JPEG atau JPG', t),
                    _infoLine('Ukuran file', '40 KB – 2 MB (maks 4 MB)', t),
                    _infoLine('Dimensi minimum', '600 × 600 piksel', t),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasPhoto)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePhoto(t),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('Hapus Foto Profil',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text('Tutup',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: t.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, TemaData t) {
    final passCtrl = TextEditingController();
    bool isDeleteEnabled = false;
    bool deleted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (deleted) {
            return Dialog(
              backgroundColor: t.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF16A34A), size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text('Akun sudah dihapus',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Kembali ke Login',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            backgroundColor: t.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE53E3E), size: 22),
                      const SizedBox(width: 8),
                      Text('Konfirmasi Hapus Akun',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: const Color(0xFFE53E3E))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tindakan ini tidak bisa dibatalkan. Masukkan kata sandi untuk melanjutkan.',
                    style: GoogleFonts.openSans(
                        fontSize: 12, color: t.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text('Kata Sandi',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: t.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: GoogleFonts.openSans(
                        fontSize: 13, color: t.textPrimary),
                    onChanged: (val) {
                      setDialogState(() {
                        isDeleteEnabled = val.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi kamu',
                      hintStyle: GoogleFonts.openSans(
                          fontSize: 13, color: t.textSecondary),
                      filled: true,
                      fillColor: t.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: t.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE53E3E))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleteEnabled
                              ? () async {
                                  try {
                                    await ApiService.deleteAccount(
                                        passCtrl.text);
                                    if (context.mounted) {
                                      setDialogState(() => deleted = true);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Gagal menghapus akun: $e')),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: t.isDark
                                ? const Color(0xFF4A2020)
                                : const Color(0xFFFFCDD2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text('Hapus Akun',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: t.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text('Batal',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: t.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoLine(String key, String value, TemaData t) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $key: ',
              style: GoogleFonts.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary)),
          Expanded(
            child: Text(value,
                style:
                    GoogleFonts.openSans(fontSize: 11, color: t.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, _) {
        final t = TemaData();
        return Scaffold(
          backgroundColor: t.background,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: t.isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                      ]
                    : [
                        const Color(0xFFF3F7FF),
                        const Color(0xFFE6EFFF),
                      ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(t),
                    const SizedBox(height: 20),
                    _buildSubTabBar(t),
                    const SizedBox(height: 20),
                    _buildTabContent(t),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(TemaData t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: t.isDark ? 0.25 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, size: 14, color: t.textSecondary),
              label: Text('KEMBALI',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: t.textSecondary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _openPhotoViewer(t),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration:
                        BoxDecoration(color: t.surface, shape: BoxShape.circle),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: t.accentLight,
                          backgroundImage: _photoProvider,
                          child: (_localPhotoFile == null &&
                                  (_photoUrl == null || _photoUrl!.isEmpty))
                              ? Text(
                                  _getInitials(_nameController.text),
                                  style: GoogleFonts.montserrat(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: t.accent),
                                )
                              : null,
                        ),
                        if (_isLoadingPhoto) const CircularProgressIndicator(),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: t.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.surface, width: 2),
                            ),
                            child: const Icon(Icons.zoom_in_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border, width: 1.5),
                  ),
                  child: Text('PROFILE',
                      style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: t.textSecondary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingUser)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(_nameController.text,
                style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 14, color: t.textSecondary),
                const SizedBox(width: 4),
                Text(_emailController.text,
                    style: GoogleFonts.openSans(
                        color: t.textSecondary, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubTabBar(TemaData t) {
    final tabs = [
      const _TabMeta(Icons.person_outline_rounded, 'Profil', Color(0xFF6366F1),
          Color(0xFF4338CA)),
      const _TabMeta(Icons.lock_outline_rounded, 'Keamanan', Color(0xFF10B981),
          Color(0xFF047857)),
      const _TabMeta(Icons.settings_outlined, 'Preferensi', Color(0xFF3B82F6),
          Color(0xFF1D4ED8)),
      const _TabMeta(Icons.warning_amber_rounded, 'Zona Bahaya',
          Color(0xFFEF4444), Color(0xFFB91C1C)),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: t.isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final meta = tabs[i];
          final bool isSelected = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? meta.bgColor.withValues(alpha: t.isDark ? 0.2 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: meta.activeColor
                              .withValues(alpha: t.isDark ? 0.4 : 0.25))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      meta.icon,
                      size: 20,
                      color: isSelected ? meta.activeColor : t.textSecondary,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                meta.label,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: meta.activeColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(TemaData t) {
    switch (_activeTab) {
      case 0:
        return _buildProfilContent(t);
      case 1:
        return _buildKeamananContent(t);
      case 2:
        return _buildPreferensiContent(t);
      case 3:
        return _buildZonaBahayaContent(t);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfilContent(TemaData t) {
    return Column(
      children: [
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.badge_outlined, 'Informasi Pribadi',
                  'Kelola nama dan emailmu', t),
              const SizedBox(height: 16),
              _buildEditableField('NAMA LENGKAP', _nameController, t,
                  icon: Icons.person_outline),
              const SizedBox(height: 14),
              _buildEditableField('USERNAME', _usernameController, t,
                  icon: Icons.alternate_email),
              const SizedBox(height: 14),
              _buildEditableField('EMAIL AKUN', _emailController, t,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final names = _nameController.text.trim().split(' ');
                      final firstName = names.isNotEmpty ? names.first : '';
                      final lastName =
                          names.length > 1 ? names.skip(1).join(' ') : '';

                      await ApiService.updateUser({
                        'first_name': firstName,
                        'last_name': lastName,
                        'username': _usernameController.text.trim(),
                        'email': _emailController.text.trim(),
                      });
                      AppNotifier.instance.notifyAll();
                      if (!mounted) return;
                      _showSuccessDialog(
                          context, t, 'Profil berhasil\ndiperbarui!');
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text('Simpan Perubahan',
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSectionTitle(
                  Icons.camera_alt_outlined, 'Photo', 'Profile preview', t,
                  center: true),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: t.accentLight,
                    backgroundImage: _localPhotoFile != null
                        ? FileImage(_localPhotoFile!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty
                            ? NetworkImage(_photoUrl!)
                            : null) as ImageProvider?,
                    child: (_localPhotoFile == null &&
                            (_photoUrl == null || _photoUrl!.isEmpty))
                        ? Text(
                            _getInitials(_nameController.text),
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: t.accent,
                                fontSize: 22),
                          )
                        : null,
                  ),
                  if (_isLoadingPhoto) const CircularProgressIndicator(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_nameController.text}\n${_emailController.text}',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.openSans(fontSize: 12, color: t.textSecondary),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showPhotoDialog(context, t),
                icon: const Icon(Icons.upload, size: 16),
                label: Text('Ganti Photo',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeamananContent(TemaData t) {
    return Column(
      children: [
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.shield_outlined, 'Kata Sandi',
                  'Perbarui kredensial', t),
              const SizedBox(height: 16),
              _buildPasswordField(
                  'Password Saat Ini',
                  'Enter password saat ini',
                  _currentPassController,
                  _showCurrentPass, (v) {
                setState(() => _showCurrentPass = v);
              }, t),
              const SizedBox(height: 14),
              _buildPasswordField('Password Baru', 'Enter password baru',
                  _newPassController, _showNewPass, (v) {
                setState(() => _showNewPass = v);
              }, t),
              const SizedBox(height: 14),
              _buildPasswordField(
                  'Konfirmasi Password',
                  'Enter konfirmasi password',
                  _confirmPassController,
                  _showConfirmPass, (v) {
                setState(() => _showConfirmPass = v);
              }, t),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_currentPassController.text.trim().isEmpty) {
                          _showErrorDialog(
                              context, t, 'Current password harus diisi!');
                          return;
                        }
                        if (_newPassController.text.trim().isEmpty ||
                            _confirmPassController.text.trim().isEmpty) {
                          _showErrorDialog(context, t,
                              'Password baru dan konfirmasi password harus diisi!');
                          return;
                        }
                        final newPassword = _newPassController.text;
                        final isStrongPassword = newPassword.length >= 8 &&
                            RegExp(r'[A-Za-z]').hasMatch(newPassword) &&
                            RegExp(r'[0-9]').hasMatch(newPassword) &&
                            RegExp(r'[^A-Za-z0-9]').hasMatch(newPassword);
                        if (!isStrongPassword) {
                          _showErrorDialog(context, t,
                              'Password minimal 8 karakter dan harus berisi huruf, angka, serta simbol.');
                          return;
                        }
                        if (_newPassController.text !=
                            _confirmPassController.text) {
                          _showErrorDialog(
                              context, t, 'Konfirmasi password tidak cocok!');
                          return;
                        }
                        try {
                          final names = _nameController.text.trim().split(' ');
                          final firstName = names.isNotEmpty ? names.first : '';
                          final lastName =
                              names.length > 1 ? names.skip(1).join(' ') : '';

                          await ApiService.updateUser({
                            'first_name': firstName,
                            'last_name': lastName,
                            'username': _usernameController.text.trim(),
                            'email': _emailController.text.trim(),
                            'currentPassword': _currentPassController.text,
                            'newPassword': _newPassController.text,
                            'confirmPassword': _confirmPassController.text,
                          });
                          AppNotifier.instance.notifyAll();
                          if (!mounted) return;
                          _currentPassController.clear();
                          _newPassController.clear();
                          _confirmPassController.clear();
                          _showSuccessDialog(
                              context, t, 'Kata sandi berhasil\ndiperbarui!');
                        } catch (e) {
                          if (!mounted) return;
                          String errMsg = e.toString();
                          if (errMsg.startsWith('Exception: ')) {
                            errMsg = errMsg.replaceFirst('Exception: ', '');
                          }
                          _showErrorDialog(context, t, errMsg);
                        }
                      },
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: Text('Perbarui',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      _currentPassController.clear();
                      _newPassController.clear();
                      _confirmPassController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: t.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                    ),
                    child: Text('Hapus',
                        style: GoogleFonts.montserrat(color: t.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: t.isDark
                        ? const Color(0xFF137333).withValues(alpha: 0.2)
                        : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('PRAKTIK KEAMANAN TERBAIK',
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF137333))),
              ),
              const SizedBox(height: 16),
              _buildTipsItem(
                  '1',
                  'Gunakan minimal 8 karakter dengan kombinasi huruf, angka, dan simbol',
                  t),
              _buildTipsItem(
                  '2',
                  'Jangan gunakan ulang password dari situs lain seperti Media Sosial',
                  t),
              _buildTipsItem(
                  '3',
                  'Ganti passwordmu secara rutin untuk keamanan akun yang lebih baik',
                  t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferensiContent(TemaData t) {
    const Color toggleActive = Color(0xFF22C55E);
    final Color toggleInactive =
        t.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.notifications_none_outlined,
                  'Notifikasi', 'Kelola peringatan dan pengingat', t),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _isNotificationOn
                          ? toggleActive.withValues(alpha: 0.35)
                          : t.border),
                  color: _isNotificationOn
                      ? (t.isDark
                          ? toggleActive.withValues(alpha: 0.08)
                          : const Color(0xFFF0FDF4))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _isNotificationOn
                          ? toggleActive.withValues(alpha: 0.15)
                          : t.surfaceVariant,
                      child: Icon(
                        Icons.notifications_active,
                        color:
                            _isNotificationOn ? toggleActive : t.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifikasi Push',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _isNotificationOn
                                      ? (t.isDark
                                          ? toggleActive
                                          : const Color(0xFF15803D))
                                      : t.textPrimary)),
                          Text('Pengingat harian & task',
                              style: GoogleFonts.openSans(
                                  fontSize: 11, color: t.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isNotificationOn,
                      activeThumbColor: Colors.white,
                      activeTrackColor: toggleActive,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: toggleInactive,
                      onChanged: (val) {
                        setState(() => _isNotificationOn = val);
                        NotificationPrefs.instance.setEnabled(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCardWrapper(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: t.isDark
                        ? const Color(0xFF1A73E8).withValues(alpha: 0.2)
                        : const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('METADATA APLIKASI',
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A73E8))),
              ),
              const SizedBox(height: 12),
              _buildMetadataRow('VERSI', '1.0.0', t),
              Divider(color: t.divider),
              _buildMetadataRow(
                  'TEMA SISTEM', t.isDark ? 'Dark Mode' : 'Glass Light', t),
              Divider(color: t.divider),
              _buildMetadataRow('ID UNIK', 'USER-DYNAMIC', t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZonaBahayaContent(TemaData t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF3F1010) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color:
                t.isDark ? const Color(0xFF7F2020) : const Color(0xFFFEB2B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53E3E)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hapus Akun',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE53E3E))),
                    Text('Hapus akun dan semua data secara permanen',
                        style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: t.isDark
                                ? const Color(0xFFFC8181)
                                : Colors.red[300])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: t.surface, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Setelah kamu menghapus akun, tidak ada jalan kembali. Semua data termasuk task, kategori, preferensi, dan informasi profil akan dihapus secara permanen. Harap yakin sebelum melanjutkan.',
              style: GoogleFonts.openSans(
                  fontSize: 12, color: t.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: t.isDark
                    ? const Color(0xFF3D2E00)
                    : const Color(0xFFFEFCBF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.isDark
                        ? const Color(0xFF7A5900)
                        : const Color(0xFFF6E05E))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yang akan dihapus:',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB7791F))),
                const SizedBox(height: 6),
                Text(
                    '• Semua task dan kategori\n• Data profil dan foto\n• Semua preferensi dan pengaturan',
                    style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: t.isDark
                            ? const Color(0xFFD4A017)
                            : const Color(0xFFB7791F),
                        height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showDeleteAccountDialog(context, t),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text('Hapus Akunmu',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child, required TemaData t}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: t.isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(
      IconData icon, String title, String subtitle, TemaData t,
      {bool center = false}) {
    return Row(
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        CircleAvatar(
            radius: 16,
            backgroundColor: t.accentLight,
            child: Icon(icon, size: 16, color: t.accent)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment:
              center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: t.textPrimary)),
            Text(subtitle,
                style:
                    GoogleFonts.openSans(fontSize: 11, color: t.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, TemaData t,
      {IconData? icon, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: t.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.openSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: t.textSecondary)
                : null,
            suffixIcon: Icon(Icons.edit_outlined, size: 16, color: t.accent),
            filled: true,
            fillColor: t.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.accent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label,
      String placeholder,
      TextEditingController controller,
      bool isVisible,
      ValueChanged<bool> onToggle,
      TemaData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: t.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          style: GoogleFonts.openSans(fontSize: 13, color: t.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                GoogleFonts.openSans(fontSize: 13, color: t.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: t.textSecondary,
              ),
              onPressed: () => onToggle(!isVisible),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: t.surfaceVariant,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.accent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsItem(String number, String text, TemaData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 10,
              backgroundColor: t.isDark
                  ? const Color(0xFF137333).withValues(alpha: 0.25)
                  : const Color(0xFFE6F4EA),
              child: Text(number,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF137333),
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.openSans(
                      fontSize: 12, color: t.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String key, String value, TemaData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary)),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary)),
        ],
      ),
    );
  }
}

class _TabMeta {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color activeColor;
  const _TabMeta(this.icon, this.label, this.bgColor, this.activeColor);
}
