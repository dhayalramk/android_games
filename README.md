# Android Games Studio (Monorepo)

Fast hyper-casual / arcade Android games. **One folder = one game.**

## Games

| Folder | Game | Pitch |
|---|---|---|
| `games/neon_tac_blitz/` | **Neon Tac Blitz** | Tic-tac-toe gone arcade — blitz timer, bomb/warp/freeze cells, streak Ult vs AI |
| `games/stack_smash_3d/` | Stack Smash 3D | Smash through tower rings (Godot 4) |

Neon Sky Roller 3D lives on branch `cursor/neon-sky-roller-3d-910a` until merged.

## Run Neon Tac Blitz

```bash
# Godot 4.3+
godot --path games/neon_tac_blitz
# or
./scripts/run_neon_tac_blitz.sh
```

## Structure

```text
android_games/
├── games/                 # One folder per game
├── scripts/               # Run / install helpers
└── docs/
```
