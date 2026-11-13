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
│   ├── neon_sky_roller_3d/         # Flagship: solo-leveling sky highway roller (Godot 4)
│   ├── stack_smash_3d/             # 3D tower smash (Godot 4)
│   └── ...                         # One folder = one game
├── scripts/                        # Godot run / ADB install helpers
└── docs/
    ├── neon_sky_roller_3d_plan.md
    ├── cyber_drift_3d_gdd.md
    └── weekly_game_studio_plan.md
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

## 🎯 Live Games

1. **Neon Sky Roller 3D** (`games/neon_sky_roller_3d`) — Flagship solo-leveling roller: drag-steer a chrome sphere across neon sky highways, collect gems, hit boosts, charge Supernova, clear level after level.
2. **Stack Smash 3D** (`games/stack_smash_3d`) — Smash through tower rings with timing + fever mode.

## 🗺️ Concept Backlog

- Cyber Drift 3D, Glass Shatter 3D, Chroma Dash, Orbit Flip, Neon Slice, Stack Pulse, Vortex Weave, Merge Rush 2048
