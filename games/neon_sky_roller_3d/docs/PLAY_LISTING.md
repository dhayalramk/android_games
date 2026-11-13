# Play Console — paste-ready listing

## App name
Neon Sky Roller 3D

## Short description (≤80 characters)
```text
Roll neon sky highways. Level up. Turbo. Unlock legendary chrome balls.
```

## Full description
```text
Neon Sky Roller 3D is a solo-leveling sky highway roller.

Drag left/right to steer. Slide up for turbo, down to brake. Grab gems, smash gates with Supernova, and climb endless named levels.

WHY YOU’LL COME BACK
• Daily Gift + login streak
• Daily Mission with gem rewards
• Solo Rank XP that never resets
• ★★★ mastery replays
• Ball Garage — Cyber, Chrome, Solar, Dark Matter, Aurora, Crimson

Clear the horizon. One more run.
```

## Graphics to upload
See `store/README.md` (icon 512, feature 1024×500, phone screenshots).

## Privacy policy URL
Host `docs/PRIVACY_POLICY.md` publicly, then paste that URL into Store settings → Privacy policy.

## Data safety
Fill using `docs/PLAY_DATA_SAFETY.md` (v1 offline: no data collected/shared).

## Release checklist (human)
1. Create Play app + upload key / Play App Signing
2. `./scripts/install_android_template.sh`
3. Set `NSR_RELEASE_KEYSTORE*` + `JAVA_HOME` (JDK 17) + `ANDROID_HOME`
4. `./scripts/build_release_aab.sh`
5. Internal testing track → install on 2 phones → `./scripts/qa_smoke.sh checklist`
6. Promote when device QA passes
