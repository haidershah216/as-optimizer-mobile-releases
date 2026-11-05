import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _appVersion = "1.0.0";
  bool _checkingUpdate = false;
  String? _updateStatus;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateStatus = null;
    });

    final release = await MobileApiService.checkLatestRelease();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _checkingUpdate = false;
        if (release != null) {
          final isNewer = MobileApiService.isUpdateAvailable(_appVersion);
          _showReleaseDialog(release);
        } else {
          _updateStatus = "Your AS Optimizer Mobile is up to date (v$_appVersion).";
        }
      });
    }
  }

  void _showReleaseDialog(ReleaseInfo release) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppTheme.primaryBlue, size: 26),
            const SizedBox(width: 10),
            Text("Release v${release.version}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "A new mobile update is available from asoptimizer.com (${(release.fileSizeBytes / 1048576).toStringAsFixed(1)} MB).",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                release.releaseNotes.isEmpty ? "Performance and bug fixes." : release.releaseNotes,
                style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse(release.downloadUrl.isNotEmpty ? release.downloadUrl : "https://asoptimizer.com/download");
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Download APK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Membership & Account"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                      child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gaming Member",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Connected via Google Account",
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmeraldLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ACTIVE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("App Version", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text("v$_appVersion", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ecosystem", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const Text("asoptimizer.com", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Updates Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SOFTWARE UPDATES",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  "AS Optimizer Mobile updates automatically from GitHub Releases and asoptimizer.com distribution.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _checkingUpdate
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_checkingUpdate ? "Checking for updates..." : "Check for Updates"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _checkingUpdate ? null : _checkForUpdate,
                  ),
                ),
                if (_updateStatus != null) ...[
                  const SizedBox(height: 10),
                  Text(_updateStatus!, style: const TextStyle(fontSize: 12, color: AppTheme.accentEmerald, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Founders / Agency Badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF60A5FA), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "SAJLOG AGENCY ECOSYSTEM",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Engineered and maintained by Sajjad Ali (Sajlog) and Arslan Azmat (Arslany). Built for pro mobile competitive players.",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse("https://asoptimizer.com");
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: const Row(
                    children: [
                      Text(
                        "Visit Official Website",
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_outward_rounded, color: Color(0xFF60A5FA), size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

