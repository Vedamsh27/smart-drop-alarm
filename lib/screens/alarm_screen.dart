import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import '../services/alarm_service.dart';
import '../services/background_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm(BuildContext context) async {
    await AlarmService.stopAlarm();
    await AlarmService.stopMonitoring();
    await BackgroundService.stop();
    if (context.mounted) {
      context.read<AlarmProvider>().stopAlarm();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _snooze(BuildContext context) async {
    // Silence sound and vibration but keep GPS monitoring alive
    await AlarmService.stopAlarm();

    if (context.mounted) {
      // Reset triggered flag so alarm can re-trigger when still nearby
      context.read<AlarmProvider>().snooze();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💤 Snoozed — alarm will re-trigger if still nearby!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Go back to home screen — GPS keeps running in background
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarm = context.watch<AlarmProvider>();

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnimation,
                child: const Icon(
                  Icons.notifications_active,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '🔔 WAKE UP!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'You are near your destination!',
                style: TextStyle(color: Colors.white70, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  alarm.destinationName.isNotEmpty
                      ? '📍 ${alarm.destinationName}'
                      : '📍 ${alarm.destinationLat?.toStringAsFixed(4)}, ${alarm.destinationLng?.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (alarm.currentDistanceMeters != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    alarm.currentDistanceMeters! >= 1000
                        ? '📏 ${(alarm.currentDistanceMeters! / 1000).toStringAsFixed(1)} km away'
                        : '📏 ${alarm.currentDistanceMeters!.toStringAsFixed(0)} m away',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),

              // Stop button
              SizedBox(
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () => _stopAlarm(context),
                  icon: const Icon(Icons.stop_circle, size: 32),
                  label: const Text(
                    'I\'M AWAKE — STOP ALARM',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Snooze button
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _snooze(context),
                  icon: const Icon(Icons.snooze, color: Colors.white70),
                  label: const Text(
                    'Snooze — keep monitoring',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}