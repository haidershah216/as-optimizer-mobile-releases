class GameProfile {
  final String packageName;
  final String gameName;
  final String tag;
  final String versionName;
  final bool isInstalled;
  int fpsTarget; // 60, 90, 120
  String graphicStyle; // Smooth, Balanced, HD, Ultra HD
  bool antiAliasing;
  bool shadows;
  bool aotOptimized;

  GameProfile({
    required this.packageName,
    required this.gameName,
    required this.tag,
    required this.versionName,
    required this.isInstalled,
    this.fpsTarget = 90,
    this.graphicStyle = 'Smooth (Max FPS)',
    this.antiAliasing = false,
    this.shadows = false,
    this.aotOptimized = false,
  });

  factory GameProfile.fromMap(Map<dynamic, dynamic> map) {
    return GameProfile(
      packageName: map['packageName']?.toString() ?? '',
      gameName: map['gameName']?.toString() ?? 'Mobile Game',
      tag: map['tag']?.toString() ?? 'game',
      versionName: map['versionName']?.toString() ?? '1.0',
      isInstalled: map['isInstalled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'gameName': gameName,
    'tag': tag,
    'versionName': versionName,
    'isInstalled': isInstalled,
    'fpsTarget': fpsTarget,
    'graphicStyle': graphicStyle,
    'antiAliasing': antiAliasing,
    'shadows': shadows,
    'aotOptimized': aotOptimized,
  };
}

