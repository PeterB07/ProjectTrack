import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:traccar_client/location_cache.dart';
import 'package:traccar_client/preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_partial_android/wakelock_partial_android.dart';

class GeolocationService {
  static final platform = MethodChannel('org.traccar.client/tracking');

  static Future<void> init() async {
    await bg.BackgroundGeolocation.requestPermission();
    await bg.BackgroundGeolocation.ready(Preferences.geolocationConfig());
    if (Platform.isAndroid) {
      await bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
    }
    bg.BackgroundGeolocation.onEnabledChange(onEnabledChange);
    bg.BackgroundGeolocation.onMotionChange(onMotionChange);
    bg.BackgroundGeolocation.onHeartbeat(onHeartbeat);
    bg.BackgroundGeolocation.onLocation(onLocation, (bg.LocationError error) {
      developer.log('Location error', error: error);
    });
   // Do not auto-start tracking
 }

 static Timer? _heartbeatTimer;

 static Future<void> start() async {
    await bg.BackgroundGeolocation.start();
    if (Platform.isAndroid) {
      platform.invokeMethod('startTrackingService');
    }
    // Force a fresh location update on start
    await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 3, // Get a few samples for better accuracy
      timeout: 10, // 10-second timeout
      persist: true, // Persist the location to the database
      extras: {'event': 'toggle_on'}, // Add an extra event flag
    );
    // Start heartbeat timer
    _startHeartbeatTimer();
  }

  static Future<void> stop() async {
    await sendOfflineStatus(); // Send offline status update
    await bg.BackgroundGeolocation.stop();
    if (Platform.isAndroid) {
      platform.invokeMethod('stopTrackingService');
    }
    // Stop heartbeat timer
    _stopHeartbeatTimer();
  }

  static Future<void> sendOfflineStatus() async {
    try {
      final deviceId = Preferences.instance.getString(Preferences.id)!;
      final restUri = Uri.parse('http://3.17.110.39:5055').replace(
        queryParameters: {
          'id': deviceId,
          'offline': 'true', // Indicate offline status
        },
      );
      await http.get(restUri);
    } catch (error) {
      developer.log('Failed to send offline status via HTTP', error: error);
    }
  }

  static Future<void> onEnabledChange(bool enabled) async {
    if (Preferences.instance.getBool(Preferences.wakelock) ?? false) {
      if (!enabled) {
        await WakelockPartialAndroid.release();
      }
    }
  }

  static Future<void> onMotionChange(bg.Location location) async {
    if (Preferences.instance.getBool(Preferences.wakelock) ?? false) {
      if (location.isMoving) {
        await WakelockPartialAndroid.acquire();
      } else {
        await WakelockPartialAndroid.release();
      }
    }
  }

  static Future<void> onHeartbeat(bg.HeartbeatEvent event) async {
    await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 1,
      persist: true,
      extras: {'heartbeat': true},
    );
  }

  static Future<void> onLocation(bg.Location location) async {
    if (_shouldDelete(location)) {
      try {
        await bg.BackgroundGeolocation.destroyLocation(location.uuid);
      } catch (error) {
        developer.log('Failed to delete location', error: error);
      }
    } else {
      LocationCache.set(location);
      await _sendLocation(location);
    }
  }

  static bool _shouldDelete(bg.Location location) {
    return false;
  }

  static double _distance(bg.Location from, bg.Location to) {
    const earthRadius = 6371008.8; // meters
    final dLat = _degToRad(to.coords.latitude - from.coords.latitude);
    final dLon = _degToRad(to.coords.longitude - from.coords.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final a =
        sinLat * sinLat +
        cos(_degToRad(from.coords.latitude)) *
            cos(_degToRad(to.coords.latitude)) *
            sinLon *
            sinLon;
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double degree) => degree * pi / 180.0;

  static Future<void> _sendLocation(bg.Location location) async {
    // Send HTTP GET to Traccar default HTTP protocol
    try {
      final deviceId = Preferences.instance.getString(Preferences.id)!;
      final restUri = Uri.parse('http://3.17.110.39:5055').replace(
        queryParameters: {
          'id': deviceId,
          'lat': location.coords.latitude.toString(),
          'lon': location.coords.longitude.toString(),
          'timestamp': location.timestamp,
        },
      );
      await http.get(restUri);
    } catch (error) {
      developer.log('Failed to send location via HTTP', error: error);
    }
  }

  static void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: true,
        extras: {'heartbeat': true},
      );
      await _sendHeartbeatLocation(location);
    });
  }

  static void _stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  static Future<void> _sendHeartbeatLocation(bg.Location location) async {
    // Send HTTP GET to Traccar default HTTP protocol
    try {
      final deviceId = Preferences.instance.getString(Preferences.id)!;
      final restUri = Uri.parse('http://3.17.110.39:5055').replace(
        queryParameters: {
          'id': deviceId,
          'lat': location.coords.latitude.toString(),
          'lon': location.coords.longitude.toString(),
          'timestamp': location.timestamp,
        },
      );
      await http.get(restUri);
    } catch (error) {
      developer.log('Failed to send location via HTTP', error: error);
    }
  }
}

@pragma('vm:entry-point')
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  await Preferences.init();
  switch (headlessEvent.name) {
    case bg.Event.ENABLEDCHANGE:
      await GeolocationService.onEnabledChange(headlessEvent.event as bool);
      break;
    case bg.Event.MOTIONCHANGE:
      await GeolocationService.onMotionChange(headlessEvent.event as bg.Location);
      break;
    case bg.Event.HEARTBEAT:
      await GeolocationService.onHeartbeat(headlessEvent.event as bg.HeartbeatEvent);
      break;
    case bg.Event.LOCATION:
      await GeolocationService.onLocation(headlessEvent.event as bg.Location);
      break;
  }
}
