# Ordnance

Ordnance is a shooting-sports tool. It keeps a firearms directory, the firearms you own, ammunition and handload records, and a range log. The interface defaults to English. Simplified Chinese and Traditional Chinese remain available in Settings for this session.

Ordnance 是射击运动工具：枪械目录、自有枪械、弹药与手册装药记录、靶场记录。界面默认英文。

## What it does

- **Range.** Log a session against a firearm you own: date, place, distance, drill, target, rounds, ammunition lot, score, and notes. Saving the session deducts those rounds from inventory and adds them to that firearm's round count. Trip reminders use the system calendar and alarms.
- **Armory.** Firearms you own, with an optional nickname, serial, purchase notes, configuration, and round count. Maintenance records store the date and the round count at service. The range page shows items that are due from the round or day interval you set (defaults: 500 rounds, 90 days).
- **Ammunition.** Inventory by caliber, manufacturer, product, quantity, lot, and intended firearm, plus storage notes you type yourself. Low stock is flagged from the line you set. Handload batches record what you actually loaded.
- **Published loads.** A load row is shown only when it cites a handbook name and edition. Rows without that citation stay out of the load list. The app does not calculate a charge and does not walk through a loading procedure.
- **Directory.** Browse by type, action, caliber family, maker, use, and rimfire. Detail pages show shooting specs that are on file, compatible ammunition names, and links into the armory, maintenance, and ammunition. Empty specs are left empty.
- **Community.** Local posts for range logs, milestones, gear setups, maintenance, citations of published loads, and medal exchange. Sales, manufacturing instructions, and unpublished loads are refused in the composer. An account is not required for the range, armory, or ammunition tools.

## Data

Catalog rows are compiled from public specifications. New rows name the source in the data file. Load rows are transcribed from published handbooks and are hidden unless the handbook name includes an edition or year. Counts are checked by `test/data_integrity_test.dart` and `test/tool_flows_test.dart`.

## Layout

```text
lib/
  main.dart                 entry, frosted navigation
  app_version.dart          version shown in the app (kept in step with pubspec.yaml)
  models.dart               catalog models
  data.dart                 firearms, accessories, calibers, cited loads
  directory_taxonomy.dart   type, action, use, and rimfire facets
  tool_logic.dart           cited-load filter, session ammo use, maintenance due
  range_session.dart        on-device range sessions
  gun_cabinet_data.dart     armory
  community_store.dart      on-device community, favorites, scores
  i18n.dart                 interface copy
  screens/                  pages
assets/images/              artwork
shaders/                    liquid-glass shader
test/                       data, copy, and tool-flow tests
.github/workflows/          Android CI and the signed release workflow
```

## Build

The repository does not commit `android/`. The build scripts generate it, then apply `lib/`, `assets/`, and `app-icon/res/`. `patch-android-config.py` sets the application id and points `android:label` at `@string/app_name` (`Ordnance`). Without that step the scaffold label `firearms_catalog` is what the installer and the launcher show. Release and local scripts copy the built APK to `Ordnance-vX.Y.Z.apk` (debug builds use `Ordnance-vX.Y.Z-debug.apk`).

```bash
bash build-apk.sh
```

`patch-android-config.py` sets `applicationId` and `namespace` to `com.toryphoto77.ordnance`. When `android/key.properties` exists, release builds use that keystore. The iOS bundle id is still `com.wangtao969.ordnance`.

## Signing and releases

v3.0.0 moved to a new signing key and the package name `com.toryphoto77.ordnance`. Older installs cannot be overwritten. Settings includes **Import from the previous version**, which accepts a v2 export and merges favorites, range scores, and experience, and also merges armory, ammunition, and range sessions when those fields are present.

Key material stays out of the repository. CI signing uses repository secrets:

| Name | Contents |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | base64 of the release keystore |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | alias (`ordnance` for the current keystore) |

Optional variable `ANDROID_CERT_SHA256` checks the certificate fingerprint during the release build.

Current version is 3.0.1. `pubspec.yaml` and `lib/app_version.dart` stay in lockstep. A `v*` tag runs `.github/workflows/android-release.yml`.

## Tests

```bash
flutter analyze
flutter test
```

## Limits

Community, the armory, ammunition, and range sessions are on-device. The server contract in `sync-contract.md` is unchanged and still unused. iOS still uses the previous bundle id.
