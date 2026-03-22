import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'voice_service.dart';
import 'package:flutter/material.dart';

class SafetyService {
  static Timer? _unresponsiveTimer;
  static Timer? _repeatAlarmTimer;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Call this when alarm triggers — starts watching if user responds
  static Future<void> startUnresponsiveWatch() async {
    // If user doesn't stop alarm in 2 minutes, escalate
    _unresponsiveTimer = Timer(const Duration(minutes: 2), () {
      _escalate();
    });

    // Re-announce every 30 seconds until user responds
    _repeatAlarmTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      await VoiceService.announceArrival();
    });
  }

  static Future<void> _escalate() async {
    // Louder notification
    const androidDetails = AndroidNotificationDetails(
      'safety_channel',
      'Safety Alert',
      channelDescription: 'User may have missed their stop',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      color: Color(0xFFFF0000),
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(
      1,
      '⚠️ Did you miss your stop?',
      'You haven\'t responded to the alarm. Are you okay?',
      notificationDetails,
    );

    // Voice escalation
    await VoiceService.stop();
    await Future.delayed(const Duration(milliseconds: 500));

    final ttsService = VoiceService.getTts();
    await ttsService.setSpeechRate(0.4);
    await ttsService.setVolume(1.0);
    await ttsService.speak(
        'Emergency alert! You may have missed your stop. Please check your location immediately!');
  }

  // Call this when user stops the alarm
  static Future<void> cancel() async {
    _unresponsiveTimer?.cancel();
    _unresponsiveTimer = null;
    _repeatAlarmTimer?.cancel();
    _repeatAlarmTimer = null;
    await VoiceService.stop();
    await _notifications.cancel(1);
  }
}