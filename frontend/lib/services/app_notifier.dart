import 'package:flutter/material.dart';

class AppNotifier extends ChangeNotifier {
  static final AppNotifier instance = AppNotifier();
  
  void notifyAll() {
    notifyListeners();
  }
}
