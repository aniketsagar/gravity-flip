# Report 006 — Android export readiness and setup plan (2026-10-26)

Prompt: `../prompts/006-android-readiness.md`. Read-only inspection; nothing installed, no project or Godot settings changed.

## Verdict
**Not ready to export.** The project itself is configured sensibly for Android, but the machine lacks the Android SDK, a suitable JDK, Godot's 4.7.2 export templates and an export preset. None needs a code change.

## Requirements (Godot 4.7 docs, fetched 2026-10-26)
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html (page header: "Godot Engine 4.7 documentation"). The `latest` docs list newer versions (build-tools 36.1.0, android-36, NDK 29) and an automatic SDK setup that starts in Godot 4.8; those do not apply to 4.7.2.
- JDK: OpenJDK 17 recommended; higher versions "supported".
- Android SDK Platform 35; Build-Tools 35.0.1; Platform-Tools 35.0.0 or later; Command-line Tools (latest); CMake 3.10.2.4988404; NDK r28b (28.1.13356709).
- Editor Settings > Export > Android: Java SDK Path, Android SDK Path (must contain `platform-tools/adb`).
- Gradle build is not required for a normal APK; it is required for AAB (Google Play) and custom Java/plugins.
- The docs page fetched does not describe export-template download; export templates matching 4.7.2 are installed through the editor (Editor > Manage Export Templates) per general Godot practice. Not verified from docs here.
- Confirm the exact versions in the editor's Export dialog warnings once an Android preset exists, since those are authoritative for 4.7.2.

## Findings

### Project (already fine)
| Item | State |
|---|---|
| Renderer | `gl_compatibility` for desktop and mobile: correct for Android |
| Orientation | `window/handheld/orientation=1` (portrait) |
| Viewport/stretch | 480x854, `canvas_items`, `expand` |
| Input | tap and click handled; emulated mouse from touch is filtered (untested on device) |
| Permissions | none needed |
| Icon | `res://icon.svg` (default Godot icon; works, placeholder) |
| Main scene | `res://scenes/main.tscn` |

### Project gaps
- `export_presets.cfg` does not exist. It is also in `.gitignore` (together with `/android/`, `*.keystore`, `*.jks`), so presets will never be committed.
- No Android package name set (the preset defaults to `com.example.$genname`, which should be changed, e.g. `com.<you>.gravityflip`).
- `application/config/name` is "Gravity Flip" (good, used as the app name).
- No `android/` directory (only needed for a Gradle build).
- `physics/3d/physics_engine="Jolt Physics"` is irrelevant to a 2D game; harmless.

### Machine
| Item | State |
|---|---|
| Godot editor | `E:\Godot_v4.7.2-stable_win64.exe\...` (editor + console builds), 4.7.2.stable |
| Android SDK | **Missing.** Editor setting points to `C:\Users\<WINDOWS_USER>\AppData\Local\Android\Sdk`, which does not exist. `ANDROID_HOME` / `ANDROID_SDK_ROOT` unset. `<OTHER_DRIVE>\Android` exists but is empty (and H: is a backup drive). `adb`, `sdkmanager` not found. |
| Android Studio | Installed at `C:\Program Files\Android\Android Studio` (build AI-262, 2026.2.1), with `~/.android/avd` empty and no SDK configured. |
| JDK | PATH `java`/`javac` is **JDK 16.0.2** (`<JDK_PATH>`): too old (needs 17+). `JAVA_HOME` unset. Godot setting `export/android/java_sdk_path` is empty. Android Studio bundles a JetBrains runtime, **JDK 25.0.3**, with `keytool`: newer than the recommended 17 (docs say "higher versions are supported" but it is unproven with this Godot/Gradle combination). |
| Export templates | **Missing.** `%APPDATA%\Godot\export_templates` is empty (no `4.7.2.stable` folder). |
| Debug keystore | Editor setting points to `%APPDATA%\Godot\keystores\debug.keystore` (the conventional, public Android debug-keystore password `android`, not a project secret), but the folder/file does not exist. Needs `keytool` to create (or the editor may create it; unverified). |
| Release keystore | None. Not needed until a Play Store build. |
| Device | None connected (no `adb` to check). No AVD. |
| Disk | C: 64 GB free, E: 190 GB free, F: 70 GB, others larger. SDK + NDK + templates need roughly 5-10 GB (estimate, not measured). |
| Network | Not tested; downloads are required. |

