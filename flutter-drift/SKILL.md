---
name: flutter-drift
description: Implement, fix, review, migrate, test, or debug Drift persistence in Flutter apps using SQLite, drift_flutter, type-safe Dart queries, generated tables, StreamBuilder or Riverpod StreamProvider UI, write operations, transactions, schema migrations, web assets, isolate sharing, and local database testing. Use when a Flutter task mentions drift, local database storage, SQLite, reactive database streams, CRUD, schemaVersion, build_runner, drift_dev make-migrations, migration tests, or Flutter-specific database setup across mobile, web, or desktop.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "1.1"
---

# Flutter Drift

Use this skill to add or repair Drift-based local persistence in Flutter apps. The skill is an operating workflow: inspect the target app first, choose only the relevant reference files, implement with current Drift APIs, and validate generated code.

## Core Workflow

1. Inspect the app before editing:
   - Check `pubspec.yaml`, existing database files, `build.yaml`, state management package, target platforms, and tests.
   - Prefer the app's current architecture and naming over the examples in this skill.
2. Add or verify dependencies with package commands instead of hardcoding versions:
   - `dart pub add drift drift_flutter path_provider dev:drift_dev dev:build_runner`
   - Add `provider` or `flutter_riverpod` only when the app already uses it or the user asks for that integration.
3. Create or update the database entry point:
   - Define tables in Dart or `.drift` files.
   - Add the tables to `@DriftDatabase`.
   - Open Flutter databases with `driftDatabase` from `package:drift_flutter/drift_flutter.dart` unless the project needs a custom executor.
4. Keep Drift calls scoped to the database object:
   - Use `database.select(database.todoItems)`, `database.into(database.todoItems)`, `database.update(database.todoItems)`, and `database.delete(database.todoItems)` from widgets, services, and repositories.
   - Use bare `select(todoItems)` only inside `GeneratedDatabase` subclasses or `DatabaseAccessor` classes where the methods and table getters are in scope.
5. Generate code after changing Drift declarations:
   - Run `dart run build_runner build`.
   - Treat generator errors as blockers, not optional cleanup.
6. For schema changes in an existing app, use Drift's guided migration workflow:
   - Configure `drift_dev` databases in `build.yaml`.
   - Run `dart run drift_dev make-migrations` before and after schema changes as needed.
   - Bump `schemaVersion`, write generated step-by-step migrations, and run generated migration tests.
7. Validate before finishing:
   - Run `dart format` on edited Dart files.
   - Run `flutter analyze` or `dart analyze` for the package.
   - Run targeted tests, including generated migration tests when migrations changed.

## Resource Routing

- Read [references/setup.md](references/setup.md) when adding Drift, opening a database, configuring web support, or sharing a database across isolates.
- Read [references/tables.md](references/tables.md) when defining tables, columns, defaults, keys, indexes, constraints, generated columns, or strict tables.
- Read [references/queries.md](references/queries.md) when implementing selects, filters, sorting, pagination, joins, aggregations, subqueries, custom columns, or unions.
- Read [references/writes.md](references/writes.md) when implementing inserts, updates, deletes, upserts, companions, transactions, or batch operations.
- Read [references/streams.md](references/streams.md) when implementing reactive Drift streams, StreamBuilder, StreamProvider, custom select streams, table update listeners, or manual stream invalidation.
- Read [references/migrations.md](references/migrations.md) when `schemaVersion`, existing user data, `build.yaml`, `make-migrations`, generated schema files, or migration tests are involved.
- Read [references/flutter-ui.md](references/flutter-ui.md) when wiring Drift data into Flutter widgets with Provider, Riverpod, StreamBuilder, search, filtering, pagination, or user-facing loading and error states.

## Required API Rules

- Do not call `select(database.table)` as a top-level function from a widget. Use `database.select(database.table)` outside database classes.
- Do not use `watch(...)`, `todoUpdates(...)`, or `notifyTableUpdates(...)`. Use `customSelect(...).watch()`, `tableUpdates(...)`, and `notifyUpdates(...)`.
- Do not call `delete(table).go(id)`. Add a `where` clause and then call `go()`, or use generated table extension helpers if the project already uses them.
- Do not use `batch.updateAll(...)` or pass raw ids to `batch.delete(...)`. Use `batch.update(..., where: ...)`, `batch.delete(...)` with an insertable row, or `batch.deleteWhere(...)`.
- Do not mix Provider and Riverpod APIs. `Provider.of<AppDatabase>(context)` belongs to `provider`; `Provider<AppDatabase>((ref) { ... })` and `AsyncValue.when(...)` belong to Riverpod.
- Do not bump `schemaVersion` without a migration plan for existing databases.
- Do not rely on raw SQLite writes when UI streams must update. Use Drift write APIs or call `notifyUpdates` with explicit `TableUpdate` metadata.

## Fallbacks

- If package downloads are blocked, update source files and leave exact `dart pub add` or `flutter pub add` commands for the user, then state that dependency resolution was not validated.
- If a project cannot run `build_runner`, do not hand-write generated `*.g.dart` files. Fix source declarations and report the generator blocker.
- If migration state is unclear, stop before changing `schemaVersion`; ask for the current released schema history or database files.
- If web support is required but `sqlite3.wasm` and `drift_worker.js` are missing, add the code path and explicitly report the required web assets.

## Validation Checklist

- `pubspec.yaml` contains Drift runtime and generator dependencies.
- Database files have valid `part` directives, table declarations, `@DriftDatabase`, constructor, and `schemaVersion`.
- All query and write examples are scoped to the correct database/accessor context.
- Generated code was rebuilt with `build_runner`.
- Flutter UI examples handle loading, empty, error, and data states without treating `AsyncValue` as a `List`.
- Migrations changed only with generated schema snapshots, step-by-step migration code, and tests.
- `flutter analyze` or `dart analyze` passes for the edited package, or any remaining analyzer failure is reported with the blocker.
