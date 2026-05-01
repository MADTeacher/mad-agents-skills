---
title: Table Definitions
description: Define Drift tables for Dart SQLite and PostgreSQL apps
---

# Table Definitions

Use this reference for table classes, constraints, indexes, defaults, and
backend-specific column choices.

## Basic Table

```dart
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

Register tables on the database:

```dart
@DriftDatabase(tables: [TodoItems, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
```

## Common Column Types

| Dart type | Drift column | Notes |
|---|---|---|
| `int` | `integer()` | SQLite integer |
| `BigInt` | `int64()` | 64-bit integer |
| `String` | `text()` | Text |
| `bool` | `boolean()` | Stored as integer in SQLite |
| `double` | `real()` | Floating point |
| `Uint8List` | `blob()` | Binary data |
| `DateTime` | `dateTime()` | Good for SQLite; avoid for PostgreSQL-specific schemas |

Use `nullable()` to allow null values:

```dart
IntColumn get categoryId => integer().nullable()();
```

## Defaults

SQLite server-side default:

```dart
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
```

Dart-side default:

```dart
BoolColumn get isActive => boolean().clientDefault(() => true)();
```

For PostgreSQL timestamps, prefer `PgTypes` and `now()` from
`drift_postgres` instead of SQLite-oriented `dateTime()` helpers.

## Keys and Constraints

Auto-increment primary key:

```dart
IntColumn get id => integer().autoIncrement()();
```

Custom primary key:

```dart
class Profiles extends Table {
  TextColumn get email => text()();

  @override
  Set<Column<Object>>? get primaryKey => {email};
}
```

Foreign key:

```dart
class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get artistId => integer().references(Artists, #id)();
}
```

Enable SQLite foreign keys when opening the database:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

Unique constraints:

```dart
TextColumn get username => text().unique()();
```

```dart
class Reservations extends Table {
  TextColumn get room => text()();
  DateTimeColumn get onDay => dateTime()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {room, onDay},
      ];
}
```

Check constraint:

```dart
IntColumn get age => integer().check(age.isBiggerOrEqualValue(0))();
```

## Indexes

```dart
@TableIndex(name: 'users_by_name', columns: {#name})
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
```

```dart
@TableIndex(
  name: 'log_entries_by_time',
  columns: {IndexedColumn(#loggedAt, orderBy: OrderingMode.desc)},
)
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
}
```

Partial or expression indexes can use SQL:

```dart
@TableIndex.sql('''
  CREATE INDEX pending_orders ON orders (creation_time)
    WHERE status = 'pending';
''')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get status => text()();
  DateTimeColumn get creationTime => dateTime()();
}
```

## PostgreSQL Types

Import `drift_postgres` for Postgres-specific custom types:

```dart
import 'package:drift_postgres/drift_postgres.dart';

class Users extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
  JsonColumn get settings => customType(PgTypes.jsonb)();
  TimestampColumn get createdAt =>
      customType(PgTypes.timestampWithTimezone).withDefault(now())();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
```

Useful `PgTypes` include `uuid`, `json`, `jsonb`, `textArray`, `date`,
`timestampWithTimezone`, and `timestampNoTimezone`.

## Generated Columns

```dart
class Boxes extends Table {
  IntColumn get length => integer()();
  IntColumn get width => integer()();
  IntColumn get area => integer().generatedAs(length * width, stored: true)();
}
```

## Naming

Custom table name:

```dart
@override
String get tableName => 'product_table';
```

Custom column name:

```dart
BoolColumn get isAdmin => boolean().named('admin')();
```
