import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../providers/alarm_provider.dart';
import 'distance_service.dart';
import 'sound_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // Set audio to media mode so it plays even on silent
    await _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  static Future<void> startMonitoring(AlarmProvider provider) async {
    await DistanceService.startMonitoring(provider);
  }

  static Future<void> stopMonitoring() async {
    await DistanceService.stopMonitoring();
    await _audioPlayer.stop();
  }

  static Future<void> triggerAlarm() async {
  const androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Drop Alarm',
    channelDescription: 'Alerts when near destination',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    playSound: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
  );
  const notificationDetails = NotificationDetails(android: androidDetails);
  await _notifications.show(
    0,
    '🔔 Wake Up!',
    'You are near your destination!',
    notificationDetails,
  );

  // Play whichever sound the user selected
  final selectedSound = await SoundService.getSelectedSound();
  await _audioPlayer.play(AssetSource(selectedSound));

  final bool? hasVibrator = await Vibration.hasVibrator();
  if (hasVibrator == true) {
    Vibration.vibrate(
      pattern: [0, 1000, 500, 1000, 500, 1000],
      repeat: 0,
    );
  }
}

  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
    await _notifications.cancelAll();
    Vibration.cancel();
  }
}