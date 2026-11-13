# Neon Sky Roller 3D — Production Readiness Checklist

Goal: shippable Google Play release that customers enjoy.

## Packaging (Play)

| # | Item | Status |
|---|---|---|
| 1 | Stable hub / input / gameplay entry | DONE |
| 2 | Release Android export (.aab) + versioning + build scripts | DONE |
| 3 | Store assets (adaptive icon, feature graphic, screenshots) | DONE |
| 4 | Privacy policy + Play data-safety stubs | DONE |
| 5 | Device QA / install test scripts | DONE |
| 6 | Production audio (music + real SFX) | DONE |
| 7 | Visual quality pass | DONE |

## Customer delight

| # | Item | Status |
|---|---|---|
| D1 | Level 1–3 fun/fair first-session curve + coach | DONE |
| D2 | Juice: float pops, clear flash, snappier steer | DONE |
| D3 | First-clear gem gift + clearer clear banner | DONE |
| D4 | Hub tip for new players | DONE |
| D5 | Paste-ready Play listing (`docs/PLAY_LISTING.md`) | DONE |

## Definition of done

- [x] Play / Daily / Garage / Level chips work on desktop (touch-emulated)
- [x] `export_presets.cfg` builds a signed release `.aab`
- [x] Store listing folder has icon + feature graphic + ≥2 phone screenshots
- [x] Privacy policy + data-safety stubs in-repo
- [x] QA scripts present (`qa_smoke.sh`)
- [x] Music bed + sampled SFX
- [x] Visual pass (skyline, arches, bloom, camera bank, speed lines)
- [x] First session teaches controls and delivers a quick win
- [ ] **Human gate:** Internal-test AAB on ≥1 real phone (upload key + Console)

## Honest ship status

**Ready for Internal / closed testing** after you sign with your Play upload keystore and run device QA.

**Public Production** after the human gate above (real devices + Console listing live).
