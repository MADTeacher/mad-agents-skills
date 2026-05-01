---
title: Migrations
description: Manage Drift schema migrations safely in Flutter apps
---

## Default Rule

Use Drift's guided `make-migrations` workflow for existing apps. Manual migrations are error-prone and should be a fallback only when generated migration tooling cannot be adopted.

Do not bump `schemaVersion` unless the migration path for existing user databases is known.

## Configure Guided Migrations

Add every database entry point to `build.yaml`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          databases:
            app_database: lib/database.dart
          schema_dir: drift_schemas/
          test_dir: test/drift/
```

`databases` is required for `make-migrations`. `schema_dir` and `test_dir` may use the defaults, but declaring them makes the workflow explicit.

## Initial Schema

Before changing a database schema, generate the initial schema snapshot:

```bash
dart run drift_dev make-migrations
```

Commit the generated schema files and migration test scaffolding. They are part of the migration contract.

## Schema Change Workflow

1. Modify table declarations.
2. Bump `schemaVersion`.
3. Run:

```bash
dart run drift_dev make-migrations
```

4. Implement the generated step-by-step migration file.
5. Run generated migration tests.
6. Run `dart run build_runner build`.
7. Run `flutter analyze` and app tests.

## Step-By-Step Migration

After `make-migrations`, import the generated steps file and wire `onUpgrade` to the generated `stepByStep` helper.

```dart
import 'database.steps.dart';

@DriftDatabase(tables: [Categories, TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async => m.createAll(),
      onUpgrade: _schemaUpgrade,
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

extension Migrations on GeneratedDatabase {
  OnUpgrade get _schemaUpgrade => stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(
            schema.todoItems,
            schema.todoItems.priority,
          );
        },
      );
}
```

Keep the `stepByStep` call outside the database class body when possible so migration code does not accidentally reference the current schema instead of generated schema snapshots.

## Common Operations

Add a nullable column or a column with a SQL default:

```dart
from1To2: (m, schema) async {
  await m.addColumn(schema.todoItems, schema.todoItems.priority);
}
```

Create a new table:

```dart
from1To2: (m, schema) async {
  await m.createTable(schema.categories);
}
```

Alter a table when constraints or generated columns require a rebuild:

```dart
from2To3: (m, schema) async {
  await m.alterTable(TableMigration(schema.todoItems));
}
```

Create an index generated from a `@TableIndex` annotation:

```dart
from2To3: (m, schema) async {
  await m.create(schema.todoItemsCompleted);
}
```

Use custom SQL only when Drift's migrator API cannot express the operation:

```dart
from2To3: (m, schema) async {
  await m.customStatement('''
    UPDATE todo_items
    SET priority = 0
    WHERE priority IS NULL
  ''');
}
```

## Data Migrations

Prefer SQL statements over reading through current generated row classes during migration. Drift query builders expect the latest schema, which can be unsafe while upgrading older schemas.

```dart
from1To2: (m, schema) async {
  await m.addColumn(schema.todoItems, schema.todoItems.priority);
  await m.customStatement('''
    UPDATE todo_items
    SET priority = 0
    WHERE priority IS NULL
  ''');
}
```

If Dart transformation is unavoidable, run it only after the columns or tables it needs exist.

## Post-Migration Callbacks

Use `beforeOpen` for pragmas and seed data. Guard seed data with `details.wasCreated` or `details.hadUpgrade`.

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: _schemaUpgrade,
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      if (details.wasCreated) {
        final inboxId = await into(categories).insert(
          CategoriesCompanion.insert(name: 'Inbox'),
        );

        await into(todoItems).insert(
          TodoItemsCompanion.insert(
            title: 'First todo',
            category: Value(inboxId),
          ),
        );
      }
    },
  );
}
```

## Testing Migrations

`make-migrations` generates migration tests. Run them after every schema change:

```bash
dart test test/drift/
```

Migration tests should verify:

- a new database can be created at the latest schema;
- every old schema can migrate to the latest schema;
- important user data survives migration;
- indexes, constraints, and foreign keys match the expected schema.

## Manual Fallback

Use manual migrations only when generated migration files cannot be used. Keep conditions incremental with `from < version`, not only exact equality, so users can migrate across multiple versions.

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(todoItems, todoItems.priority);
      }
      if (from < 3) {
        await m.createTable(categories);
      }
    },
  );
}
```

Report manual migration fallback as a residual risk unless it has equivalent tests.
