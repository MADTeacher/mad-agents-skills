---
title: Queries
description: SELECT queries in Drift
---

# Queries

Use this reference for Drift SELECTs, filters, ordering, joins, aggregates, and
custom SQL reads.

## Basic Select

```dart
final allTodos = await db.select(db.todoItems).get();
final todoStream = db.select(db.todoItems).watch();
```

## Where

```dart
final completedTodos = await (db.select(db.todoItems)
      ..where((t) => t.isCompleted.equals(true)))
    .get();
```

Combine expressions with `&` and `|`:

```dart
final importantOpenTodos = await (db.select(db.todoItems)
      ..where(
        (t) => t.isCompleted.equals(false) & t.priority.isBiggerThanValue(3),
      ))
    .get();
```

Common operators:

- `equals(value)`
- `isBiggerThanValue(value)`
- `isBiggerOrEqualValue(value)`
- `isSmallerThanValue(value)`
- `isSmallerOrEqualValue(value)`
- `like(pattern)`
- `contains(value)` for text contains
- `isNull()` and `isNotNull()`

## Limit and Order

```dart
final page = await (db.select(db.todoItems)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(20, offset: 40))
    .get();
```

## Single Row

```dart
final todo = await (db.select(db.todoItems)
      ..where((t) => t.id.equals(id)))
    .getSingle();
```

```dart
final maybeTodo = await (db.select(db.todoItems)
      ..where((t) => t.id.equals(id)))
    .getSingleOrNull();
```

Use `watchSingle()` and `watchSingleOrNull()` for reactive single-row streams.

## Mapping Rows

```dart
final titles = await (db.select(db.todoItems)
      ..where((t) => t.title.length.isBiggerOrEqualValue(10)))
    .map((row) => row.title)
    .get();
```

## Joins

```dart
class TodoWithCategory {
  TodoWithCategory({required this.todo, required this.category});

  final TodoItem todo;
  final Category? category;
}

final rows = await db.select(db.todoItems).join([
  leftOuterJoin(
    db.categories,
    db.categories.id.equalsExp(db.todoItems.categoryId),
  ),
]).map((row) {
  return TodoWithCategory(
    todo: row.readTable(db.todoItems),
    category: row.readTableOrNull(db.categories),
  );
}).get();
```

For self-joins, alias the table:

```dart
final otherTodos = alias(db.todoItems, 'other_todos');

final related = await db.select(otherTodos).join([
  innerJoin(
    db.todoItems,
    db.todoItems.categoryId.equalsExp(otherTodos.categoryId),
    useColumns: false,
  ),
]).map((row) => row.readTable(otherTodos)).get();
```

## Aggregates

Count all rows:

```dart
final countExp = db.todoItems.id.count();

final count = await (db.selectOnly(db.todoItems)..addColumns([countExp]))
    .map((row) => row.read(countExp) ?? 0)
    .getSingle();
```

Group by a column:

```dart
final category = db.todoItems.categoryId;
final countExp = db.todoItems.id.count();

final counts = await (db.selectOnly(db.todoItems)
      ..addColumns([category, countExp])
      ..groupBy([category]))
    .map((row) {
  return (
    categoryId: row.read(category),
    count: row.read(countExp) ?? 0,
  );
}).get();
```

Average:

```dart
final avgExp = db.todoItems.priority.avg();

final averagePriority = await (db.selectOnly(db.todoItems)..addColumns([avgExp]))
    .map((row) => row.read(avgExp))
    .getSingle();
```

## Custom Columns

```dart
final isImportant = db.todoItems.title.like('%important%');

final rows = await (db.select(db.todoItems)..addColumns([isImportant]))
    .map((row) {
  return (
    todo: row.readTable(db.todoItems),
    important: row.read(isImportant) ?? false,
  );
}).get();
```

## Exists

```dart
final existsExp = existsQuery(
  db.select(db.todoItems)..where((t) => t.id.equals(id)),
);

final exists = await (db.selectOnly(db.todoItems)..addColumns([existsExp]))
    .map((row) => row.read(existsExp) ?? false)
    .getSingle();
```

## Custom SQL Reads

Use `customSelect` when the query builder does not expose a database-specific
feature. Always pass variables separately and declare `readsFrom` for streams:

```dart
final rows = await db.customSelect(
  'SELECT * FROM todo_items WHERE title LIKE ?',
  variables: [Variable.withString('%drift%')],
  readsFrom: {db.todoItems},
).get();
```

For PostgreSQL-specific SQL, prefer `customSelect` over inventing unsupported
expression APIs.
