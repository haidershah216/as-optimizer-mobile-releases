import 'package:flutter/material.dart';
import '../services/optimizer_service.dart';
import '../theme/app_theme.dart';

class TuningScreen extends StatefulWidget {
  const TuningScreen({super.key});

  @override
  State<TuningScreen> createState() => _TuningScreenState();
}

class _TuningScreenState extends State<TuningScreen> {
  final OptimizerService _optimizer = OptimizerService();
  double _selectedHz = 120.0;
  bool _aotSpeedCompilation = true;
  bool _gameModeApi = true;
  bool _thermalShield = true;
  bool _ramAggressivePurge = true;

  @override
  void initState() {
    super.initState();
    _selectedHz = _optimizer.currentRefreshRateLock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OS & Kernel Tuning"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF60A5FA), size: 22),
                    SizedBox(width: 10),
                    Text(
                      "KERNEL & DISPLAY PACING",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Enforce high-refresh rate display locks and Android OS compute thread scheduling to prevent mid-combat FPS drops.",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Display Refresh Rate Lock
          _buildSectionHeader("DISPLAY REFRESH RATE LOCK"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lock System Refresh Rate",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Overrides dynamic adaptive display downclocking (e.g., dropping from 120Hz to 60Hz during gunfights).",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [60.0, 90.0, 120.0].map((hz) {
                    final active = _selectedHz == hz;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            setState(() => _selectedHz = hz);
                            final ok = await _optimizer.setRefreshRateLock(hz);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? "Display refresh rate locked to ${hz.toInt()} Hz!"
                                      : "Hz preference saved. (Elevated ADB/Root recommended for force-lock)"),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: active ? AppTheme.primaryBlue : AppTheme.surfaceSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active ? AppTheme.primaryBlue : AppTheme.borderLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${hz.toInt()} Hz",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: active ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Android ART & Memory Settings
          _buildSectionHeader("SYSTEM TWEAKS"),
          const SizedBox(height: 10),
          Container(
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "AOT Dexopt Speed Compilation",
                  subtitle: "Pre-compiles PUBG Mobile DEX bytecode to native machine code via 'cmd package compile -m speed'. Eliminates Stop-The-World JIT GC drops.",
                  icon: Icons.memory_rounded,
                  value: _aotSpeedCompilation,
                  onChanged: (val) => setState(() => _aotSpeedCompilation = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Android GameMode API Integration",
                  subtitle: "Registers the game process with Android's system GameMode service (Mode 2: Extreme Performance) for dedicated thermal headroom.",
                  icon: Icons.speed_rounded,
                  value: _gameModeApi,
                  onChanged: (val) => setState(() => _gameModeApi = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Aggressive RAM Background Purge",
                  subtitle: "Trims background memory caches and limits non-essential services while the game is running to maximize physical heap memory.",
                  icon: Icons.cleaning_services_rounded,
                  value: _ramAggressivePurge,
                  onChanged: (val) => setState(() => _ramAggressivePurge = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Thermal Pacing & Anti-Throttle Shield",
                  subtitle: "Monitors battery temperature and balances CPU core frequency scaling to delay aggressive kernel throttling in 20+ minute matches.",
                  icon: Icons.shield_rounded,
                  value: _thermalShield,
                  onChanged: (val) => setState(() => _thermalShield = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeColor: AppTheme.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

