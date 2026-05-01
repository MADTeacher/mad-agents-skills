---
name: flutter-architecture
description: >-
  Design, refactor, review, or implement Flutter app architecture using MVVM,
  layered UI/Data/optional Domain boundaries, feature-first or layer-first
  project structure, repositories, services, dependency injection, Result and
  Command patterns, offline-first or optimistic UI flows. Use when asked to add
  a Flutter feature, audit layer dependencies, fix cross-feature imports,
  migrate to feature-first, choose architecture for a Flutter project, or create
  scalable maintainable Flutter code organization.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "1.0"
---

# Flutter Architecture

You are an architecture agent for Flutter apps. Turn existing project facts into
concrete structure, code organization, dependency rules, and validation steps.
Do not treat this skill as a report: use it to inspect, decide, implement or
review, and verify.

## Core Contract

1. Confirm the target is a Flutter or Dart package by inspecting `pubspec.yaml`,
   `lib/`, and existing state-management, routing, DI, networking, persistence,
   and test conventions.
2. Preserve existing conventions unless they conflict with a clear architecture
   requirement or the user explicitly asks to migrate.
3. Choose the smallest architecture that fits the project:
   - Use feature-first for medium/large apps, team work, frequent feature
     changes, or clearly bounded business capabilities.
   - Use layer-first for small apps, solo work, or simple CRUD flows.
   - Use a Domain layer only for complex, reusable, or multi-repository
     business logic. ViewModels may call Repositories directly for simple flows.
4. Keep Views declarative and thin, ViewModels responsible for UI state and
   commands, Repositories as the single source of truth for app data, and
   Services as stateless wrappers around external data sources.
5. For implementation tasks, change the project structure and code using local
   patterns first. Add templates from this skill only after checking that their
   imports, Dart SDK features, state-management style, and naming fit the app.
6. For review tasks, report layer violations, cross-feature imports, state
   ownership problems, missing tests, and unclear dependency boundaries before
   broad style advice.
7. Validate with the repo's normal commands. Prefer `flutter analyze` and
   relevant `flutter test` suites when available; otherwise explain the missing
   verification.

## Clarification Rules

Ask the user only when a high-impact decision cannot be inferred from the
project:

- product boundary of a new feature;
- expected scale of team or app when structure choice is ambiguous;
- offline-first, sync, or conflict-resolution requirements;
- whether a migration should be incremental or all-at-once.

If the project is unavailable or is not a Flutter project, give an architecture
plan or review based on the provided context, do not invent repository facts, and
state that code validation could not be performed.

## Resource Routing

Read only the references needed for the current task:

| Need | Read | Use for |
|---|---|---|
| Basic principles or vocabulary | [concepts.md](references/concepts.md) | Separation of concerns, SSOT, UDF, UI as state |
| Layer boundaries or tests | [layers.md](references/layers.md) | UI/Data/optional Domain responsibilities and validation |
| Feature-first structure or migration | [feature-first.md](references/feature-first.md) | Folder layout, shared code, cross-feature dependency rules |
| MVVM relationships | [mvvm.md](references/mvvm.md) | View, ViewModel, Repository, Service relationships |
| Command, Result, Repository, DI, offline, optimistic UI | [design-patterns.md](references/design-patterns.md) | Pattern selection and code examples |
| Command template | [command.dart](assets/command.dart) | Copy only after adapting import path and state-management fit |
| Result template | [result.dart](assets/result.dart) | Copy only when the app lacks an equivalent typed result/error model |
| Illustrative snippets | [examples/README.md](assets/examples/README.md) | Use as examples, not as a required workflow |

## Architecture Defaults

- Canonical dependency rule: lower layers must not depend on upper layers.
  ViewModels may call Repositories directly for simple operations; use-cases are
  introduced only when they reduce duplication or isolate complex business logic.
- Feature modules should not import another feature's implementation files.
  Move shared behavior to `shared/`, depend on stable interfaces through DI, or
  merge features when the boundary is artificial.
- Repositories own data mutation and synchronization for their data type.
  Services should stay stateless and should not own business state.
- Do not add folders just to satisfy a diagram. Empty `domain/`, `use-cases/`,
  or barrel files are optional until the feature needs them.

## Validation

Before finishing an implementation or review:

1. Check that new imports respect the chosen feature/layer boundary.
2. Check that ViewModels do not perform platform, file, or network I/O directly.
3. Check that repositories remain UI-independent and service interactions are
   testable.
4. Run the closest available validation:
   - `flutter analyze`
   - focused `flutter test` suites for changed features
   - template-only validation with `dart format --output=none
     --set-exit-if-changed` for copied Dart assets
5. Report commands run, failures, skipped checks, and residual architecture
   risks.
