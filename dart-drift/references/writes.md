---
title: Insert, Update, Delete
description: Write operations in Drift
---

# Writes

Use this reference for inserts, updates, deletes, upserts, batches, and
transactions.

## Insert

```dart
final id = await db.into(db.todoItems).insert(
      TodoItemsCompanion.insert(
        title: 'First todo',
        content: const Value('Some description'),
      ),
    );
```

Columns with default values, nullable columns, and auto-increment columns can be
omitted from `Companion.insert`.

Insert and read generated defaults:

```dart
final row = await db.into(db.todoItems).insertReturning(
      TodoItemsCompanion.insert(title: 'A todo entry'),
    );
```

Bulk insert:

```dart
await db.batch((batch) {
  batch.insertAll(db.todoItems, [
    TodoItemsCompanion.insert(title: 'First'),
    TodoItemsCompanion.insert(title: 'Second'),
  ]);
});
```

## Update

Partial update:

```dart
await (db.update(db.todoItems)..where((t) => t.id.equals(id))).write(
  const TodoItemsCompanion(
    title: Value('Updated title'),
    isCompleted: Value(true),
  ),
);
```

Replace a full row by primary key:

```dart
await db.update(db.todoItems).replace(
      TodoItem(
        id: id,
        title: 'Updated title',
        content: 'Updated content',
        isCompleted: true,
        createdAt: existing.createdAt,
      ),
    );
```

Update with SQL expressions:

```dart
await db.update(db.users).write(
      UsersCompanion.custom(
        name: db.users.name.lower(),
      ),
    );
```

## Delete

```dart
await (db.delete(db.todoItems)..where((t) => t.id.equals(id))).go();
```

Delete a range:

```dart
await (db.delete(db.todoItems)..where((t) => t.id.isSmallerThanValue(10))).go();
```

Delete all rows only when that is explicitly intended:

```dart
await db.delete(db.todoItems).go();
```

## Companions and Value

Use data classes for complete rows and companions for inserts or partial
updates.

```dart
final companion = TodoItemsCompanion(
  title: const Value('New title'),
  content: Value.absent(),
);
```

- `Value(value)` sets the column to the value, including `null` for nullable columns.
- `Value.absent()` leaves the column unchanged in updates.
- `const Value(value)` is fine for compile-time constant values.

## Upsert

For primary-key upserts:

```dart
Future<int> createOrUpdateUser(User user) {
  return db.into(db.users).insertOnConflictUpdate(user);
}
```

For custom conflict behavior:

```dart
class Words extends Table {
  TextColumn get word => text()();
  IntColumn get usages => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>>? get primaryKey => {word};
}

Future<void> trackWord(String word) {
  return db.into(db.words).insert(
        WordsCompanion.insert(word: word),
        onConflict: DoUpdate(
          (old) => WordsCompanion.custom(
            usages: old.usages + const Constant(1),
          ),
        ),
      );
}
```

For unique constraints that are not the primary key, provide `target`:

```dart
await db.into(db.matchResults).insert(
      data,
      onConflict: DoUpdate(
        (old) => data,
        target: [db.matchResults.teamA, db.matchResults.teamB],
      ),
    );
```

## Transactions

```dart
final id = await db.transaction(() async {
  final categoryId = await db.into(db.categories).insert(
        CategoriesCompanion.insert(name: 'Work'),
      );

  return db.into(db.todoItems).insert(
        TodoItemsCompanion.insert(
          title: 'Write migration tests',
          categoryId: Value(categoryId),
        ),
      );
});
```

Drift rolls back the transaction if the callback throws.

## Custom Writes

Use `customUpdate`, `customInsert`, or `customStatement` for SQL not covered by
the query builder. Declare affected tables so streams update:

```dart
await db.customUpdate(
  'UPDATE todo_items SET is_completed = ? WHERE id = ?',
  variables: [
    Variable.withBool(true),
    Variable.withInt(id),
  ],
  updates: {db.todoItems},
  updateKind: UpdateKind.update,
);
```

## Safety Rule

Always add a `where` clause to updates and deletes unless the request explicitly
requires changing every row.
