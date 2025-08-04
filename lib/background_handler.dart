import 'dart:math';
import 'package:WhereIsMyMetro/main.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

bool _alarmTriggered = false;

Future<void> initBackgroundGeolocation(
  double destinationLat,
  double destinationLng,
) async {
  print("[Geo] Initializing background geolocation...");

  await bg.BackgroundGeolocation.ready(
    bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 50,
      stopOnTerminate: false, // ✅ survives kill
      startOnBoot: true, // ✅ resumes on reboot
      debug: true,
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
    ),
  );

  print("[Geo] BackgroundGeolocation ready!");

  // Log motion state changes
  bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
    print(
      "[Geo] Motion change -> isMoving: ${location.isMoving}, "
      "Lat: ${location.coords.latitude}, Lng: ${location.coords.longitude}",
    );
  });

  // Handle location updates
  bg.BackgroundGeolocation.onLocation((bg.Location location) {
    double lat = location.coords.latitude;
    double lng = location.coords.longitude;

    print("[Geo] Location received: lat=$lat, lng=$lng");

    double distance = calculateHaversineDistance(
      lat,
      lng,
      destinationLat,
      destinationLng,
    );
    print("[Geo] Distance to destination: ${distance.toStringAsFixed(3)} km");

    if (!_alarmTriggered && distance <= 1.0) {
      _alarmTriggered = true;
      print("[Geo] Within 1 km radius. Triggering alarm...");
      triggerAlarm();
      bg.BackgroundGeolocation.stop(); // optional if tracking is one-time
    }
  });

  await bg.BackgroundGeolocation.start();
  print("[Geo] Background tracking started.");
}

double calculateHaversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const R = 6371; // Radius of Earth in km
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double deg) => deg * pi / 180;

Future<void> triggerAlarm() async {
  // Play alarm
  FlutterRingtonePlayer().playAlarm(looping: true, volume: 1.0, asAlarm: true);

  // Show notification with STOP action
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Notification channel for alarm',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('STOP_ALARM', 'Stop Alarm'),
        ],
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    'Alarm Ringing',
    'Tap to stop the alarm',
    platformChannelSpecifics,
  );
}

void stopAlarm() {
  FlutterRingtonePlayer().stop();
  flutterLocalNotificationsPlugin.cancel(0); // remove notification
}
