import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocalLensApp());
}

class VocalLensApp extends StatefulWidget {
  const VocalLensApp({super.key});

  @override
  State<VocalLensApp> createState() => _VocalLensAppState();
}

class _VocalLensAppState extends State<VocalLensApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ultra-clean font styling
    final fontName = GoogleFonts.plusJakartaSans().fontFamily;

    // Premium Deep Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accentCyan,
        surface: AppColors.darkSurface,
        onSurface: Color(0xFFF1F5F9),
        surfaceContainerHighest: AppColors.darkCard,
      ),
      fontFamily: fontName,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
    );

    // Premium Crisp Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accentCyan,
        surface: AppColors.lightSurface,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: AppColors.lightInput,
      ),
      fontFamily: fontName,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
    );

    return MaterialApp(
      title: 'VocalLens - Photo & Text Voice AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
