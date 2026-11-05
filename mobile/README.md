# AS Optimizer Mobile — Ultimate Android & PUBG Mobile Gaming Engine

Developed by **Sajlog Agency** (Sajjad Ali & Arslan Azmat) as the mobile companion to **AS Optimizer** (https://asoptimizer.com).

## 🚀 Key Features

1. **1-Click Game Turbo Engine**:
   - Background memory trim and aggressive physical RAM purge.
   - AOT Dexopt Speed mode compilation (`cmd package compile -m speed -f <pkg>`) to eliminate runtime JIT Stop-The-World garbage collection stutter.
   - Android GameMode API Extreme Performance mode integration (Mode 2).
2. **Display Refresh Rate Lock**:
   - Locks display pacing to 60Hz, 90Hz, or 120Hz to prevent dynamic downclocking in high-intensity firefights.
3. **Real-time Hardware Telemetry**:
   - 100% Dynamic, querying real Linux kernel `/proc/meminfo`, `/proc/cpuinfo`, and `BatteryManager` in real-time.
   - SoC detection, active core clock (MHz), available RAM, battery temperature in °C, and display refresh rate.
4. **Auto-Detection for All PUBG Mobile & BGMI Variants**:
   - PUBG Mobile Global (`com.tencent.ig`)
   - BGMI (`com.pubg.imobile`)
   - PUBG KR (`com.pubg.krmobile`)
   - PUBG VN (`com.vng.pubgmobile`)
   - PUBG TW (`com.rekoo.pubgm`)
   - Free Fire & COD Mobile
5. **Universal Android Support**:
   - Supports Android 7.0 (API 24) to Android 15+ (API 35).
   - Works on standard non-rooted devices (standard optimizations), with elevated power unlocked via Shizuku or Root.
6. **Automatic Updates**:
   - Directly checks and downloads releases from `https://asoptimizer.com/api/releases/latest?platform=android`.

## 🛠️ Build & Run

```bash
# Get dependencies
flutter pub get

# Build Release APK
flutter build apk --release --split-per-abi

# Universal APK
flutter build apk --release
```

