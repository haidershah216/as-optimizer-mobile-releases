import 'package:flutter/material.dart';
import '../models/game_profile.dart';
import '../services/telemetry_service.dart';
import '../services/optimizer_service.dart';
import '../theme/app_theme.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final TelemetryService _telemetryService = TelemetryService();
  final OptimizerService _optimizerService = OptimizerService();
  List<GameProfile> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _telemetryService.getInstalledGames();
    if (mounted) {
      setState(() {
        _games = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Profiles & Tuning"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Configure graphics pacing, 90/120 FPS frame caps, and AOT compilation profiles per installed game.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ..._games.map((game) => _buildGameCard(game)),
              ],
            ),
    );
  }

  Widget _buildGameCard(GameProfile game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.gameName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      game.packageName,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmeraldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${game.fpsTarget} FPS",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentEmerald,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          
          // FPS Selector
          const Text("TARGET FRAME RATE (FPS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [60, 90, 120].map((fps) {
              final active = game.fpsTarget == fps;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() => game.fpsTarget = fps);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryBlue : AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? AppTheme.primaryBlue : AppTheme.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$fps FPS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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

          const SizedBox(height: 16),

          // Graphics Profile
          const Text("GRAPHICS RENDERING PACING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: game.graphicStyle,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Smooth (Max FPS)', child: Text('Smooth (Zero Input Lag & Max FPS)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Balanced', child: Text('Balanced (Standard 60-90 FPS)', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'HD Ultra', child: Text('HD Ultra (Max Visual Fidelity)', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => game.graphicStyle = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text("AOT Turbo"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("AOT Dexopt Speed mode compiling for ${game.gameName}...")),
                    );
                    await _optimizerService.executeTurbo(game.packageName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Optimization applied for ${game.gameName}!")),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text("Launch Game"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _optimizerService.launchGame(game.packageName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

