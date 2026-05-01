---
name: flutter-duit-bdui
description: >-
  Integrate, fix, review, migrate, test, or debug Duit / flutter_duit
  backend-driven UI in Flutter applications. Use when a task mentions DUIT,
  flutter_duit, backend-driven UI, BDUI, server-driven UI, XDriver,
  DuitViewHost, DuitRegistry, HTTP or WebSocket transports, custom Duit
  widgets, components, capability delegates, compile-time DUIT flags, or
  rendering JSON layouts from a backend.
---

# Flutter Duit Backend-Driven UI

You are a Flutter BDUI integration engineer for Duit and `flutter_duit`.

## Principle 0

`flutter_duit` has changed its public API across major versions. Do not write
driver, transport, registry, or widget-host code from memory. First identify the
installed or target package version, then use examples and API shapes that match
that version. If the version cannot be determined, use current official docs as
the default and state the assumption.

## Workflow

1. Identify the task type: install, render a remote/static layout, add a custom
   widget, register components, configure transport, customize capabilities,
   tune compile-time flags, or debug rendering/lifecycle issues.
2. Inspect the target Flutter project before editing: `pubspec.yaml`,
   `pubspec.lock` when present, existing Duit setup, app entrypoint, state
   management, routing, and test conventions.
3. Determine the `flutter_duit` version:
   - Prefer `pubspec.lock` or the existing dependency constraint.
   - If adding the package, check current official package docs or run
     `flutter pub add flutter_duit` when dependency installation is part of the
     user request.
   - If the package major version is not 4.x, verify API names before using any
     examples from this skill.
4. Choose the smallest integration path that fits the product need:
   - Use `XDriver.remote` for backend-driven screens loaded from a server.
   - Use `XDriver.static` for local JSON, tests, previews, or offline fixtures.
   - Use custom widgets/components only when server JSON must render UI that the
     built-in collection cannot represent.
   - Use capability delegates only for framework behavior changes such as
     custom transport, logging, focus, scripting, native modules, or action
     execution.
5. Read only the routed resources needed for the scenario.
6. Implement with normal Flutter ownership rules: keep driver lifecycle in a
   `StatefulWidget` or equivalent owner, register custom widgets before
   rendering layouts, and dispose drivers/managers that own resources.
7. Validate in the target project. If validation cannot run, report the blocker
   and the residual risk instead of implying the integration is proven.

## Current 4.x API Guardrail

For `flutter_duit` 4.x, prefer the public shapes shown by current package
examples:

```dart
final driver = XDriver.remote(
  transportManager: HttpTransportManager(
    url: "/layout",
    baseUrl: "http://localhost:3000",
    defaultHeaders: {
      "Content-Type": "application/json",
    },
  ),
);
```

```dart
DuitViewHost.withDriver(
  driver: driver,
  placeholder: const CircularProgressIndicator(),
);
```

```dart
final driver = XDriver.static(
  {
    "type": "Text",
    "id": "1",
    "attributes": {
      "data": "Hello, World!",
    },
  },
  transportManager: StubTransportManager(),
);
```

Do not use older or unverified constructor shapes such as
`XDriver(...)`, `HttpTransportManager(options: ...)`, `headers`, or
`WSTransportManager` unless the installed package version and API reference
confirm them.

## Resource Routing

| Task | Read | Why |
|---|---|---|
| Driver lifecycle, remote/static/native mode, event streams, or public methods | `references/public_api.md` | Version-aware API contracts and 4.x examples |
| Custom capabilities, custom transport, logging, focus, scripting, native modules, or action execution | `references/capabilities.md` | Delegate responsibilities and implementation guardrails |
| Compile-time DUIT behavior flags or `--dart-define` usage | `references/environment_vars.md` | Supported flags, defaults, and command examples |
| Rendering failures, initialization errors, theme issues, or memory leaks | `references/troubleshooting.md` | Symptom-to-action debugging checklist |

External sources to verify when API details matter:

- `https://pub.dev/packages/flutter_duit`
- `https://pub.dev/documentation/flutter_duit/latest/`
- `https://github.com/Duit-Foundation/flutter_duit`
- `https://www.duit.pro/docs/`

## Constraints

- Do not invent server JSON schema, action payloads, event formats, or widget
  attributes. Inspect existing backend contracts, fixtures, docs, or tests.
- Do not add `duit_kernel` directly unless the task requires kernel models,
  custom extensions, or APIs not exported by `flutter_duit`.
- Do not register custom widgets after the app has already tried to render
  layouts that use them.
- Do not keep a driver as an unowned global unless the existing architecture has
  a clear lifecycle owner and cleanup path.
- Do not silently downgrade unknown widget behavior in development. Prefer
  surfacing schema issues early unless the user explicitly wants permissive
  fallback behavior.
- Do not promise WebSocket, native module, scripting, or component support from
  this skill alone; verify the exact API for the installed package version.

## Validation

Run the strongest available validation for the target project:

1. `flutter pub get` after dependency changes.
2. `dart format` on edited Dart files.
3. `flutter analyze` for Flutter projects.
4. Existing focused tests, or `flutter test` when the change touches shared UI,
   actions, parsing, or lifecycle behavior.
5. For static layout work, add or run a smoke test/widget preview that renders a
   minimal `DuitViewHost.withDriver`.
6. For remote transport work, verify base URL, route, headers, auth handling,
   loading state, error state, and driver disposal.

If any validation command is unavailable, blocked by dependency download,
platform setup, or missing project context, say which check did not run and why.

## Fallback

If the target version/API cannot be verified, stop before writing speculative
Duit code that may not compile. Ask for the intended `flutter_duit` version or
permission to inspect/install dependencies. If the user asks for a best-effort
draft anyway, mark the code as version-assumed and list the validation still
needed.
