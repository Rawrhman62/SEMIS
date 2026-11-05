import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  SyncService.instance.initialize(); // Mulai background sync listener
  runApp(const SemisApp());
}

class SemisApp extends StatelessWidget {
  const SemisApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF0B5A47);
    const mint = Color(0xFF38A3A5);
    const blue = Color(0xFF2563EB);
    const darkText = Color(0xFF1A2E26);
    const background = Color(0xFFF3F7F5);

    return MaterialApp(
      title: 'SEMIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',

        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          primary: forest,
          secondary: mint,
          surface: Colors.white,
          error: const Color(0xFFDC2626),
        ),

        scaffoldBackgroundColor: background,

        appBarTheme: const AppBarTheme(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: darkText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: darkText,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F7F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: forest,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: blue,
          foregroundColor: Colors.white,
        ),
      ),

      home: Builder(
        builder: (homeContext) => LoginScreen(
          onLogin: () {
            Navigator.of(homeContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MainShell(),
              ),
            );
          },
        ),
      ),
    );
  }
}
