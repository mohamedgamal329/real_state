# Copilot Instructions for `real_state`

## Project Overview
- **Type:** Flutter cross-platform app (mobile, web, desktop)
- **Structure:**
  - `lib/` contains all Dart source code, organized by `core/` (shared logic) and `features/` (domain modules)
  - Platform-specific code in `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`
  - Tests in `test/`, mirroring `lib/` structure

## Key Patterns & Conventions
- **Feature-first organization:**
  - Each feature in `lib/features/<feature_name>/` (e.g., `auth`, `settings`, `properties`)
  - Shared utilities in `lib/core/`
- **State management:**
  - (Infer from code: likely Provider, Riverpod, Bloc, or GetX; check `lib/core/` for patterns)
- **Error handling:**
  - Centralized in `lib/core/failure/` and `lib/core/handle_errors/`
- **Routing:**
  - Managed in `lib/core/routes/`
- **Theming:**
  - Centralized in `lib/core/theme/`

## Developer Workflows
- **Build:**
  - Standard Flutter: `flutter build <platform>`
- **Run:**
  - `flutter run` (platform auto-detected)
- **Test:**
  - `flutter test` (unit/widget tests in `test/`)
- **Dependencies:**
  - Managed via `pubspec.yaml` (`flutter pub get`)

## Integration Points
- **Firebase:**
  - Integration code in `lib/core/firebase/`
- **Platform code:**
  - Native code in `android/`, `ios/`, etc. (rarely edited unless adding plugins)

## Project-Specific Notes
- **Add new features:**
  - Create a new directory in `lib/features/`
  - Mirror test structure in `test/features/`
- **Constants/config:**
  - Use `lib/core/constants/`
- **Validation:**
  - Use helpers in `lib/core/validation/`

## Examples
- To add a new settings page:
  - Add Dart files in `lib/features/settings/`
  - Add tests in `test/features/settings/`
- To add a new error type:
  - Extend in `lib/core/failure/`

---
For more, see `README.md` and explore `lib/` for code patterns.
