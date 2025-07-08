import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/timer_service.dart';
import 'services/schedule_service.dart';
import 'services/protection_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ScreenLockApp());
}

class ScreenLockApp extends StatelessWidget {
  const ScreenLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => ScheduleService()),
        ChangeNotifierProvider(create: (_) => ProtectionService()),
      ],
      child: MaterialApp(
        title: 'Screen Lock App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

