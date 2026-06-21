# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter app named `summon_ai`. Application code lives in `lib/`, with the entry point in `lib/main.dart`. The current organization separates concerns into `lib/model/` for data classes, `lib/view/` for UI screens, `lib/view_model/` for state and presentation logic, and `lib/service/` for external API access. Platform projects are under `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`. Tests belong in `test/`; add new widget or unit tests beside the existing `test/widget_test.dart`. Static assets declared in `pubspec.yaml` currently include `.env`.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies from `pubspec.yaml`.
- `flutter run`: launch the app on the selected emulator, device, or desktop target.
- `flutter analyze`: run static analysis using `analysis_options.yaml` and `flutter_lints`.
- `flutter test`: run all tests under `test/`.
- `flutter build apk` or `flutter build web`: create release builds for Android or web.

Run `flutter pub get` after changing dependencies, assets, or SDK constraints.

## Coding Style & Naming Conventions

Follow the default Dart formatter: two-space indentation, trailing commas where they improve formatting, and `dart format .` before submitting changes. The project includes `package:flutter_lints/flutter.yaml`; resolve analyzer warnings instead of suppressing them unless there is a documented reason. Use `PascalCase` for classes and widgets, `camelCase` for variables and methods, and `snake_case.dart` for Dart filenames. Keep view models named like `AIViewModel` or `WeatherViewModel`, and keep UI widgets in `lib/view/`.

## Testing Guidelines

Use `flutter_test` for widget and unit tests. Name test files with the `_test.dart` suffix and write behavior-focused test names, for example `shows weather results after city search`. The existing generated counter smoke test is stale relative to the current app; update or replace it when touching tests. Run `flutter test` and `flutter analyze` before opening a PR.

## Commit & Pull Request Guidelines

Recent history uses short imperative subjects, often prefixed with `feat:`. Prefer messages like `feat: add weather error state` or `fix: handle missing API key`. Pull requests should include a concise description, testing performed, linked issue if applicable, and screenshots or screen recordings for UI changes.

## Security & Configuration Tips

The app loads `.env` with `flutter_dotenv`. Do not commit real API keys or secrets; use local environment values and document required keys in PRs when adding integrations.
