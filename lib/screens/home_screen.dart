import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/alarm_provider.dart';
import '../providers/theme_provider.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';
import '../services/background_service.dart';
import '../services/prediction_service.dart';
import '../services/recent_destinations_service.dart';
import '../services/battery_service.dart';
import '../services/sound_service.dart';
import '../screens/map_picker_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarm = context.watch<AlarmProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('🚌 Smart Drop Alarm'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(alarm: alarm),
            const SizedBox(height: 20),
            _DestinationCard(alarm: alarm),
            const SizedBox(height: 20),
            _RadiusCard(alarm: alarm),
            const SizedBox(height: 20),
            _SoundCard(),
            const SizedBox(height: 20),
            _PermissionCard(),
            const SizedBox(height: 30),
            _AlarmButton(alarm: alarm),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AlarmProvider alarm;
  const _StatusCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                alarm.isAlarmTriggered
                    ? Icons.notifications_active
                    : alarm.isAlarmActive
                        ? Icons.gps_fixed
                        : Icons.gps_off,
                key: ValueKey(alarm.isAlarmTriggered
                    ? 'triggered'
                    : alarm.isAlarmActive
                        ? 'active'
                        : 'off'),
                size: 64,
                color: alarm.isAlarmTriggered
                    ? Colors.red
                    : alarm.isAlarmActive
                        ? Colors.green
                        : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              alarm.isAlarmTriggered
                  ? '🔔 WAKE UP! You\'re near your destination!'
                  : alarm.isAlarmActive
                      ? '📍 Monitoring your location...'
                      : '😴 Set a destination and start the alarm',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (alarm.currentDistanceMeters != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alarm.currentDistanceMeters! >= 1000
                      ? '📏 ${(alarm.currentDistanceMeters! / 1000).toStringAsFixed(1)} km away'
                      : '📏 ${alarm.currentDistanceMeters!.toStringAsFixed(0)} m away',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (alarm.etaMinutes != null) ...[
                const SizedBox(height: 8),
                Text(
                  '⏱ ETA: ${alarm.etaMinutes!.toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (alarm.transportMode != null) ...[
                const SizedBox(height: 4),
                Text(
                  PredictionService.getModeLabel(alarm.transportMode!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
            if (alarm.isAlarmTriggered) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await AlarmService.stopAlarm();
                  context.read<AlarmProvider>().stopAlarm();
                  await BackgroundService.stop();
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop Alarm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            if (!alarm.isAlarmActive && !alarm.isAlarmTriggered) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await AlarmService.triggerAlarm();
                  await Future.delayed(const Duration(seconds: 3));
                  await AlarmService.stopAlarm();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Alarm test complete!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Test Alarm Sound'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final AlarmProvider alarm;
  const _DestinationCard({required this.alarm});

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  List<RecentDestination> _recents = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await RecentDestinationsService.load();
    if (mounted) setState(() => _recents = recents);
  }

  Future<void> _pickOnMap() async {
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (picked != null) {
      final name =
          '${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}';
      context.read<AlarmProvider>().setDestination(
            picked.latitude,
            picked.longitude,
            name,
          );
      await RecentDestinationsService.add(
        RecentDestination(
            lat: picked.latitude, lng: picked.longitude, name: name),
      );
      _loadRecents();
    }
  }

  void _selectRecent(RecentDestination recent) {
    context.read<AlarmProvider>().setDestination(
          recent.lat,
          recent.lng,
          recent.name,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Destination set to ${recent.name}')),
    );
  }
  void _shareDestination() {
  final alarm = widget.alarm;
  if (!alarm.hasDestination) return;

  final name = alarm.destinationName.isNotEmpty
      ? alarm.destinationName
      : '${alarm.destinationLat!.toStringAsFixed(4)}, ${alarm.destinationLng!.toStringAsFixed(4)}';

  final lat = alarm.destinationLat!;
  final lng = alarm.destinationLng!;
  final mapsLink = 'https://maps.google.com/?q=$lat,$lng';

  Share.share(
    '📍 My destination: $name\n🗺️ $mapsLink\n\n(Sent via Smart Drop Alarm)',
    subject: 'My destination — $name',
  );
}
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Destination',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.alarm.hasDestination
                        ? widget.alarm.destinationName.isNotEmpty
                            ? widget.alarm.destinationName
                            : '${widget.alarm.destinationLat!.toStringAsFixed(4)}, ${widget.alarm.destinationLng!.toStringAsFixed(4)}'
                        : 'No destination set',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (widget.alarm.hasDestination)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
           SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _pickOnMap,
    icon: const Icon(Icons.map),
    label: const Text('Pick on Map'),
  ),
),

// Share button — only show when destination is set
if (widget.alarm.hasDestination) ...[
  const SizedBox(height: 8),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _shareDestination(),
      icon: const Icon(Icons.share),
      label: const Text('Share Destination'),
    ),
  ),
],
            if (_recents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🕐 Recent',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await RecentDestinationsService.clear();
                      _loadRecents();
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              ..._recents.map(
                (recent) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(
                    recent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectRecent(recent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadiusCard extends StatelessWidget {
  final AlarmProvider alarm;
  const _RadiusCard({required this.alarm});

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📏 Alert Radius',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatRadius(alarm.radiusInMeters),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Alarm triggers when you are within this distance',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: alarm.radiusInMeters.clamp(500, 20000),
              min: 500,
              max: 20000,
              divisions: 39,
              onChanged: (value) =>
                  context.read<AlarmProvider>().setRadius(value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('500 m', style: Theme.of(context).textTheme.bodySmall),
                Text('20 km', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🧠 Smart radius',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Switch(
                  value: alarm.useSmartRadius,
                  onChanged: (v) =>
                      context.read<AlarmProvider>().toggleSmartRadius(v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundCard extends StatefulWidget {
  @override
  State<_SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends State<_SoundCard> {
  String _selectedSound = 'sounds/alarm.mp3';

  @override
  void initState() {
    super.initState();
    _loadSound();
  }

  Future<void> _loadSound() async {
    final sound = await SoundService.getSelectedSound();
    if (mounted) setState(() => _selectedSound = sound);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎵 Alarm Sound',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...SoundService.availableSounds.map(
              (sound) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(sound['name']!),
                value: sound['file']!,
                groupValue: _selectedSound,
                onChanged: (value) async {
                  if (value != null) {
                    await SoundService.setSelectedSound(value);
                    setState(() => _selectedSound = value);
                    // Preview the sound
                    await AlarmService.stopAlarm();
                    final player = AudioPlayer();
                    await player.play(AssetSource(value));
                    await Future.delayed(const Duration(seconds: 2));
                    await player.stop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatefulWidget {
  @override
  State<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<_PermissionCard> {
  bool _gpsOk = false;
  bool _batterySaverOn = false;
  int _batteryLevel = 100;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    final result = await LocationService.requestPermission();
    final batterySaver = await BatteryService.isBatterySaverOn();
    final batteryLevel = await BatteryService.getBatteryLevel();
    if (mounted) {
      setState(() {
        _gpsOk = result.isSuccess;
        _batterySaverOn = batterySaver;
        _batteryLevel = batteryLevel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _gpsOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _gpsOk ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _gpsOk
                        ? '✅ Location permission granted'
                        : '⚠️ Location permission needed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (!_gpsOk)
                  TextButton(
                    onPressed: _checkAll,
                    child: const Text('Fix'),
                  ),
              ],
            ),
            if (_batterySaverOn) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.battery_saver,
                      color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ Battery saver is ON — may kill GPS in background!',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ],
            if (_batteryLevel < 20) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.battery_alert,
                      color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🔋 Battery is low (${_batteryLevel}%) — plug in before sleeping!',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlarmButton extends StatelessWidget {
  final AlarmProvider alarm;
  const _AlarmButton({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: alarm.isAlarmTriggered ? null : () => _toggleAlarm(context),
        icon: Icon(alarm.isAlarmActive ? Icons.stop : Icons.play_arrow,
            size: 28),
        label: Text(
          alarm.isAlarmActive ? 'Stop Alarm' : 'Start Alarm',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: alarm.isAlarmActive ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAlarm(BuildContext context) async {
    final provider = context.read<AlarmProvider>();

    if (provider.isAlarmActive) {
      await AlarmService.stopMonitoring();
      await AlarmService.stopAlarm();
      await BackgroundService.stop();
      provider.stopAlarm();
    } else {
      if (!provider.hasDestination) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('⚠️ Please set a destination first!')),
        );
        return;
      }

      final locationResult = await LocationService.requestPermission();
      if (!locationResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationResult.errorMessage ?? 'Location error'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await BackgroundService.start();
      provider.startAlarm();
      await AlarmService.startMonitoring(provider);
    }
  }
}