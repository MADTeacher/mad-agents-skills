---
title: Insert, Update, Delete
description: Implement Drift writes, companions, transactions, and batches
---

## Scope Rule

From Flutter code outside the database class, call write builders on the database instance:

```dart
await database.into(database.todoItems).insert(
  TodoItemsCompanion.insert(title: title),
);
```

Use bare `into(todoItems)`, `update(todoItems)`, and `delete(todoItems)` only inside `GeneratedDatabase` or `DatabaseAccessor` code.

## Insert

Insert a row with required values:

```dart
final id = await database.into(database.todoItems).insert(
  TodoItemsCompanion.insert(
    title: 'First todo',
    content: const Value('Some description'),
  ),
);
```

Omit nullable columns and columns with SQL defaults:

```dart
final id = await database.into(database.todoItems).insert(
  TodoItemsCompanion.insert(title: 'First todo'),
);
```

Insert multiple rows in a batch:

```dart
await database.batch((batch) {
  batch.insertAll(database.todoItems, [
    TodoItemsCompanion.insert(title: 'First entry'),
    TodoItemsCompanion.insert(
      title: 'Another entry',
      priority: const Value(2),
    ),
  ]);
});
```

## Upsert

Use `insertOnConflictUpdate` when the row has a primary key or unique key that should be replaced on conflict.

```dart
await database.into(database.todoItems).insertOnConflictUpdate(
  TodoItemsCompanion.insert(
    id: const Value(1),
    title: 'Updated title',
  ),
);
```

For custom conflict handling, pass a `DoUpdate` clause with an update companion:

```dart
await database.into(database.todoItems).insert(
  TodoItemsCompanion.insert(
    id: const Value(1),
    title: 'Important',
  ),
  onConflict: DoUpdate(
    (old) => const TodoItemsCompanion(
      priority: Value(5),
    ),
  ),
);
```

Use `insertReturning` only when the target SQLite runtime supports `RETURNING`.

```dart
final row = await database.into(database.todoItems).insertReturning(
  TodoItemsCompanion.insert(title: 'A todo entry'),
);
```

## Update

Always add a `where` clause unless the intent is truly to update every row.

```dart
await (database.update(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .write(
  const TodoItemsCompanion(
    title: Value('Updated title'),
  ),
);
```

Update multiple columns with a companion:

```dart
await (database.update(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .write(
  const TodoItemsCompanion(
    title: Value('Updated title'),
    isCompleted: Value(true),
  ),
);
```

Use `replace` only when you have a complete generated data row:

```dart
await database.update(database.todoItems).replace(
  todo.copyWith(isCompleted: true),
);
```

Use custom expressions for SQL-side updates:

```dart
await (database.update(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .write(
  TodoItemsCompanion.custom(
    priority: database.todoItems.priority + const Constant(1),
  ),
);
```

## Delete

Delete matching rows with `where` and `go()`:

```dart
await (database.delete(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .go();
```

Delete multiple rows:

```dart
await (database.delete(database.todoItems)
      ..where((t) => t.isCompleted.equals(true)))
    .go();
```

Delete all rows only when that is explicitly intended:

```dart
await database.delete(database.todoItems).go();
```

Do not use `delete(table).go(id)`. That is not Drift's delete API.

## Companions And Value

Generated data classes represent full rows. Companions represent partial writes.

```dart
final companion = TodoItemsCompanion(
  title: const Value('Title'),
  content: const Value('Content'),
  priority: const Value(2),
  category: const Value.absent(),
);
```

For nullable fields, distinguish setting `NULL` from leaving a column unchanged:

```dart
const TodoItemsCompanion(
  category: Value<int?>(null),
);

const TodoItemsCompanion(
  category: Value.absent(),
);
```

## Transactions

Use transactions for multi-step writes that must succeed or fail together.

```dart
final categoryId = await database.transaction(() async {
  final id = await database.into(database.categories).insert(
    CategoriesCompanion.insert(name: 'Work'),
  );

  await database.into(database.todoItems).insert(
    TodoItemsCompanion.insert(
      title: 'First work todo',
      category: Value(id),
    ),
  );

  return id;
});
```

Errors thrown inside the callback roll the transaction back.

## Batch Operations

Batches are useful for many similar writes.

```dart
await database.batch((batch) {
  batch.insertAll(database.todoItems, [
    TodoItemsCompanion.insert(title: 'First'),
    TodoItemsCompanion.insert(title: 'Second'),
  ]);

  batch.update(
    database.todoItems,
    const TodoItemsCompanion(priority: Value(1)),
    where: (t) => t.isCompleted.equals(false),
  );

  batch.deleteWhere(
    database.todoItems,
    (t) => t.isCompleted.equals(true),
  );
});
```

Use `batch.delete(table, row)` only when you have an insertable row with the primary key. Use `batch.deleteWhere` for predicates.

## Write Safety

Avoid broad updates and deletes in UI actions:

```dart
// Bad: updates every todo.
await database.update(database.todoItems).write(
  const TodoItemsCompanion(isCompleted: Value(true)),
);

// Good: updates one row.
await (database.update(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .write(
  const TodoItemsCompanion(isCompleted: Value(true)),
);
```
