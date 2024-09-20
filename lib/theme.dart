import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inspecciones/infrastructure/datasources/providers.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) =>
    ThemeNotifier(
        _buildGomacTheme(
            ref.watch(localPreferencesDataSourceProvider).getTema() ?? true
                ? Brightness.light
                : Brightness.dark),
        ref));

class ThemeNotifier extends StateNotifier<ThemeData> {
  final Ref ref;
  ThemeNotifier(super.state, this.ref);
  void switchTheme() {
    state.brightness == Brightness.light
        ? _setTheme(Brightness.dark)
        : _setTheme(Brightness.light);
  }

  void _setTheme(Brightness brightness) {
    ref
        .read(localPreferencesDataSourceProvider)
        .saveTema(brightness == Brightness.light);
    state = _buildGomacTheme(brightness);
  }
}

ThemeData _buildGomacTheme(Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF665c77), brightness: brightness),
  );
}

// ignore: unused_element
ThemeData _buildFlutterTheme(Brightness brightness) {
  switch (brightness) {
    case Brightness.dark:
      return ThemeData.dark();

    case Brightness.light:
      return ThemeData.light();
  }
}

// ignore: unused_element
ThemeData _buildGomacThemeFromBase(Brightness brightness) {
  final ThemeData baseTheme;
  switch (brightness) {
    case Brightness.dark:
      baseTheme = ThemeData.dark();
      break;
    case Brightness.light:
      baseTheme = ThemeData.light();
      break;
  }
  return baseTheme.copyWith(
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      filled: true,
    ),
    primaryColorLight: const Color.fromRGBO(229, 236, 233, 1),
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: const Color.fromRGBO(28, 44, 59, 1),
      secondary: const Color.fromRGBO(237, 181, 34, 1),
    ),
    highlightColor: const Color.fromRGBO(237, 181, 34, 0.5),
    scaffoldBackgroundColor: const Color.fromRGBO(114, 163, 141, 1),
    visualDensity: VisualDensity.compact,
    textTheme: baseTheme.textTheme.copyWith(
      displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.25),
    ),
    /*inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      border: const UnderlineInputBorder(),
      fillColor: Colors.grey.withOpacity(.3),
      filled: true,
    ),*/
  );
}
