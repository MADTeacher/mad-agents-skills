---
name: dart-drift
description: >-
  Build, fix, audit, and migrate Drift persistence in Dart CLI, server-side,
  and non-Flutter desktop apps. Use when adding SQLite with
  package:drift/native.dart, configuring PostgreSQL with drift_postgres and
  package:postgres, writing type-safe tables, queries, writes, streams, and
  migrations, resolving build_runner or drift_dev failures, or validating Dart
  database code with code generation, analysis, tests, and migration checks.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "2.0"
---

# Dart Drift

You are a Dart persistence engineer for non-Flutter apps using Drift.

## Principle 0

Do not write Drift database code from memory. First identify the runtime
backend, read the routed reference for the operation, then verify generated code
with the Dart toolchain. Broken persistence code is worse than no persistence
code because schema and migration mistakes can silently lose data.

## Workflow

1. Inspect the project before changing code: `pubspec.yaml`, existing database
   classes, `build.yaml`, generated parts, tests, migration files, and whether
   the app targets SQLite, PostgreSQL, or both.
2. Choose the backend path:
   - For Dart CLI, server jobs, or native desktop local storage, use SQLite via
     `package:drift/native.dart`.
   - For server-side PostgreSQL, use `drift_postgres` with `package:postgres`
     and enable the Postgres SQL dialect in `build.yaml`.
   - For Flutter UI integration, stop and use the `flutter-drift` skill instead.
3. Read only the reference files needed for the requested task.
4. Implement the smallest safe change using the APIs and caveats from those
   references.
5. Run mandatory validation. If validation cannot run, report the blocker and
   the concrete risk instead of presenting the change as verified.

## Resource Routing

| Task | Read or run | Why |
|---|---|---|
| Add Drift to a Dart app, choose dependencies, open SQLite/Postgres connections, or fix build setup | `references/setup.md` | Current non-Flutter setup and imports |
| Define tables, constraints, indexes, defaults, or PostgreSQL custom types | `references/tables.md` | Schema APIs and backend-specific column caveats |
| Write SELECT, WHERE, JOIN, aggregate, subquery, or custom-column code | `references/queries.md` | Query-builder patterns that compile |
| Insert, update, delete, upsert, batch, or transaction code | `references/writes.md` | Safe write APIs and conflict handling |
| Add or repair reactive streams, custom SQL streams, update notifications, or table update listeners | `references/streams.md` | Drift stream APIs without Flutter UI assumptions |
| Add or change schema migrations | `references/migrations.md` | Guided migrations, generated tests, and migration safety rules |
| Configure PostgreSQL, pooling, custom types, or Postgres-specific functions | `references/postgres.md` | `drift_postgres` and `package:postgres` source of truth |
| Edit this skill or its examples | `scripts/verify-examples.sh` | Deterministic smoke check for the documented patterns |

## Mandatory Validation

- After dependency changes, run `dart pub get`.
- After changing Drift tables, database classes, DAOs, SQL files, or generated
  parts, run `dart run build_runner build` and `dart analyze`.
- After changing behavior, run the narrowest relevant `dart test` target. If no
  tests exist, add or describe a focused smoke test for the database operation.
- After migration changes, run `dart run drift_dev make-migrations` and the
  generated migration tests from the configured `test_dir`.
- After editing this skill, references, or reusable examples, run
  `dart-drift/scripts/verify-examples.sh`.

## Constraints

- Keep this skill scoped to Dart CLI, server-side, and non-Flutter desktop apps.
  Do not add `StreamBuilder`, Riverpod, Provider, `drift_flutter`, or
  Flutter-specific storage patterns here.
- Prefer `dart pub add ...` for new dependencies. Only hardcode versions when
  matching an existing repository policy.
- Do not use deprecated PostgreSQL examples based on `HostEndpoint`,
  `PgEndpoint`, `postgres_pool.dart`, `postgresUuid()`, `postgresJson()`,
  `PostgresTypes`, or `gen_random_uuid`.
- For PostgreSQL, avoid SQLite-only helpers such as `currentDateAndTime` and
  most `dateTime()` convenience APIs. Use `PgTypes.date`,
  `PgTypes.timestampWithTimezone`, `PgTypes.timestampNoTimezone`, and `now()`.
- Do not replace code generation or migration validation with manual reasoning
  unless the user explicitly waives the risk.

## Fallback

If the requested repository lacks enough context to choose a backend, ask
whether the target is SQLite or PostgreSQL. If network, database, or toolchain
access prevents validation, finish with the exact command that failed and the
remaining risk.
