# Report 007 — Android setup plan (2026-10-26)

> **Historical snapshot (2026-10-26).** This plan records the Android toolchain state at that time (SDK missing, nothing installed). Later setup may have changed it; the findings below are preserved unchanged.

Prompt: `../prompts/007-android-setup-plan.md`. Inspection and planning only. Nothing was installed or downloaded, no project file or Godot setting was changed, nothing committed or pushed. Network use was limited to reading web pages and a `winget search/show` metadata query (no packages fetched). Supersedes the planning part of report 006.

## 1. Current state

### Already present
| Item | State |
|---|---|
| Godot | 4.7.2.stable at `E:\Godot_v4.7.2-stable_win64.exe\` (the "exe" is a folder; console build `Godot_v4.7.2-stable_win64_console.exe`) |
| Android Studio | Installed, `C:\Program Files\Android\Android Studio`, build AI-262.9437.185 (2026.2.1). Has a bundled JetBrains runtime, **JDK 25.0.3**, with `keytool`. **No SDK configured**, no AVD (`~/.android/avd` empty). |
| winget | v1.29.380 available |
| Disk | E: 190 GB free (target), C: 64 GB free |
| Git | branch `main` at `982426b`; only `claude-work/` and `screenshots/` untracked |
| Project config | portrait, GL Compatibility, 480x854 `canvas_items`/`expand`, main scene set, name "Gravity Flip" |

### Missing
| Item | Finding |
|---|---|
| JDK 17 | **Not installed.** Only `<JDK_PATH>`; it is also the `java`/`javac` on PATH (`...\Oracle\Java\javapath`). `JAVA_HOME` unset. No `keytool` on PATH. |
| Android SDK | **None.** `<ANDROID_DIR>` and `<ANDROID_SDK_PATH>` do not exist. `C:\Users\<WINDOWS_USER>\AppData\Local\Android\Sdk` does not exist. `<OTHER_DRIVE>\Android` exists but is empty (backup drive; ignore). `ANDROID_HOME`/`ANDROID_SDK_ROOT` unset. |
| cmdline-tools / sdkmanager | Not present |
| platform-tools / adb | Not present (and no `adb` on PATH) |
| build-tools, platforms, NDK, CMake | Not present |
| Godot export templates | **None** (`%APPDATA%\Godot\export_templates` empty, no `4.7.2.stable` folder) |
| Godot Android settings | `android_sdk_path` = `C:\Users\<WINDOWS_USER>\AppData\Local/Android/Sdk` (non-existent); `java_sdk_path` = empty; `debug_keystore` = `C:/Users/<WINDOWS_USER>/AppData/Roaming/Godot/keystores/debug.keystore` (the folder does not exist; the store password is the public Android debug default, not shown here) |
| Export preset | No `export_presets.cfg`; no `android/` folder, keystores, gradle or manifest files in the project |
| Device | No `adb`, so connection could not be checked |

### Nothing reusable
There is no compatible JDK or SDK piece on the machine to reuse. The only candidate is Android Studio's bundled JDK 25 (see decisions). Do **not** install winget's `Google.PlatformTools` (37.0.1): it would create a second adb location outside the SDK; install platform-tools through `sdkmanager` into `<ANDROID_SDK_PATH>` instead.

## 2. Compatibility with Godot 4.7.2
Source: Godot 4.7 docs, https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html (page header "Godot Engine 4.7 documentation"). The `latest` docs list newer versions (build-tools 36.1.0, android-36, NDK 29, automatic SDK setup) that belong to Godot 4.8; do not use those.

| Component | Version to install |
|---|---|
| JDK | OpenJDK **17** (recommended; newer "supported") |
| Platform | `platforms;android-35` |
| Build-Tools | `build-tools;35.0.1` |
| Platform-Tools | `platform-tools` (docs: 35.0.0 or later; latest is fine) |
| Command-line tools | `cmdline-tools;latest` |
| CMake | `cmake;3.10.2.4988404` |
| NDK | `ndk;28.1.13356709` (r28b) |

Notes:
- A plain debug APK does not need a Gradle build, so the NDK and CMake may not be exercised by the export itself; the docs still list them and the editor's Export dialog may warn without them. Installing them costs download size only. If the Export dialog says they are unnecessary, they can be skipped.
- Compatibility details I could not verify: whether Godot 4.7.2 accepts JDK 25, and the Android export template download file name/size (the GitHub release page assets did not load). Choosing JDK 17 avoids the first question.
- Exact requirements should be re-checked against the warnings Godot's Export dialog shows once an Android preset exists.

### Target device: Samsung Galaxy M52 (5G)
From GSMArena/91mobiles: Snapdragon 778G (64-bit ARM), shipped with Android 11, upgradable to Android 13 (One UI 5.1), 6.7" 1080x2400, 20:9. Consequences:
- Export `arm64-v8a` only (smaller, faster build). Godot's default minimum SDK is far below Android 11, so the M52 is supported.
- 20:9 is taller than the 480x854 base, so with `expand` the visible area becomes about 480x1067 (the corridor is taller than the 854 case; the bot test already covered 480x1066).
- The device's actual Android version was not verified (read from specs, not from the phone).
- On Windows, `adb` normally recognises Samsung phones through the generic driver; if `adb devices` shows nothing or "unauthorized", the Samsung USB driver may be needed (unverified here).

## 3. Package configuration (recommended, not applied)
- `application/config/name`: "Gravity Flip" (already set).
- Android preset `package/unique_name`: `com.aniketsagar.gravityflip` (valid: lowercase segments starting with a letter).
- `version/code` 1, `version/name` "1.0" (defaults are fine for debug).
- Architectures: arm64-v8a only. Gradle build: off. Permissions: none. Export path suggestion: `build/gravityflip-debug.apk`.
- `export_presets.cfg` is in `.gitignore`, so the preset stays local (it holds no secrets for a debug build; for later release builds use the `GODOT_ANDROID_KEYSTORE_RELEASE_*` environment variables instead of writing passwords into it).
- `build/` and `*.apk` are not currently ignored; add them to `.gitignore` when the build output folder is created.

## 4. Recommended installation steps (none executed)
Run in PowerShell. Re-run the verification line after each step before continuing.

1. **JDK 17 (Temurin) via winget**
   `winget install --id EclipseAdoptium.Temurin.17.JDK --source winget`
   (winget lists 17.0.20.101; expected path `C:\Program Files\Eclipse Adoptium\jdk-17.*-hotspot`). Check afterwards that the installer did not change your default `java` on PATH or set `JAVA_HOME` unexpectedly (`java -version`, `$env:JAVA_HOME`); the plan below uses the explicit path and does not depend on either. Verify: `& "<jdk17>\bin\java.exe" -version` and that `<jdk17>\bin\keytool.exe` exists.
2. **Create the SDK folder and get the command-line tools**
   - `New-Item -ItemType Directory <ANDROID_SDK_PATH>`.
   - Download "Command line tools only" for Windows from https://developer.android.com/studio#command-line-tools-only (file `commandlinetools-win-15859902_latest.zip`, 155.7 MB, published SHA-256 `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`; the direct URL is probably `https://dl.google.com/android/repository/<file>` but that pattern is from general knowledge, so use the page link). Check the hash with `Get-FileHash` before extracting.
   - Extract into a scratch folder, then move its `cmdline-tools` contents to `<ANDROID_SDK_PATH>\cmdline-tools\latest\` so that `<ANDROID_SDK_PATH>\cmdline-tools\latest\bin\sdkmanager.bat` exists.
3. **Install SDK packages (accepting licences is your decision)**
   For this session only: `$env:JAVA_HOME = '<jdk17 path>'`, then
   `<ANDROID_SDK_PATH>\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=<ANDROID_SDK_PATH> --licenses`
   `<ANDROID_SDK_PATH>\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=<ANDROID_SDK_PATH> "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"`
   Verify: `<ANDROID_SDK_PATH>\platform-tools\adb.exe version`, and folders `build-tools\35.0.1`, `platforms\android-35`, `ndk\28.1.13356709`, `cmake\3.10.2.4988404`. Size not measured (the NDK is the largest piece; expect several GB).
4. **Godot export templates 4.7.2**: in the Godot editor, Editor > Manage Export Templates > Download and Install (official mirror). Offline alternative: download `Godot_v4.7.2-stable_export_templates.tpz` from https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable (asset name assumed, page assets did not load) and use "Install from File". Verify `%APPDATA%\Godot\export_templates\4.7.2.stable` exists.
5. **Godot editor settings** (Editor Settings > Export > Android): Java SDK Path = the JDK 17 folder; Android SDK Path = `<ANDROID_SDK_PATH>`. Replaces the dead `C:\...\Android\Sdk` value. (Could also be edited in `%APPDATA%\Godot\editor_settings-4.7.tres` with the editor closed; the editor UI is safer.)
6. **Debug keystore** (only if the editor does not create it): with JDK 17's `keytool`, create `%APPDATA%\Godot\keystores\debug.keystore` with alias `androiddebugkey` and the standard debug passwords Godot's settings already use (do not paste those values into chat or files). Keep it out of the repo (`*.keystore` is already ignored; it lives outside the repo anyway).
7. **Phone**: Settings > About phone > Software information > tap Build number 7 times; Developer options > enable USB debugging; connect by USB, set the USB mode to File transfer if prompted, accept the RSA prompt. Verify `<ANDROID_SDK_PATH>\platform-tools\adb.exe devices` lists the phone as `device` (not `unauthorized`).
8. **Project changes (after approval)**: add the Android export preset (package `com.aniketsagar.gravityflip`, arm64-v8a, debug, no Gradle), create `build/` and add `build/` and `*.apk` to `.gitignore`.
9. **Export and install (smallest reliable path)**: from the editor, the Android "Remote Deploy" button, or CLI:
   `& 'E:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path E:\dev\projects\gravity-flip --export-debug "Android" build\gravityflip-debug.apk`
   then `<ANDROID_SDK_PATH>\platform-tools\adb.exe install -r build\gravityflip-debug.apk` and start the app from the phone (or `adb shell monkey -p com.aniketsagar.gravityflip 1`). (The CLI preset name must equal the preset's name; this command is untested.)
10. **On-device checks**: one tap = one flip, restart works, layout on 20:9, frame rate, no crash on lock/unlock, back button.

Rollback: uninstall JDK 17 with winget/Add-Remove Programs; delete `<ANDROID_DIR>`; delete `%APPDATA%\Godot\export_templates\4.7.2.stable`; delete the preset and `.gitignore` additions.

## 5. Decisions and issues needing your attention
1. **JDK 17 vs Android Studio's JDK 25.** Recommended: install Temurin 17 (docs-recommended, small download). The JDK 25 already on disk "may work" per the docs' "higher versions supported", but is unproven; Studio's SDK manager would also bring its own Gradle/AGP assumptions. Please confirm the install.
2. **SDK route.** Recommended: command-line tools into `<ANDROID_SDK_PATH>` (smallest, no emulator images). Alternative: the SDK Manager inside Android Studio with the SDK location set to `<ANDROID_SDK_PATH>` (GUI, same packages; also easy to add an emulator later).
3. **Licences:** installing the SDK requires accepting Google's Android SDK licences; that has to be your decision.
4. **Optional components:** NDK/CMake may be unnecessary for a non-Gradle debug APK. Say if you prefer to skip them to save disk/time and add them only if Godot's Export dialog demands them.
5. **Unverified:** JDK 25 compatibility, template asset name/size, device Android version, Samsung USB driver need, and download sizes.
6. **Machine PATH:** the default `java` is JDK 16.0.2. This plan does not change it; if you want JDK 17 as the default, that is a separate choice.
