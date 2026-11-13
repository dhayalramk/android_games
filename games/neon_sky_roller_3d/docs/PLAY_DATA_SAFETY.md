# Play Console — Data safety form (stub)

Fill Play Console → App content → Data safety using these answers for **v1.0.0 offline build**.

## Does your app collect or share any of the required user data types?

**No** — this version does not collect or share user data as defined by Play Data safety.

(Progress is stored only in on-device app storage and is not transmitted off device.)

## Data collected / shared

| Category | Collected? | Shared? | Notes |
|---|---|---|---|
| Location | No | No | |
| Personal info | No | No | |
| Financial info | No | No | |
| Health & fitness | No | No | |
| Messages | No | No | |
| Photos and videos | No | No | |
| Audio files | No | No | |
| Files and docs | No | No | |
| Calendar | No | No | |
| Contacts | No | No | |
| App activity | No | No | On-device saves only |
| Web browsing | No | No | |
| App info and performance | No | No | No crash SDK |
| Device or other IDs | No | No | No ads / no analytics ID |

## Security practices

- Data is encrypted in transit: **N/A** (no network transfer)
- Users can request deletion: **Yes** — uninstall the app / clear app storage
- Committed to Play Families policy: follow your target audience setting
- Independent security review: No

## Privacy policy URL

Host `docs/PRIVACY_POLICY.md` (or rendered GitHub Pages / raw link) and paste the public URL into:

Play Console → Store presence → Store settings → Privacy policy

Example raw URL (update if the default branch or path changes):

`https://github.com/dhayalramk/android_games/blob/main/games/neon_sky_roller_3d/docs/PRIVACY_POLICY.md`

## When you add ads / analytics later

1. Update `PRIVACY_POLICY.md`
2. Re-answer this form (collect = Yes for relevant types)
3. Declare SDKs (AdMob, Firebase, etc.)
4. Add any new permissions to `export_presets.cfg`
5. Bump `version/code`
