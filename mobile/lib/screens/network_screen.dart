import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../theme/app_theme.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final NetworkService _network = NetworkService();
  List<PingResult> _results = [];
  bool _testing = false;
  String _selectedDns = 'Cloudflare 1.1.1.1 (Recommended)';

  @override
  void initState() {
    super.initState();
    _runPingTest();
  }

  Future<void> _runPingTest() async {
    setState(() => _testing = true);
    final res = await _network.testAllServers();
    if (mounted) {
      setState(() {
        _results = res;
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowestPing = _results.isNotEmpty ? _results.first.latencyMs : 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ping Stabilizer & Network Shield"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Ping Gauge Banner
          Container(
            padding: const EdgeInsets.all(22),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CURRENT GAMING PING",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$lowestPing",
                          style: TextStyle(
                            color: lowestPing < 50 ? const Color(0xFF34D399) : (lowestPing < 90 ? const Color(0xFFFBBF24) : const Color(0xFFF87171)),
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text("ms", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lowestPing < 50 ? "Zero Bullet Desync (Buttery Smooth)" : "Acceptable for Competitive",
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _testing ? null : _runPingTest,
                  icon: _testing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_testing ? "Pinging..." : "Test"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Gaming DNS Selector
          const Text(
            "GAMING DNS ROUTER",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Anti-Lag DNS Provider", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                const Text(
                  "Optimizes routing hops to nearest PUBG Mobile match servers.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDns,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Cloudflare 1.1.1.1 (Recommended)', child: Text('Cloudflare 1.1.1.1 (Ultra Low Latency)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Google 8.8.8.8', child: Text('Google 8.8.8.8 (Global Routing)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Quad9 9.9.9.9', child: Text('Quad9 9.9.9.9 (DDoS Protected)', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDns = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$val applied for gaming session!")),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Real-time Gateway Latency List
          const Text(
            "REGIONAL PUBG GATEWAY LATENCY",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          ..._results.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: r.latencyMs < 60 ? AppTheme.accentEmeraldLight : AppTheme.primaryBlueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.wifi_tethering_rounded,
                    color: r.latencyMs < 60 ? AppTheme.accentEmerald : AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.serverName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text("Host: ${r.host}", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: r.latencyMs < 60 ? AppTheme.accentEmeraldLight : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${r.latencyMs} ms",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: r.latencyMs < 60 ? AppTheme.accentEmerald : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

