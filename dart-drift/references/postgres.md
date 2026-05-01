---
title: PostgreSQL
description: Use Drift with PostgreSQL in non-Flutter Dart apps
---

# PostgreSQL

Use this reference for `drift_postgres`, `package:postgres`, PostgreSQL custom
types, pooling, and Postgres-specific caveats.

## Dependencies

Prefer commands:

```bash
dart pub add drift drift_postgres postgres
dart pub add dev:drift_dev dev:build_runner
```

Enable PostgreSQL SQL generation in `build.yaml`:

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

Remove `sqlite` from the dialect list only when the database will never target
SQLite.

## Basic Database

```dart
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'postgres_database.g.dart';

class Users extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
  JsonColumn get settings => customType(PgTypes.jsonb)();
  TimestampColumn get createdAt =>
      customType(PgTypes.timestampWithTimezone).withDefault(now())();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
```

## Single Connection

```dart
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
        connectTimeout: const Duration(seconds: 10),
        queryTimeout: const Duration(seconds: 30),
        applicationName: 'my-dart-service',
      ),
    ),
  );
}
```

Use `pg.SslMode.verifyFull` or another production-appropriate SSL mode for
public network connections.

## Connection Pooling

Use `pg.Pool.withEndpoints` for services:

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
  settings: pg.PoolSettings(
    maxConnectionCount: 20,
    maxConnectionAge: const Duration(hours: 1),
    applicationName: 'my-dart-service',
  ),
);

final db = AppDatabase(PgDatabase.opened(pool));
```

Close both layers:

```dart
await db.close();
await pool.close();
```

Do not use old examples based on `postgres_pool.dart`, `PgPool`, or
`PgEndpoint`.

## Custom Types

`drift_postgres` exposes `PgTypes`:

```dart
class Events extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  JsonColumn get payload => customType(PgTypes.jsonb)();
  Column<List<String>> get tags => customType(PgTypes.textArray)();
  PgDateColumn get eventDate => customType(PgTypes.date)();
  TimestampColumn get createdAt =>
      customType(PgTypes.timestampWithTimezone).withDefault(now())();
}
```

Common types:

- `PgTypes.uuid` maps to `UuidValue`
- `PgTypes.json` and `PgTypes.jsonb` map to JSON-like Dart objects
- `PgTypes.textArray` maps to `List<String>`
- `PgTypes.date` maps to `PgDate`
- `PgTypes.timestampWithTimezone` and `PgTypes.timestampNoTimezone` map to
  `PgDateTime`

## PostgreSQL Functions

Use exported helpers when available:

```dart
UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
TimestampColumn get createdAt =>
    customType(PgTypes.timestampWithTimezone).withDefault(now())();
```

For PostgreSQL functions that `drift_postgres` does not wrap, use
`FunctionCallExpression` or `customSelect`.

## Queries

Array contains:

```dart
final tagged = await (db.select(db.events)
      ..where((event) => event.tags.contains('dart')))
    .get();
```

JSON operators are often clearest as custom SQL:

```dart
final rows = await db.customSelect(
  "SELECT * FROM events WHERE payload ->> 'kind' = ?",
  variables: [Variable.withString('created')],
  readsFrom: {db.events},
).get();
```

Full text search is also a custom SQL use case:

```dart
final rows = await db.customSelect(
  '''
  SELECT * FROM posts
  WHERE to_tsvector('english', content) @@ plainto_tsquery('english', ?)
  ''',
  variables: [Variable.withString(searchTerm)],
  readsFrom: {db.posts},
).get();
```

## Indexes

Use raw SQL indexes for PostgreSQL-specific index types:

```dart
@TableIndex.sql('''
  CREATE INDEX events_payload_kind_idx ON events ((payload ->> 'kind'));
''')
class Events extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  JsonColumn get payload => customType(PgTypes.jsonb)();
}
```

```dart
@TableIndex.sql('''
  CREATE INDEX events_tags_gin_idx ON events USING GIN (tags);
''')
class Events extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  Column<List<String>> get tags => customType(PgTypes.textArray)();
}
```

## Caveats

- PostgreSQL support is stable, but Drift has more SQLite-first helper APIs than
  PostgreSQL-specific wrappers.
- Avoid SQLite-oriented `currentDateAndTime` and most `dateTime()` helper APIs
  in PostgreSQL schemas.
- Use real PostgreSQL integration tests for Postgres behavior. SQLite in-memory
  tests only validate shared query-builder behavior.
- For complex production migrations, consider PostgreSQL-native migration tools
  and keep Drift focused on typed access after the migration.
