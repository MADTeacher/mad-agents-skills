---
title: Setup
description: Set up Drift for non-Flutter Dart applications
---

# Setup

Use this reference when adding Drift to Dart CLI tools, server processes, or
native desktop apps. For Flutter apps, use the `flutter-drift` skill.

## Dependencies

Prefer commands so the project receives current compatible versions:

```bash
dart pub add drift sqlite3
dart pub add dev:drift_dev dev:build_runner
```

For PostgreSQL support, also add:

```bash
dart pub add drift_postgres postgres
```

If a project requires manual `pubspec.yaml` edits, keep `drift` and
`drift_dev` on the same minor release when possible and follow the existing
repository version policy.

## Code Generation

Every generated database file needs a `part` directive and a build step:

```dart
import 'package:drift/drift.dart';

part 'database.g.dart';
```

```bash
dart run build_runner build
```

Use `dart run build_runner watch` only during interactive development.

## SQLite Database

Use `package:drift/native.dart` for non-Flutter native Dart apps:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return NativeDatabase.createInBackground(File('db.sqlite'));
}
```

Do not open SQLite manually with `sqlite3.open()` before passing it to Drift
unless the project has a specific reason to manage the low-level connection.

## PostgreSQL Database

Configure the SQL dialect before generating code:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialects:
              - sqlite
              - postgres
```

Use `pg.Endpoint` from `package:postgres`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

AppDatabase openPostgresDatabase() {
  return AppDatabase(
    PgDatabase(
      endpoint: pg.Endpoint(
        host: 'localhost',
        database: 'mydb',
        username: 'user',
        password: 'password',
      ),
      settings: pg.ConnectionSettings(
        sslMode: pg.SslMode.disable,
      ),
    ),
  );
}
```

For production services, prefer a pool. Close both the Drift database and the
pool during shutdown:

```dart
final pool = pg.Pool.withEndpoints(
  [
    pg.Endpoint(
      host: 'localhost',
      database: 'mydb',
      username: 'user',
      password: 'password',
    ),
  ],
  settings: pg.PoolSettings(maxConnectionCount: 10),
);

final db = AppDatabase(PgDatabase.opened(pool));

Future<void> shutdown() async {
  await db.close();
  await pool.close();
}
```

## Tests

Use an in-memory SQLite database for fast unit tests:

```dart
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

PostgreSQL behavior needs integration tests against a real PostgreSQL database.
Do not claim PostgreSQL behavior is verified from an in-memory SQLite test.
