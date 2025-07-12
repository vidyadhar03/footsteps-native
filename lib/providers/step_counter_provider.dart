import 'package:flutter/material.dart';

class StepCounterProvider extends ChangeNotifier {
  int _stepCount = 0;

  int get stepCount => _stepCount;

  void increment() {
    _stepCount++;
    notifyListeners();
  }
} 