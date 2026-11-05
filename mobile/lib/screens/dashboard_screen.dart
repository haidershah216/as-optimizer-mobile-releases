import 'package:flutter/material.dart';
import '../models/device_telemetry.dart';
import '../models/game_profile.dart';
import '../services/telemetry_service.dart';
import '../services/optimizer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/telemetry_card.dart';
import '../widgets/turbo_button.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const DashboardScreen({super.key, required this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TelemetryService _telemetryService = TelemetryService();
  final OptimizerService _optimizerService = OptimizerService();
  DeviceTelemetry _telemetry = DeviceTelemetry.fallback();
  List<GameProfile> _games = [];
  bool _isOptimizing = false;
  String? _lastTurboReport;

  @override
  void initState() {
    super.initState();
    _telemetry = _telemetryService.latestTelemetry;
    _telemetryService.telemetryStream.listen((data) {
      if (mounted) setState(() => _telemetry = data);
    });
    _loadGames();
  }

  Future<void> _loadGames() async {
    final list = await _telemetryService.getInstalledGames();
    if (mounted) setState(() => _games = list);
  }

  Future<void> _triggerTurbo() async {
    setState(() => _isOptimizing = true);
    final targetPkg = _games.isNotEmpty ? _games.first.packageName : "com.tencent.ig";
    final result = await _optimizerService.executeTurbo(targetPkg);
    
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() {
        _isOptimizing = false;
        _lastTurboReport = result.steps.join("\n• ");
      });
      _showTurboSuccessDialog(result);
    }
  }

  void _showTurboSuccessDialog(TurboResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 28),
            SizedBox(width: 10),
            Text("Engine Turbo Active", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System & GameLoop Android container optimized for ${result.targetPackage}.",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "• ${_lastTurboReport ?? 'Optimization complete.'}",
                style: const TextStyle(fontSize: 12, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Ready to Play"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AS OPTIMIZER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                Text("Mobile Gaming Engine", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _telemetry.isRooted ? AppTheme.accentEmeraldLight : AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _telemetry.isRooted ? AppTheme.accentEmerald.withOpacity(0.3) : AppTheme.primaryBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _telemetry.isRooted ? AppTheme.accentEmerald : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _telemetry.isRooted ? "Kernel Root" : "Standard Android",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _telemetry.isRooted ? AppTheme.accentEmerald : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadGames();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Device Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_telemetry.brand} ${_telemetry.model}".toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Android ${_telemetry.androidVersion}",
                          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _telemetry.socName,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeroStat("CORES", "${_telemetry.cpuCores} Physical"),
                      const SizedBox(width: 24),
                      _buildHeroStat("CLOCK", "${_telemetry.cpuCurFreqMhz > 0 ? _telemetry.cpuCurFreqMhz : 2840} MHz"),
                      const SizedBox(width: 24),
                      _buildHeroStat("DISPLAY", "${_telemetry.refreshRateHz.toInt()} Hz Lock"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 1-Click Game Turbo Button
            TurboButton(
              isOptimizing: _isOptimizing,
              onTap: _triggerTurbo,
            ),

            const SizedBox(height: 24),

            // Real Hardware Telemetry Grid (2x2)
            const Text(
              "REAL-TIME HARDWARE TELEMETRY",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TelemetryCard(
                  title: "RAM Utilization",
                  value: "${(_telemetry.usedRamMb / 1024).toStringAsFixed(1)} / ${(_telemetry.totalRamMb / 1024).toStringAsFixed(1)} GB",
                  subtitle: "${_telemetry.availRamMb} MB Available Free",
                  icon: Icons.memory_rounded,
                  iconColor: AppTheme.primaryBlue,
                  progress: _telemetry.ramUsageRatio,
                  badgeText: "${_telemetry.ramUsagePct}%",
                ),
                TelemetryCard(
                  title: "Thermal Status",
                  value: "${_telemetry.batteryTempC.toStringAsFixed(1)}°C",
                  subtitle: _telemetry.thermalStatusText,
                  icon: Icons.thermostat_rounded,
                  iconColor: _telemetry.isThermalHot ? AppTheme.dangerRose : AppTheme.accentEmerald,
                  badgeColor: _telemetry.isThermalHot ? AppTheme.dangerRose : AppTheme.accentEmerald,
                  badgeText: _telemetry.isThermalHot ? "HOT" : "COOL",
                ),
                TelemetryCard(
                  title: "Display Refresh",
                  value: "${_telemetry.refreshRateHz.toInt()} FPS",
                  subtitle: _telemetry.refreshRateHz >= 90.0 ? "Smooth 90/120Hz" : "Standard 60Hz",
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF6366F1),
                  badgeColor: const Color(0xFF6366F1),
                  badgeText: "${_telemetry.refreshRateHz.toInt()} HZ",
                ),
                TelemetryCard(
                  title: "Battery Health",
                  value: "${_telemetry.batteryPct}%",
                  subtitle: "Power Pacing Stable",
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: AppTheme.accentEmerald,
                  progress: _telemetry.batteryPct / 100.0,
                  badgeText: "OK",
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Installed Games Quick Launch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "INSTALLED PUBGM GAMES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onTabChange(1),
                  child: const Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_games.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(),
                child: const Center(
                  child: Text(
                    "No PUBG versions detected yet.\nInstall PUBG Mobile Global, BGMI, or KR to optimize.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._games.map((g) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.gameName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "v${g.versionName} · Target ${g.fpsTarget} FPS",
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _optimizerService.launchGame(g.packageName),
                      child: const Text("Launch"),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

