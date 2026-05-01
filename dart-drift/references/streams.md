---
title: Stream Queries
description: Reactive stream queries and update notifications in Drift
---

# Streams

Use this reference for Drift streams in Dart services, CLI tools, and native
desktop apps. Do not add Flutter `StreamBuilder`, Provider, or Riverpod examples
to this skill.

## Basic Watch

```dart
Stream<List<TodoItem>> watchTodos(AppDatabase db) {
  return db.select(db.todoItems).watch();
}
```

Filtered stream:

```dart
Stream<List<TodoItem>> watchOpenTodos(AppDatabase db) {
  return (db.select(db.todoItems)
        ..where((t) => t.isCompleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
}
```

Single-row stream:

```dart
Stream<TodoItem> watchTodo(AppDatabase db, int id) {
  return (db.select(db.todoItems)..where((t) => t.id.equals(id))).watchSingle();
}
```

Nullable single-row stream:

```dart
Stream<TodoItem?> watchMaybeTodo(AppDatabase db, int id) {
  return (db.select(db.todoItems)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
}
```

## Watch Joins

```dart
class TodoWithCategory {
  TodoWithCategory({required this.todo, required this.category});

  final TodoItem todo;
  final Category? category;
}

Stream<List<TodoWithCategory>> watchTodosWithCategories(AppDatabase db) {
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
      db.categories,
      db.categories.id.equalsExp(db.todoItems.categoryId),
    ),
  ]);

  return query.map((row) {
    return TodoWithCategory(
      todo: row.readTable(db.todoItems),
      category: row.readTableOrNull(db.categories),
    );
  }).watch();
}
```

## Custom SQL Streams

For custom SQL, use `customSelect(...).watch()` and declare `readsFrom`.
Without `readsFrom`, Drift cannot know which table changes should re-run the
stream.

```dart
Stream<List<QueryRow>> watchCompletedRows(AppDatabase db) {
  return db.customSelect(
    '''
    SELECT * FROM todo_items
    WHERE is_completed = ?
    ORDER BY created_at DESC
    ''',
    variables: [Variable.withBool(true)],
    readsFrom: {db.todoItems},
  ).watch();
}
```

If a generated table mapper is available, map `QueryRow.data`:

```dart
Stream<List<TodoItem>> watchCompletedTodos(AppDatabase db) {
  return watchCompletedRows(db).map(
    (rows) => rows.map((row) => db.todoItems.map(row.data)).toList(),
  );
}
```

## Custom Writes and Stream Updates

When using custom writes, declare affected tables:

```dart
Future<void> markDone(AppDatabase db, int id) {
  return db.customUpdate(
    'UPDATE todo_items SET is_completed = ? WHERE id = ?',
    variables: [
      Variable.withBool(true),
      Variable.withInt(id),
    ],
    updates: {db.todoItems},
    updateKind: UpdateKind.update,
  );
}
```

For changes made outside Drift, manually notify the stream query manager:

```dart
void notifyExternalTodoUpdate(AppDatabase db) {
  db.notifyUpdates({
    TableUpdate.onTable(db.todoItems, kind: UpdateKind.update),
  });
}
```

## Table Update Events

Listen to raw table update events with `tableUpdates`:

```dart
Stream<Set<TableUpdate>> todoUpdateEvents(AppDatabase db) {
  return db.tableUpdates(TableUpdateQuery.onTable(db.todoItems));
}
```

```dart
final subscription = todoUpdateEvents(db).listen((updates) {
  for (final update in updates) {
    print('${update.table} changed: ${update.kind}');
  }
});
```

Cancel long-lived subscriptions during shutdown:

```dart
await subscription.cancel();
```

## Operational Notes

- Streams re-run when watched tables change, not only when matching rows change.
- Writes made outside Drift do not update streams until `notifyUpdates` is
  called.
- Keep stream queries fast and indexed. A stream query may run many times during
  one process lifetime.
- Use standard Dart stream transforms unless the project already depends on a
  stream utility package.
