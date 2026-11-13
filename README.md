# Android Games Studio (Monorepo)

Fast hyper-casual / arcade Android games. **One folder = one game.**

---

## 🎮 Active Games

| Folder | Game | Engine | Pitch |
|---|---|---|---|
| `games/neon_sky_roller_3d/` | **Neon Sky Roller 3D** | Godot 4 (Vulkan 3D) | Flagship solo-leveling roller: drag-steer a chrome sphere across neon sky highways, collect gems, hit boosts, charge Supernova, clear levels. |
| `games/stack_smash_3d/` | **Stack Smash 3D** | Godot 4 (Mobile 3D) | Hyper-addictive 3D tower smash: hold to drill down, shatter rotating neon slices, avoid black barriers, trigger Fireball Supernova! |
| `games/neon_tac_blitz/` | **Neon Tac Blitz** | Godot 4 | Tic-tac-toe gone arcade — blitz timer, bomb/warp/freeze cells, streak Ult vs AI. |

---

## 📱 Quick Run & Install Helpers

```bash
# Stack Smash 3D
./scripts/run_on_pc.bat
./scripts/install_to_phone.bat

# Neon Sky Roller 3D
./scripts/run_neon_sky_roller.bat

# Neon Tac Blitz
./scripts/run_neon_tac_blitz.bat
```

---

## 📁 Repository Structure

```text
android_games/
├── games/
│   ├── neon_sky_roller_3d/         # Flagship: solo-leveling sky highway roller (Godot 4)
│   ├── stack_smash_3d/             # 3D tower smash (Godot 4)
│   ├── neon_tac_blitz/             # Chaos arcade tic-tac-toe (Godot 4)
│   └── ...                         # One folder = one game
├── scripts/                        # Godot run / ADB install helpers
└── docs/                           # Game Design Documents and specifications
```
