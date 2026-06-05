import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notifikasi_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [
    NotificationModel(
        id: '1',
        title: 'Visualisasi Data',
        priority: 'TINGGI',
        timeLabel: 'Besok',
        isRead: false),
    NotificationModel(
        id: '2',
        title: 'ABP',
        priority: 'RENDAH',
        timeLabel: 'Besok',
        isRead: false),
    NotificationModel(
        id: '3',
        title: 'Tugas Matematika',
        priority: 'SEDANG',
        timeLabel: 'Hari Ini',
        isRead: true),
    NotificationModel(
        id: '4',
        title: 'Presentasi Kelompok',
        priority: 'TINGGI',
        timeLabel: '2 hari lagi',
        isRead: true),
  ];

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'TINGGI':
        return const Color(0xFFEF4444);
      case 'SEDANG':
        return const Color(0xFFF59E0B);
      case 'RENDAH':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  Color _getTimeLabelColor(String label) {
    if (label == 'Hari Ini') return const Color(0xFFEF4444);
    if (label == 'Besok') return const Color(0xFF364C84);
    return const Color(0xFF6B7280);
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                priority: n.priority,
                timeLabel: n.timeLabel,
                isRead: true,
              ))
          .toList();
    });
  }

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              top: kToolbarHeight + 8,
              right: 12,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 420),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                        child: Row(
                          children: [
                            Text('Kotak Masuk',
                                style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E293B))),
                            const SizedBox(width: 8),
                            if (_unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF364C84),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$_unreadCount',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _markAllRead();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero),
                              child: Text('Tandai dibaca',
                                  style: GoogleFonts.montserrat(
                                      color: const Color(0xFF364C84),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Daftar notifikasi
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: notif.isRead
                                    ? Colors.white
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: notif.isRead
                                      ? Colors.grey.shade100
                                      : const Color(0xFF364C84)
                                          .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(notif.priority),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(notif.title,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: notif.isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.bold,
                                                color:
                                                    const Color(0xFF1E293B))),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: _getPriorityColor(
                                                    notif.priority),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(notif.priority,
                                                style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getPriorityColor(
                                                        notif.priority))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getTimeLabelColor(notif.timeLabel)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(notif.timeLabel,
                                        style: GoogleFonts.montserrat(
                                            color: _getTimeLabelColor(
                                                notif.timeLabel),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Tombol Lihat Aktivitas
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF364C84),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text('Lihat Aktivitas',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text('Inbox',
                style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B))),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF364C84),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_unreadCount',
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Tandai semua dibaca',
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF364C84),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          // Tombol popup notifikasi
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.grey),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text('$_unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotificationPopup(context),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Tidak ada notifikasi',
                      style: GoogleFonts.montserrat(
                          color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        notif.isRead ? Colors.white : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: notif.isRead
                          ? Colors.grey.shade200
                          : const Color(0xFF364C84).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                          color: _getPriorityColor(notif.priority),
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    title: Text(notif.title,
                        style: GoogleFonts.montserrat(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1E293B))),
                    subtitle: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _getPriorityColor(notif.priority),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(notif.priority,
                            style: GoogleFonts.montserrat(
                                color: _getPriorityColor(notif.priority),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _getTimeLabelColor(notif.timeLabel)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(notif.timeLabel,
                          style: GoogleFonts.montserrat(
                              color: _getTimeLabelColor(notif.timeLabel),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _showNotificationPopup(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF364C84),
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('Lihat Aktivitas',
              style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
