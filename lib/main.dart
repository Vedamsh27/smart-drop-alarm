import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/alarm_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/alarm_service.dart';
import 'services/background_service.dart';
import 'services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.initialize();
  await BackgroundService.initialize();
  await VoiceService.initialize();

  final alarmProvider = AlarmProvider();
  await alarmProvider.loadSavedState();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => alarmProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
      ],
      child: SmartDropAlarmApp(onboardingDone: onboardingDone),
    ),
  );
}

class SmartDropAlarmApp extends StatelessWidget {
  final bool onboardingDone;
  const SmartDropAlarmApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Smart Drop Alarm',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: onboardingDone
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}