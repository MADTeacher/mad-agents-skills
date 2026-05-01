---
title: Table Definitions
description: Define Drift tables, columns, keys, indexes, and constraints
---

## Table Style

Use generated Dart table classes for ordinary Flutter apps. Keep the schema close to the domain model, but remember that Drift data classes are generated from the table definitions.

```dart
@DataClassName('TodoCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
}

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get content => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get category =>
      integer().nullable().references(Categories, #id)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
```

Add every table to the database annotation:

```dart
@DriftDatabase(tables: [Categories, TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
```

## Column Types

| Dart value | Drift column builder | SQLite storage |
| --- | --- | --- |
| `int` | `integer()` | `INTEGER` |
| `BigInt` | `int64()` | `INTEGER` |
| `String` | `text()` | `TEXT` |
| `bool` | `boolean()` | `INTEGER` |
| `double` | `real()` | `REAL` |
| `Uint8List` | `blob()` | `BLOB` |
| `DateTime` | `dateTime()` | `INTEGER` or `TEXT` |

Use `nullable()` for optional values:

```dart
TextColumn get content => text().nullable()();
```

Use SQL defaults for values that should exist even when inserts omit them:

```dart
BoolColumn get isCompleted =>
    boolean().withDefault(const Constant(false))();
DateTimeColumn get createdAt =>
    dateTime().withDefault(currentDateAndTime)();
```

Use client defaults only when the value must be computed in Dart:

```dart
TextColumn get clientId => text().clientDefault(() => const Uuid().v4())();
```

## Keys And References

Use `autoIncrement()` for ordinary integer primary keys:

```dart
IntColumn get id => integer().autoIncrement()();
```

Use a custom primary key only when the domain really owns the identifier:

```dart
class Profiles extends Table {
  TextColumn get email => text()();

  @override
  Set<Column<Object>> get primaryKey => {email};
}
```

Reference another table with `references`:

```dart
class TodoItems extends Table {
  IntColumn get category =>
      integer().nullable().references(Categories, #id)();
}
```

Enable SQLite foreign keys when the app relies on enforcement:

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

## Unique Constraints

Use `unique()` for a single column:

```dart
TextColumn get username => text().unique()();
```

Use `uniqueKeys` for multi-column uniqueness:

```dart
class Reservations extends Table {
  TextColumn get room => text()();
  DateTimeColumn get onDay => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {room, onDay},
      ];
}
```

## Indexes

Index columns that are frequently filtered, sorted, or joined.

```dart
@TableIndex(name: 'todo_items_completed', columns: {#isCompleted})
@TableIndex(
  name: 'todo_items_created_at',
  columns: {IndexedColumn(#createdAt, orderBy: OrderingMode.desc)},
)
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
```

Use custom SQL indexes for partial indexes:

```dart
@TableIndex.sql('''
  CREATE INDEX pending_todos ON todo_items (created_at)
    WHERE is_completed = 0;
''')
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
```

## Constraints

Use length constraints for user-facing text:

```dart
TextColumn get title => text().withLength(min: 1, max: 120)();
```

Use check constraints for numeric domain rules:

```dart
IntColumn get priority => integer().check(
      priority.isBiggerOrEqualValue(0) & priority.isSmallerOrEqualValue(5),
    )();
```

Use generated columns when SQLite should compute derived data:

```dart
class Boxes extends Table {
  IntColumn get length => integer()();
  IntColumn get width => integer()();
  IntColumn get area => integer().generatedAs(length * width)();
}
```

## Table Mixins

Use mixins for repeated columns, but keep them simple.

```dart
mixin TimestampColumns on Table {
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Notes extends Table with TimestampColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get body => text()();
}
```

## Strict Tables

Use strict tables only when the target SQLite runtime supports them and the app benefits from stricter typing.

```dart
class Preferences extends Table {
  TextColumn get key => text()();
  AnyColumn get value => sqliteAny().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};

  @override
  bool get isStrict => true;
}
```
