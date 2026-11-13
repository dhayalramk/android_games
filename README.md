# 🎮 Android Games Studio (Monorepo)

A collection of fast, engaging, hyper-casual and arcade Android games designed for rapid weekly development, physical device testing, and continuous Google Play publishing.

---

## 📱 Connected Hardware
- **Physical Device**: Connected via ADB (`b7a6bfe1`)
- **Target Platform**: Android (minSdk 21+, targetSdk 34+)
- **Primary Tech Engine**: Flutter + Flame Engine / Lightweight 2D Canvas (Fast iteration, high FPS, single-codebase, direct ADB hot-reload)

---

## 📁 Repository Structure

```text
android_games/
├── games/
│   ├── game_01_chroma_dash/        # Week 1 Game
│   ├── game_02_orbit_flip/         # Week 2 Game
│   └── ...
├── shared/                         # Reusable core modules
│   ├── audio/                      # Sound FX & BGM helpers
│   ├── haptics/                    # Vibration & sensory feedback
│   ├── storage/                    # Local high scores & settings
│   └── ui_components/              # Common pause, game over, score overlays
├── scripts/                        # Automation & deployment helpers
│   ├── build_apk.bat               # Fast APK build for connected device
│   ├── build_bundle.bat            # Release AAB generation for Play Store
│   └── install_to_device.bat       # Direct adb push to phone
└── docs/
    └── game_publishing_playbook.md # Weekly 7-day sprint plan
```

---

## 🚀 Weekly Game Sprint Plan (7-Day Cycle)

| Day | Focus | Output |
|---|---|---|
| **Day 1 (Mon)** | Concept & Core Mechanic | Playable graybox prototype |
| **Day 2 (Tue)** | Gameplay Physics & Controls | Smooth input feel, obstacle generation |
| **Day 3 (Wed)** | Visual Style & Juice | Particles, screen shake, neon/flat aesthetics |
| **Day 4 (Thu)** | Audio, Haptics & UI | Sound FX, haptic vibrations, game over screen |
| **Day 5 (Fri)** | Device Testing (`adb`) & Polish | 60+ FPS lock, bug fixes on real mobile |
| **Day 6 (Sat)** | Store Assets & Release Build | App icon, feature graphic, signed `.aab` |
| **Day 7 (Sun)** | Publish & Retrospective | Google Play Console upload & analytics review |

---

## 🎯 6-Week Game Lineup

1. **Game 1: Chroma Dash (Color Rush)**
   - *Mechanic*: One-tap color matching obstacle runner. Tap to switch colors to pass through matching laser barriers.
2. **Game 2: Orbit Flip (Gravity Switch)**
   - *Mechanic*: Endless runner where tapping inverts gravity between ceiling and floor dodging spikes and gaps.
3. **Game 3: Neon Slice (Precision Cutter)**
   - *Mechanic*: Swipe to cut floating geometric shapes into equal percentages before the timer expires.
4. **Game 4: Stack Pulse (Timing Rhythm)**
   - *Mechanic*: Tap at the exact micro-second to stack moving blocks into a towering sky scraper.
5. **Game 5: Vortex Weave (Reflex Survival)**
   - *Mechanic*: Smooth drag control dodging incoming bullet hell ripples in a cyber-neon arena.
6. **Game 6: Merge Rush 2048 (Arcade Drop)**
   - *Mechanic*: Drop and combine numbered bouncy spheres into higher values with bouncy physics.
