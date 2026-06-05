import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import semua screen yang dibutuhkan
import 'beranda_screen.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'priority_screen.dart';
import 'pomodoro_screen.dart';

// Wajib import tema_screen untuk integrasi warna dinamis
import 'tema_screen.dart';

class BotNavigation extends StatelessWidget {
  final int currentIndex;

  const BotNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan ListenableBuilder agar otomatis refresh saat tema diubah
    return ListenableBuilder(
        listenable: TemaData(),
        builder: (context, child) {
          final t = TemaData(); // Ambil instance tema saat ini

          return Container(
            // Margin untuk jarak dari tepi luar layar
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),

            // Padding untuk memberikan ruang/jarak ekstra di bagian dalam
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),

            decoration: BoxDecoration(
              color: t
                  .surface, // Background dinamis (putih di Terang, gelap di Gelap)
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                // Memberikan border tipis khusus di mode gelap agar terpisah dari background
                color: t.isDark ? t.border : Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  // Shadow lebih gelap saat mode gelap agar efek melayang tetap terlihat
                  color: Colors.black.withOpacity(t.isDark ? 0.3 : 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  // Cegah navigasi jika menekan tab yang sedang aktif
                  if (index == currentIndex) return;

                  if (index == 0) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BerandaScreen()));
                  } else if (index == 1) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const TaskScreen()));
                  } else if (index == 2) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PriorityScreen()));
                  } else if (index == 3) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalendarScreen()));
                  } else if (index == 4) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PomodoroScreen()));
                  }
                },
                type: BottomNavigationBarType.fixed,

                // Ubah background jadi transparan agar mengikuti warna Container
                backgroundColor: Colors.transparent,
                elevation: 0,

                selectedItemColor:
                    t.accent, // Warna ikon & teks tab aktif dinamis
                unselectedItemColor: t
                    .textSecondary, // Warna ikon & teks tab tidak aktif dinamis
                showUnselectedLabels: true,

                // Icon diperkecil agar terlihat lebih padat
                iconSize: 20,

                selectedLabelStyle: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),

                items: const [
                  BottomNavigationBarItem(
                      icon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.home_outlined)),
                      activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.home)),
                      label: 'Beranda'),
                  BottomNavigationBarItem(
                      icon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.list_alt)),
                      label: 'Task'),
                  BottomNavigationBarItem(
                      icon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.outlined_flag)),
                      activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.flag)),
                      label: 'Prioritas'),
                  BottomNavigationBarItem(
                      icon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.calendar_month_outlined)),
                      activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.calendar_month)),
                      label: 'Kalender'),
                  BottomNavigationBarItem(
                      icon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.timer_outlined)),
                      activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Icon(Icons.timer)),
                      label: 'Pomodoro'),
                ],
              ),
            ),
          );
        });
  }
}
