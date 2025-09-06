import 'package:flutter/foundation.dart';

class AppState {
  AppState._();
  static final AppState I = AppState._();

  static final ValueNotifier<String> lang = ValueNotifier<String>('en');

  static void toggleLang() {
    lang.value = (lang.value == 'en') ? 'si' : 'en';
  }
}