## Setup plan (nothing below has been done)

### Decisions first
1. **Test target:** a physical Android phone over USB is recommended (no AVD exists, emulator images are multi-GB, and touch behaviour is the main thing to verify). Do you have one, and with USB debugging available?
2. **SDK location:** suggest `<ANDROID_SDK_PATH>` (fast drive, no spaces, no permission quirks) instead of `C:\...\AppData\Local\Android\Sdk`. `H:` (backup drive) is not recommended.
3. **JDK:** suggest installing a separate **JDK 17** (e.g. Temurin 17) rather than relying on JDK 16 or Android Studio's JDK 25. Pointing Godot at the JDK 25 JBR is the no-download alternative; try it only if you accept possible build-tool incompatibilities.
4. **Output type:** debug **APK** for device testing needs no Gradle build. Gradle/AAB only matters for Play Store later.

### Steps (in order)
1. **JDK 17:** install, then set Godot Editor Settings > Export > Android > Java SDK Path to its folder (it must contain `bin\keytool.exe`, `bin\javac.exe`). Do not rely on PATH (still JDK 16).
2. **Android SDK:** install the components above into the chosen SDK folder, either with Android Studio's SDK Manager (SDK Platforms: Android 35; SDK Tools: Build-Tools 35.0.1, Platform-Tools, Command-line Tools latest, CMake 3.10.2.4988404, NDK 28.1.13356709) or with `sdkmanager --sdk_root=<path> "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"` (needs the cmdline-tools package and JDK 17 first; accept the SDK licences). Verify `<sdk>\platform-tools\adb.exe` exists.
3. **Editor settings:** set Android SDK Path to that folder (replace the non-existent `C:\...\Sdk` value). Debug keystore settings can stay.
4. **Export templates:** Editor > Manage Export Templates > download/install for 4.7.2 stable (Godot downloads the official set; needs network).
5. **Debug keystore:** if the editor does not create it, generate `%APPDATA%\Godot\keystores\debug.keystore` with the JDK 17 `keytool` (alias `androiddebugkey` and the conventional, public debug-keystore password `android` from Godot's docs; not a project secret) as in Godot's docs. Keep it out of the repo (already covered by `.gitignore` patterns).
6. **Phone:** enable Developer options + USB debugging, connect, confirm with `adb devices` and accept the RSA prompt.
7. **Project changes (the first time files are touched, to be approved):**
   - Add an Android export preset (`export_presets.cfg`, ignored by git): package `com.<name>.gravityflip`, portrait already set in project settings, arm64-v8a only (others optional), debug export, Gradle build off, no extra permissions.
   - Optionally replace the placeholder icon.
8. **Export and run:** export a debug APK (or "One-click deploy" the Android device button in the editor) from the editor; for a repeatable CLI build later: `Godot_...console.exe --headless --path . --export-debug "Android" build\gravityflip-debug.apk` (needs the preset name to match; untested). Keep builds out of git.
9. **On-device test list:** tap flips exactly once (touch plus the emulated-mouse filter), restart works, layout on the phone's real aspect ratio (taller than 9:16 should only lengthen the corridor), 60 fps feel, no crash on rotate/lock, back button behaviour, performance.
10. **Later (not now):** release keystore + AAB + Gradle build for Google Play; store assets; signing secrets in environment variables (`GODOT_ANDROID_KEYSTORE_RELEASE_*`) so passwords never go in `export_presets.cfg` or git.

## Risks / unknowns
- Exact 4.7.2 version requirements should be re-checked against the editor's Export warnings (docs pages vary by minor release).
- JDK 25 with Godot's Android tooling is untested; JDK 17 avoids the question.
- Template download size and time unmeasured; network unverified.
- Device-specific input behaviour cannot be verified until a real device is available.

## What I need from you before proceeding
1. Physical phone available? (Yes/No)
2. OK to install JDK 17 and the Android SDK (suggested at `<ANDROID_SDK_PATH>`)?
3. Package name to use (e.g. `com.<yourname>.gravityflip`).
