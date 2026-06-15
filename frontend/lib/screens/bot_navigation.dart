import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'beranda_screen.dart';
import 'calendar_screen.dart';
import 'pomodoro_screen.dart';
import 'priority_screen.dart';
import 'task_screen.dart';
import 'tema_screen.dart';

class BotNavigation extends StatelessWidget {
  final int currentIndex;

  const BotNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaData(),
      builder: (context, child) {
        final t = TemaData();

        return SafeArea(
          top: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: t.border),
              boxShadow: t.softShadow,
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 64,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? t.accent : t.textSecondary,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected ? Colors.white : t.textSecondary,
                    size: selected ? 21 : 20,
                  );
                }),
                indicatorColor: t.accent,
                backgroundColor: Colors.transparent,
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                elevation: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_rounded),
                    selectedIcon: Icon(Icons.fact_check_rounded),
                    label: 'Task',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.flag_outlined),
                    selectedIcon: Icon(Icons.flag_rounded),
                    label: 'Prioritas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Kalender',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer_rounded),
                    label: 'Fokus',
                  ),
                ],
                onDestinationSelected: (index) {
                  if (index == currentIndex) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => _screenFor(index)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _screenFor(int index) {
    return switch (index) {
      0 => const BerandaScreen(),
      1 => const TaskScreen(),
      2 => const PriorityScreen(),
      3 => const CalendarScreen(),
      4 => const PomodoroScreen(),
      _ => const BerandaScreen(),
    };
  }
}
