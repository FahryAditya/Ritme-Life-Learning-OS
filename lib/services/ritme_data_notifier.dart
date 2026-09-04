import 'package:flutter/material.dart';

class RitmeDataNotifier extends ChangeNotifier {
  static final RitmeDataNotifier instance = RitmeDataNotifier._internal();
  RitmeDataNotifier._internal();

  void notifyDataChanged() {
    notifyListeners();
  }
}
