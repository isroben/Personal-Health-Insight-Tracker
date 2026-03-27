import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appPreferencesProvider = StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>((ref) {
  return AppPreferencesNotifier();
});

class AppPreferencesState {
  final ThemeMode themeMode;
  final Locale locale;
  final double textScaleFactor;
  final String themeModeStr;
  final String localeStr;

  AppPreferencesState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.textScaleFactor = 1.0,
    this.themeModeStr = 'System',
    this.localeStr = 'English',
  });

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    double? textScaleFactor,
    String? themeModeStr,
    String? localeStr,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      themeModeStr: themeModeStr ?? this.themeModeStr,
      localeStr: localeStr ?? this.localeStr,
    );
  }
}

class AppPreferencesNotifier extends StateNotifier<AppPreferencesState> {
  AppPreferencesNotifier() : super(AppPreferencesState()) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('themeMode') ?? 'System';
    final langStr = prefs.getString('language') ?? 'English';
    final scale = prefs.getDouble('fontSize') ?? 1.0;

    ThemeMode mode = _parseTheme(themeStr);
    Locale loc = _parseLocale(langStr);

    state = AppPreferencesState(
      themeMode: mode,
      locale: loc,
      textScaleFactor: scale,
      themeModeStr: themeStr,
      localeStr: langStr,
    );
  }

  Future<void> setThemeMode(String themeStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeStr);
    state = state.copyWith(themeMode: _parseTheme(themeStr), themeModeStr: themeStr);
  }

  Future<void> setLanguage(String langStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langStr);
    state = state.copyWith(locale: _parseLocale(langStr), localeStr: langStr);
  }

  Future<void> setFontSize(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', scale);
    state = state.copyWith(textScaleFactor: scale);
  }

  ThemeMode _parseTheme(String val) {
    if (val == 'Light') return ThemeMode.light;
    if (val == 'Dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Locale _parseLocale(String val) {
    if (val == 'Spanish') return const Locale('es');
    if (val == 'French') return const Locale('fr');
    if (val == 'German') return const Locale('de');
    return const Locale('en');
  }
}
