import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ReleaseInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final int fileSizeBytes;
  final String sha256Checksum;
  final String? publishedAtUtc;
  final String platform;

  ReleaseInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    this.publishedAtUtc,
    this.platform = 'android',
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      version: json['version']?.toString() ?? '1.0.0',
      releaseNotes: json['releaseNotes']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      sha256Checksum: json['sha256Checksum']?.toString() ?? '',
      publishedAtUtc: json['publishedAtUtc']?.toString(),
      platform: json['platform']?.toString() ?? 'android',
    );
  }
}

class MobileApiService {
  static const String baseUrl = 'https://asoptimizer.com';

  static Future<ReleaseInfo?> checkLatestRelease() async {
    try {
      final uri = Uri.parse('$baseUrl/api/releases/latest?platform=android');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return ReleaseInfo.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> isUpdateAvailable(String currentVersion) async {
    final latest = await checkLatestRelease();
    if (latest == null) return false;
    return _compareVersions(latest.version, currentVersion) > 0;
  }

  static int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final n1 = i < p1.length ? p1[i] : 0;
      final n2 = i < p2.length ? p2[i] : 0;
      if (n1 > n2) return 1;
      if (n1 < n2) return -1;
    }
    return 0;
  }
}

