# Lab 03

[![CI](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml)

A complete, production-minded Flutter starter built around a small "learning
items" demo. The app lists items, opens a detail route, keeps independent
navigation stacks for each tab, and supports light/dark/system themes.

- **App ID:** `com.quanphungg.lab03`
- **Dart package:** `lab03`
- **Targets:** Android, iOS, web
- **Flutter:** 3.47.2 (stable) · **Dart:** 3.13.2

## Stack

| Concern | Choice |
| --- | --- |
| UI | Material 3 via `material_ui` |
| State | `flutter_riverpod` 3 (`AsyncNotifier`, `Notifier`) |
| Routing | `go_router` 18 (`StatefulShellRoute.indexedStack`) |
| Async model | `AsyncValue` with explicit loading/error/refresh states |
| Tests | `flutter_test`, provider overrides, deterministic fakes |
| CI | GitHub Actions: format, analyze, test, coverage, web build |

## Quick start

```sh
flutter pub get
flutter run                    # pick a connected device
flutter run -d chrome          # web
flutter run -d <device-id>     # specific device
```

List devices with `flutter devices`. An Android emulator or a connected device
is required for `flutter run -d android`; iOS builds require macOS and Xcode.

## Commands

| Task | Command |
| --- | --- |
| Install packages | `flutter pub get` |
| Format | `dart format .` |
| Check formatting | `dart format --output=none --set-exit-if-changed .` |
| Static analysis | `flutter analyze` |
| Run tests | `flutter test` |
| Coverage report | `flutter test --coverage` |
| Web release build | `flutter build web --release` |
| Android release build | `flutter build appbundle --release` |

The generated coverage report is written to `coverage/lcov.info` and is
git-ignored.

## Project layout

```text
lib/
├── main.dart                          # ProviderScope + runApp
└── src/
    ├── app/
    │   ├── app.dart                   # MaterialApp.router, theme, l10n
    │   ├── router/
    │   │   ├── app_router.dart        # GoRouter provider + 404 page
    │   │   ├── app_routes.dart        # Paths and route names
    │   │   └── view/app_shell.dart    # Bottom navigation shell
    │   └── theme/app_theme.dart       # Material 3 light/dark themes
    ├── core/
    │   ├── constants/app_info.dart    # Name and version
    │   └── widgets/error_view.dart    # Shared error/retry UI
    └── features/
        ├── items/
        │   ├── data/item_repository.dart      # Repository + provider
        │   ├── domain/item.dart               # Model and level enum
        │   └── presentation/
        │       ├── items_controller.dart      # AsyncNotifier
        │       ├── items_page.dart            # List + pull-to-refresh
        │       └── item_details_page.dart     # Detail route
        └── settings/
            └── presentation/
                ├── settings_page.dart
                └── theme_mode_controller.dart
```

Tests mirror the feature tree:

```text
test/
├── support/                 # Fakes, fixtures, pumpApp helper
└── src/
    ├── app/app_test.dart    # End-to-end widget flows
    └── features/...         # Repository, provider, and controller tests
```

## Architecture

Features are grouped by **feature**, then split into layers:

- **domain** — plain Dart models. No Flutter or package dependencies.
- **data** — repository contracts, implementations, and the Riverpod provider
  that exposes them. Swap `InMemoryItemRepository` for an HTTP client without
  changing any UI code.
- **presentation** — screens, widgets, and Riverpod controllers. Widgets only
  read providers; they never construct repositories directly.

Data flows in one direction:

```text
ItemRepository ──► itemsControllerProvider (AsyncNotifier)
                              │
        ┌─────────────────────┼──────────────────────┐
        ▼                     ▼                      ▼
   ItemsPage            ItemDetailsPage        SettingsPage
  (list/refresh)         (same cache)         (invalidate cache)
```

`itemsControllerProvider` caches the fetched list, so opening a detail route
does not trigger another repository call. `refresh()` keeps the previous data
visible while re-fetching. Automatic retries are disabled on the provider, so
failures are surfaced immediately with an explicit **Try again** action.

Tests override `itemRepositoryProvider` with `FakeItemRepository`, which keeps
widget tests fast, deterministic, and network-free.

## Routing

| Path | Name | Screen |
| --- | --- | --- |
| `/items` | `items` | Item list |
| `/items/:id` | `item-details` | Item detail |
| `/settings` | `settings` | Settings |

The two top-level branches live in a `StatefulShellRoute`, so each tab keeps
its own navigation stack and scroll state. Deep links such as
`/items/riverpod-state` work directly on web and mobile. Unmatched locations
render `RouteErrorPage` from `app_router.dart`.

## Theming

`AppTheme` builds light and dark `ThemeData` from a single seed color
(`#4F46E5`). `themeModeControllerProvider` holds the selected
`ThemeMode.system | light | dark`, and `Lab03App` rebuilds `MaterialApp.router`
when it changes. Theme mode is in-memory by design; see **Next steps** below if
you want it persisted.

## Material UI in Flutter 3.47

Flutter 3.47 ships Material as the standalone `material_ui` package, and
`go_router` 18 is built on it. This repo imports `package:material_ui/material_ui.dart`
everywhere instead of the legacy `package:flutter/material.dart`.

If you add a third-party package that still imports legacy `flutter/material`,
wrap that subtree (or the app builder) with `MaterialUiCompatibilityBridge` as
documented in the `material_ui` README. For an old codebase, the migration is:

```sh
dart fix --apply --code=migrate_design_widgets
```

## CI

`.github/workflows/ci.yml` runs on pushes to `main`, pull requests, and manual
dispatches:

1. `dart format --set-exit-if-changed`
2. `flutter analyze`
3. `flutter test --coverage` (uploads `lcov.info`)
4. `flutter build web --release` (uploads the web bundle)

The Flutter SDK version is pinned in the `FLUTTER_VERSION` environment variable
at the top of the workflow. Update it together with your local SDK, then run
`flutter pub upgrade` and the full command set before merging.

Dependabot checks pub and GitHub Actions dependencies weekly.

## Conventions

- Single quotes, 80-column lines, trailing commas where the formatter adds them.
- No code generation: providers and models are plain Dart, so there is no
  `build_runner` step to keep in sync.
- New behavior gets a test at the lowest layer that can prove it (repository →
  provider → widget).
- Keep `lib/src/core` free of feature imports; shared code moves there only when
  at least two features need it.

## Next steps

- Persist theme mode with `shared_preferences` behind a repository interface.
- Add `riverpod_generator` / `freezed` if the model layer grows.
- Add integration tests under `integration_test/` for real device flows.
- Configure Android signing and iOS provisioning before release builds.
- Add a real HTTP repository and error mapping for production APIs.

No license file is included; add one before distributing the project.
