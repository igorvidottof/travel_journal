# Travel Journal — Agent Instructions

Apply these instructions to every prompt involving this repository. Follow the
user's current request when it changes a prior project decision. Inspect the
current code and README before relying on older conversation suggestions.

## Communication and learning

- The user is learning English. Whenever they write in English, briefly correct
  errors and explain meaningful changes while also addressing the actual request.
  If the English is correct, say so briefly. Clearly distinguish necessary
  corrections from optional suggestions for more natural phrasing.
- Match the user's language for the main response. English feedback also applies
  to the English portion of mixed Portuguese/English messages.
- This is a learning project focused on Flutter and native iOS behavior. Explain
  the purpose of meaningful changes and introduce concepts in manageable steps.
- For implementation requests, make the requested changes and explain the result.
  For questions or requests for instruction, teach without assuming permission to
  implement unrelated features.
- Keep explanations practical and concise. Report what changed, how it was
  verified, and any remaining limitations. Do not claim checks that were not run.
- Always include a concise comparison of the relevant iOS/Cupertino specifics
  with Material Design, naming equivalent Flutter widgets where available and
  explaining meaningful interaction differences. If a task has no UI impact,
  state that there are no new platform-specific UI differences to report.

## Project scope and current baseline

- Travel Journal is an iOS-style Flutter app using the standalone `cupertino_ui`
  package and `cupertino_icons`.
- The current milestone focuses on iOS. Android support was discussed as a future
  extension; do not introduce an Android UI or adaptive app root prematurely.
- The app already has Trips, Explore, and Settings placeholder screens with
  independent navigation stacks. Extend this implementation instead of recreating
  the initial tab-navigation milestone.
- Trip creation, Cupertino forms, date selection, and local persistence are the
  discussed next feature direction. Camera, maps, and other native integrations
  are later learning goals; implement them only within the requested scope.

## Architecture and organization

Use Flutter's official app architecture as the foundation:

- [App architecture guide](https://docs.flutter.dev/app-architecture/guide)
- [Case-study package structure](https://docs.flutter.dev/app-architecture/case-study#package-structure)

The [architectural overview](https://docs.flutter.dev/resources/architectural-overview)
describes the Flutter framework; use the app guide for application organization.
The current layout is:

```text
lib/
  main.dart
  app/app.dart
  ui/
    core/ui/app_shell.dart
    trips/widgets/trips_screen.dart
    explore/widgets/explore_screen.dart
    settings/widgets/settings_screen.dart
```

- Keep `main.dart` responsible for initialization and `runApp`. Configure the app
  in `lib/app/app.dart` and declare dependency providers in
  `lib/app/dependencies.dart`. Wrap the app in `ProviderScope` at startup.
- Keep feature UI under `ui/<feature>/`, shared UI under `ui/core/`, and preserve
  the existing `*Screen` naming. Earlier chat examples using `features/`, `*Page`,
  or `*View` do not require a rename of the current implementation.
- Views handle rendering, layout, animation, and simple navigation. Put UI state,
  data transformation, and commands in `ui/<feature>/view_models/` when needed.
- Use Riverpod for state management, dependency injection, and lifecycle
  management. Use `Provider` for repositories and services, and prefer
  `Notifier`/`AsyncNotifier` with their providers for view models. Access
  dependencies through `ref.watch` or `ref.read`; do not introduce a separate DI
  package or another state-management dependency. Keep the in-memory repository
  alive in the app scope so view models share one instance. Use automatic
  disposal for transient feature state and `ref.onDispose` for owned resources
  that require cleanup.
- Put sources of truth in `data/repositories/`. Define abstract repository
  contracts when adding data and implementations for the actual storage or API.
- Put external I/O, storage, networking, and platform API access in
  `data/services/`. Services must not depend on the UI.
- Put immutable application data models in `domain/models/` as needed. Add domain
  use cases only when logic is complex or shared by multiple view models.
- Follow unidirectional data flow: services and repositories supply data to view
  models; views render state and invoke view-model commands for user actions.
- Introduce layers when they have real responsibilities. Static placeholders do
  not need empty view models, repositories, services, or use cases.

## UI and platform behavior

- Keep `CupertinoApp` as the current app root and use
  `package:cupertino_ui/cupertino_ui.dart` for Cupertino UI, following existing
  imports. Keep design-system dependencies out of shared business and data logic.
- Preserve the `CupertinoTabScaffold`, `CupertinoTabBar`, and per-tab
  `CupertinoTabView` arrangement, including each tab's navigation state.
- Use Cupertino navigation, forms, dialogs, and pickers appropriate to the feature.
  Respect safe areas and native iOS navigation conventions.
- If Android support is requested later, share data and application logic while
  adapting presentation and navigation. Prefer `defaultTargetPlatform` for UI
  selection and select the app root at startup. Avoid duplicating every screen.
- Add dependencies or native integrations only when the feature needs them.
  Inspect installed versions and verify relevant official documentation before
  relying on unfamiliar or changing APIs.

## Validation

- Follow the current README: do not perform manual app testing. This supersedes
  the older chat's manual-only validation suggestion.
- For Dart changes, format the changed files with `dart format` and run
  `flutter analyze`. Respect `analysis_options.yaml` and existing lint rules.
- Do not write or execute automated tests at this stage. Validate changes with
  formatting and static analysis only.
- If tooling or platform restrictions prevent a check, report the limitation and
  leave a concrete command for validation. Never describe an unverified UI as
  tested.

## Change hygiene

- Inspect `git status` before editing and preserve unrelated or manual changes.
  Keep changes focused on the user's request; avoid broad cleanup or refactoring.
- Do not edit `README.md` unless the user explicitly asks you to. Architecture,
  setup, or validation changes do not authorize README updates on their own.
- Do not modify generated platform files, signing settings, or dependency versions
  without a concrete need for the requested work.
- Use Conventional Commits when suggesting or creating commits: `feat` for new
  behavior, `fix` for bugs, `refactor` for structural changes, `chore` for setup,
  and `docs` for documentation. Inspect the diff before committing and include
  only relevant files. Commit or push only when requested.
