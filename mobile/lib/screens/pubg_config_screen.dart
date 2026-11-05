import 'package:flutter/material.dart';
import '../models/game_profile.dart';
import '../services/telemetry_service.dart';
import '../services/optimizer_service.dart';
import '../theme/app_theme.dart';

class PubgConfigScreen extends StatefulWidget {
  const PubgConfigScreen({super.key});

  @override
  State<PubgConfigScreen> createState() => _PubgConfigScreenState();
}

class _PubgConfigScreenState extends State<PubgConfigScreen> {
  final TelemetryService _telemetry = TelemetryService();
  final OptimizerService _optimizer = OptimizerService();
  
  List<GameProfile> _games = [];
  GameProfile? _selectedGame;
  int _targetFps = 90;
  bool _disableShadows = true;
  bool _ipadView = false;
  bool _ultraAudio = true;
  bool _antiAliasing = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final list = await _telemetry.getInstalledGames();
    if (mounted) {
      setState(() {
        _games = list;
        if (list.isNotEmpty) _selectedGame = list.first;
      });
    }
  }

  Future<void> _applyAndLaunch() async {
    if (_selectedGame == null) return;
    setState(() => _applying = true);

    await _optimizer.applyPubgConfig(
      packageName: _selectedGame!.packageName,
      fpsTarget: _targetFps,
      shadows: !_disableShadows,
    );

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$_targetFps FPS & graphics profile applied to ${_selectedGame!.gameName}!"),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
      await _optimizer.launchGame(_selectedGame!.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PUBG Graphics & FPS Unlocker"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Select Target Game
          const Text(
            "SELECT GAME EDITION",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppTheme.cardDecoration(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GameProfile>(
                value: _selectedGame,
                isExpanded: true,
                hint: const Text("Choose installed PUBG / BGMI"),
                items: _games.map((g) {
                  return DropdownMenuItem<GameProfile>(
                    value: g,
                    child: Text("${g.gameName} (${g.packageName})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGame = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // FPS Unlocker (60, 90, 120)
          const Text(
            "UNLOCK REFRESH RATE (FPS)",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Row(
            children: [60, 90, 120].map((fps) {
              final active = _targetFps == fps;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _targetFps = fps),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryBlue : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? AppTheme.primaryBlue : AppTheme.borderLight,
                          width: active ? 2 : 1,
                        ),
                        boxShadow: active ? [
                          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ] : const [],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "$fps",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: active ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            fps == 120 ? "EXTREME" : (fps == 90 ? "PRO ULTRA" : "STANDARD"),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: active ? const Color(0xFFBFDBFE) : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Toggles for Competitive PUBG Features
          const Text(
            "COMPETITIVE COMBAT OPTIMIZATIONS",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Disable Dynamic Shadows (+20 FPS)",
                  subtitle: "Removes player and tree shadows to prevent sudden frame drops during hot-drop close-quarters gunfights.",
                  value: _disableShadows,
                  onChanged: (val) => setState(() => _disableShadows = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Wide Angle / iPad View (90° FOV)",
                  subtitle: "Extends vertical and horizontal camera perspective for maximum situational awareness.",
                  value: _ipadView,
                  onChanged: (val) => setState(() => _ipadView = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Ultra Sound Audio Pack Unlock",
                  subtitle: "Unlocks high-fidelity 3D spatial footsteps and vehicle engine positioning.",
                  value: _ultraAudio,
                  onChanged: (val) => setState(() => _ultraAudio = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: "Disable MSAA Anti-Aliasing (Input Lag Reduction)",
                  subtitle: "Bypasses multisample anti-aliasing to provide direct 1:1 touch response for gyroscope and hipfire.",
                  value: !_antiAliasing,
                  onChanged: (val) => setState(() => _antiAliasing = !val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Apply and Launch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applying ? null : _applyAndLaunch,
              icon: _applying
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.rocket_launch_rounded, size: 20),
              label: Text(_applying ? "APPLYING CONFIG..." : "APPLY CONFIG & LAUNCH"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

