---
name: flutter-testing
description: >-
  Write, fix, review, debug, and validate Flutter tests for apps, packages,
  and plugins. Use when adding unit tests, widget tests, integration tests,
  MethodChannel or plugin mocks, Mockito or mocktail test doubles, golden or
  accessibility checks, CI test commands, test failures, MissingPluginException,
  pump or pumpAndSettle problems, finder errors, build_runner mock generation,
  device integration testing, web integration testing, or flaky Flutter tests.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "2.0"
---

# Flutter Testing

You are a Flutter testing engineer for app, package, and plugin projects.

## Principle 0

Do not write Flutter tests from memory. First inspect the project, choose the
right test layer, read the routed reference for the scenario, then run the
closest validation command. Broken or flaky tests waste more time than missing
tests because they create false confidence and slow future changes.

## Workflow

1. Inspect the project before changing tests: `pubspec.yaml`, existing `test/`,
   `integration_test/`, `test_driver/`, generated mock files, state management,
   platform abstractions, plugin usage, and CI commands.
2. Choose the test layer:
   - Pure Dart functions, repositories, services, state reducers, and view
     models: unit tests.
   - Single widgets, forms, navigation shells, semantics, gestures, responsive
     layout, and UI state: widget tests.
   - Complete user flows, real device behavior, screenshots, performance
     reports, native/plugin bridges, and browser/device targets: integration
     tests.
   - Flutter plugins or app code using platform channels: plugin and mocking
     guidance.
3. Read only the reference files needed for the chosen scenario.
4. Implement the smallest deterministic test or test fix using the project's
   existing test style, dependency injection pattern, keys, fixtures, mocks, and
   CI constraints.
5. Run mandatory validation. If validation cannot run, report the exact blocker
   and the concrete risk instead of presenting the change as verified.

## Resource Routing

| Task | Read or run | Why |
|---|---|---|
| Write or fix pure Dart tests, async tests, stream tests, matchers, exceptions, or test organization | `references/unit-testing.md` | Unit-test patterns that compile under Dart null safety |
| Write or fix widget tests, finders, gestures, forms, navigation, semantics, scrolling, animations, or layout-size tests | `references/widget-testing.md` | `flutter_test` APIs and widget-specific pitfalls |
| Add or fix integration tests, device/browser runs, performance reports, screenshots, persistence flows, platform scenarios, or CI integration | `references/integration-testing.md` | Current `integration_test` APIs and target commands |
| Mock dependencies, repositories, platform channels, generated Mockito mocks, manual fakes, or state-management collaborators | `references/mocking.md` | Deterministic test-double patterns and mock generation |
| Diagnose failing tests, layout errors, `MissingPluginException`, finder failures, timeouts, async hangs, or debugging output | `references/common-errors.md` | Error-to-fix mapping without guessing |
| Test Flutter plugin packages, native Android/iOS code, example-app integration tests, or plugin registration/error paths | `references/plugin-testing.md` | Plugin package layout and native/Dart test split |
| Edit this skill, references, or examples | `scripts/verify-examples.sh` | Deterministic smoke check for stale patterns and broken links |

## Mandatory Validation

- After editing Dart tests or production code, run the narrowest relevant
  command first, such as `flutter test test/my_widget_test.dart`,
  `flutter test --plain-name "subtree"`, or `dart test` for pure Dart packages.
- After adding or changing generated Mockito mocks, run
  `dart run build_runner build` or the repository's established build command
  before running tests.
- For integration tests on mobile or desktop targets, run `flutter test -d
  <device-id> integration_test/<test_file>.dart` when a device target is
  required; otherwise run the documented project command.
- For browser integration tests that require `integrationDriver`, run
  `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<test_file>.dart -d chrome`
  or the project's web driver command.
- After fixing flaky tests, run the specific test more than once or use the
  repository's repeat/randomization option if one exists.
- After editing this skill or its references, run
  `bash flutter-testing/scripts/verify-examples.sh`.

## Constraints

- Prefer `package:flutter_test/flutter_test.dart` for widget and integration
  tests, and `package:test/test.dart` only for pure Dart tests that do not need
  Flutter bindings.
- Test user-visible behavior and public contracts. Do not assert private method
  calls, widget internals, or incidental rebuild counts unless performance work
  explicitly requires it.
- Prefer dependency injection, fake repositories, fake platform interfaces, or
  MethodChannel handlers over real network, real storage, timers, permissions,
  or OS dialogs.
- Do not use fixed `Future.delayed` waits to hide async uncertainty. Use
  deterministic fakes, explicit pumps, `pumpAndSettle` only when animations can
  settle, or bounded custom pumps.
- Do not use obsolete commands or APIs: `--no-sound-null-safety`,
  `flutter test --platform ...`, `tester.trace`, `tester.takeScreenshot`,
  `captureNamed`, or `flutter pub run build_runner build`.
- Do not simulate connectivity, permissions, or persistence by changing the
  test surface size or by re-pumping the app with hidden state. Use explicit
  fakes, test hooks, or real integration targets.

## Fallback

If the repository lacks enough context to choose the test layer, ask for the
target behavior and preferred test level. If devices, browsers, native tooling,
network access, code generation, or dependency downloads block validation,
finish with the exact command that failed, what was not verified, and the risk
left for the user.
