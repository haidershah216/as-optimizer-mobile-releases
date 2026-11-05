class DeviceTelemetry {
  final String brand;
  final String model;
  final String device;
  final String hardware;
  final String board;
  final String androidVersion;
  final int sdkInt;
  final int cpuCores;
  final int cpuCurFreqMhz;
  final String socName;
  final int totalRamMb;
  final int availRamMb;
  final bool lowMemory;
  final double batteryTempC;
  final int batteryPct;
  final double refreshRateHz;
  final bool isRooted;

  DeviceTelemetry({
    required this.brand,
    required this.model,
    required this.device,
    required this.hardware,
    required this.board,
    required this.androidVersion,
    required this.sdkInt,
    required this.cpuCores,
    required this.cpuCurFreqMhz,
    required this.socName,
    required this.totalRamMb,
    required this.availRamMb,
    required this.lowMemory,
    required this.batteryTempC,
    required this.batteryPct,
    required this.refreshRateHz,
    required this.isRooted,
  });

  factory DeviceTelemetry.fromMap(Map<dynamic, dynamic> map) {
    return DeviceTelemetry(
      brand: map['brand']?.toString() ?? 'Android',
      model: map['model']?.toString() ?? 'Device',
      device: map['device']?.toString() ?? '',
      hardware: map['hardware']?.toString() ?? '',
      board: map['board']?.toString() ?? '',
      androidVersion: map['androidVersion']?.toString() ?? '14',
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 34,
      cpuCores: (map['cpuCores'] as num?)?.toInt() ?? 8,
      cpuCurFreqMhz: (map['cpuCurFreqMhz'] as num?)?.toInt() ?? 2400,
      socName: map['socName']?.toString() ?? 'Qualcomm Snapdragon / MediaTek',
      totalRamMb: (map['totalRamMb'] as num?)?.toInt() ?? 8192,
      availRamMb: (map['availRamMb'] as num?)?.toInt() ?? 4096,
      lowMemory: map['lowMemory'] as bool? ?? false,
      batteryTempC: (map['batteryTempC'] as num?)?.toDouble() ?? 32.0,
      batteryPct: (map['batteryPct'] as num?)?.toInt() ?? 85,
      refreshRateHz: (map['refreshRateHz'] as num?)?.toDouble() ?? 60.0,
      isRooted: map['isRooted'] as bool? ?? false,
    );
  }

  factory DeviceTelemetry.fallback() {
    return DeviceTelemetry(
      brand: 'Smartphone',
      model: 'Octa-Core Gaming Device',
      device: 'generic',
      hardware: 'arm64-v8a',
      board: 'universal',
      androidVersion: '14.0',
      sdkInt: 34,
      cpuCores: 8,
      cpuCurFreqMhz: 2840,
      socName: 'Snapdragon 8 Gen Series / Dimensity',
      totalRamMb: 8192,
      availRamMb: 4850,
      lowMemory: false,
      batteryTempC: 33.5,
      batteryPct: 90,
      refreshRateHz: 120.0,
      isRooted: false,
    );
  }

  int get usedRamMb => totalRamMb - availRamMb;
  double get ramUsageRatio => totalRamMb > 0 ? (usedRamMb / totalRamMb) : 0.0;
  int get ramUsagePct => (ramUsageRatio * 100).toInt();

  bool get isThermalHot => batteryTempC >= 42.0;
  bool get isThermalSafe => batteryTempC < 38.0;

  String get thermalStatusText {
    if (batteryTempC < 37.0) return 'Optimal Cool';
    if (batteryTempC < 42.0) return 'Normal Warm';
    return 'Thermal Throttle Risk';
  }
}

