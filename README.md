# Travel Journal

An iOS-style travel journal built with Flutter and `cupertino_ui`.
Currently, the app provides Trips, Explore, and Settings placeholder screens,
with an independent navigation stack for each tab.

## Architecture

We follow Flutter's [app architecture guide](https://docs.flutter.dev/app-architecture/guide)
and [case-study package structure](https://docs.flutter.dev/app-architecture/case-study#package-structure).
The [architectural overview](https://docs.flutter.dev/resources/architectural-overview)
explains the framework itself and links to the app guide.

Current structure:

```text
lib/
  main.dart                    # Entry point
  app/
    app.dart                   # App configuration and dependency composition
  ui/
    core/
      ui/app_shell.dart        # Shared Cupertino tab navigation
    trips/
      widgets/trips_screen.dart
    explore/
      widgets/explore_screen.dart
    settings/
      widgets/settings_screen.dart
```

As features gain state and data, extend the structure with:

```text
lib/
  ui/<feature>/view_models/    # UI state, data transformation, and commands
  data/repositories/          # Sources of truth for application data
  data/services/              # Storage, network, and platform API access
  domain/models/              # Immutable application data models
```

Views contain rendering, layout, animation, and simple navigation logic.
Each stateful feature gets a view model that exposes UI state and commands.
Use constructor injection for dependencies; compose them at the app entry point.
Use Flutter's `ChangeNotifier` and `Listenable` when observable state is needed.
Static placeholder screens currently have no view models or data dependencies.

Repositories expose application data to view models and coordinate services.
Define abstract repository contracts when adding data, with implementations for
the actual storage or API. Services wrap external I/O and do not depend on the UI.
Data flows from services through repositories and view models into views;
user actions invoke view-model commands to update data.

Add domain use cases only when logic becomes complex or is shared by multiple
view models. Keep feature UI under `ui/<feature>/`, shared UI under `ui/core/`,
and reusable data components under `data/`.

## Validation

Run formatting and static analysis:

```sh
dart format lib
flutter analyze
```

Do not perform manual app testing. When features gain behavior, add automated
tests for their view models, repositories, services, and relevant widget flows.
