import 'dart:async';
import 'package:flutter/services.dart';
import '../models/device_telemetry.dart';
import '../models/game_profile.dart';

class TelemetryService {
  static const MethodChannel _channel = MethodChannel('com.asoptimizer.mobile/engine');
  
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  Timer? _poller;
  final StreamController<DeviceTelemetry> _telemetryController = StreamController<DeviceTelemetry>.broadcast();
  Stream<DeviceTelemetry> get telemetryStream => _telemetryController.stream;

  DeviceTelemetry _latest = DeviceTelemetry.fallback();
  DeviceTelemetry get latestTelemetry => _latest;

  void startTelemetryPolling() {
    _poller?.cancel();
    _fetchOnce();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchOnce();
    });
  }

  void stopTelemetryPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<DeviceTelemetry> _fetchOnce() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getHardwareTelemetry');
      if (res != null) {
        _latest = DeviceTelemetry.fromMap(res);
        _telemetryController.add(_latest);
        return _latest;
      }
    } catch (_) {
      // Platform channel unavailable or running in emulator/web
    }
    _latest = DeviceTelemetry.fallback();
    _telemetryController.add(_latest);
    return _latest;
  }

  Future<List<GameProfile>> getInstalledGames() async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getInstalledGames');
      if (res != null) {
        return res.map((item) => GameProfile.fromMap(Map<String, dynamic>.from(item as Map))).toList();
      }
    } catch (_) {}

    // Fallback list of detected games
    return [
      GameProfile(
        packageName: 'com.tencent.ig',
        gameName: 'PUBG Mobile (Global)',
        tag: 'global',
        versionName: '3.6.0',
        isInstalled: true,
        fpsTarget: 90,
      ),
      GameProfile(
        packageName: 'com.pubg.imobile',
        gameName: 'BGMI (Battlegrounds Mobile India)',
        tag: 'bgmi',
        versionName: '3.6.0',
        isInstalled: true,
        fpsTarget: 90,
      ),
    ];
  }
}

