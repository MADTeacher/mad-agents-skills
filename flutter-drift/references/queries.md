---
title: Queries
description: Write type-safe Drift SELECT queries from Flutter code
---

## Scope Rule

From widgets, repositories, or services, call query builders on the database instance:

```dart
final todos = await database.select(database.todoItems).get();
```

Use bare `select(todoItems)` only inside `AppDatabase` or a `DatabaseAccessor` where Drift exposes the table and query methods directly.

## Basic Select

Get all rows:

```dart
final allTodos = await database.select(database.todoItems).get();
```

Watch all rows:

```dart
final allTodosStream = database.select(database.todoItems).watch();
```

## Where Clauses

Use cascades on the statement, then call `get()` or `watch()` on the completed statement.

```dart
final completedTodos = await (database.select(database.todoItems)
      ..where((t) => t.isCompleted.equals(true)))
    .get();
```

Combine expressions with `&` and `|`:

```dart
final importantTodos = await (database.select(database.todoItems)
      ..where(
        (t) => t.isCompleted.equals(false) & t.priority.isBiggerThanValue(2),
      ))
    .get();
```

Common filters:

- `equals(value)`
- `isBiggerThanValue(value)`
- `isSmallerThanValue(value)`
- `isBiggerOrEqualValue(value)`
- `isSmallerOrEqualValue(value)`
- `like(pattern)`
- `contains(value)`
- `isNull()`
- `isNotNull()`

## Limit, Offset, And Order

```dart
final page = await (database.select(database.todoItems)
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(20, offset: 40))
    .get();
```

## Single Row

Use `getSingle()` only when the query must return exactly one row.

```dart
final todo = await (database.select(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .getSingle();
```

Use `getSingleOrNull()` for optional rows:

```dart
final todo = await (database.select(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .getSingleOrNull();
```

Watch a single row:

```dart
final todoStream = (database.select(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .watchSingleOrNull();
```

## Mapping

Map after the statement has been configured:

```dart
final titles = await (database.select(database.todoItems)
      ..where((t) => t.title.contains(searchTerm)))
    .map((row) => row.title)
    .get();
```

## Joins

Use joins when UI needs related rows in one query.

```dart
class TodoWithCategory {
  TodoWithCategory({required this.todo, required this.category});

  final TodoItem todo;
  final TodoCategory? category;
}

final query = database.select(database.todoItems).join([
  leftOuterJoin(
    database.categories,
    database.categories.id.equalsExp(database.todoItems.category),
  ),
]);

final rows = await query
    .map(
      (row) => TodoWithCategory(
        todo: row.readTable(database.todoItems),
        category: row.readTableOrNull(database.categories),
      ),
    )
    .get();
```

Use `useColumns: false` when a joined table is needed only for filtering:

```dart
final joined = database.select(database.todoItems).join([
  innerJoin(
    database.categories,
    database.categories.id.equalsExp(database.todoItems.category),
    useColumns: false,
  ),
]);

joined.where(database.categories.name.equals('Work'));

final workTodos = await joined
    .map((row) => row.readTable(database.todoItems))
    .get();
```

## Self Joins

Alias tables when joining a table to itself:

```dart
final otherTodos = alias(database.todoItems, 'other');

final query = database.select(otherTodos).join([
  innerJoin(
    database.todoItems,
    database.todoItems.category.equalsExp(otherTodos.category),
    useColumns: false,
  ),
]);

query.where(database.todoItems.title.contains('important'));

final relatedTodos = await query.map((row) => row.readTable(otherTodos)).get();
```

## Aggregations

Use `selectOnly` when selecting computed columns.

```dart
final countExpression = database.todoItems.id.count();

final count = await (database.selectOnly(database.todoItems)
      ..addColumns([countExpression]))
    .map((row) => row.read(countExpression) ?? 0)
    .getSingle();
```

Group by a related table:

```dart
final countExpression = database.todoItems.id.count();
final query = database.select(database.categories).join([
  leftOuterJoin(
    database.todoItems,
    database.todoItems.category.equalsExp(database.categories.id),
    useColumns: false,
  ),
])
  ..addColumns([countExpression])
  ..groupBy([database.categories.id]);

final counts = await query
    .map(
      (row) => (
        category: row.readTable(database.categories),
        count: row.read(countExpression) ?? 0,
      ),
    )
    .get();
```

## Subqueries

Use subqueries for reusable query fragments:

```dart
final recent = Subquery(
  database.select(database.todoItems)
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ..limit(10),
  'recent_todos',
);

final rows = await database.select(recent).get();
```

## Custom Columns

Add computed expressions with `addColumns`:

```dart
final isImportant = database.todoItems.priority.isBiggerThanValue(2);

final rows = await database.select(database.todoItems)
    .addColumns([isImportant])
    .map(
      (row) => (
        todo: row.readTable(database.todoItems),
        important: row.read(isImportant) ?? false,
      ),
    )
    .get();
```

## Exists

```dart
final hasTodosExpression = existsQuery(database.select(database.todoItems));

final hasTodos = await (database.selectOnly(database.todoItems)
      ..addColumns([hasTodosExpression]))
    .map((row) => row.read(hasTodosExpression) ?? false)
    .getSingle();
```

## Union

```dart
final completed = database.select(database.todoItems)
  ..where((t) => t.isCompleted.equals(true));

final highPriority = database.select(database.todoItems)
  ..where((t) => t.priority.isBiggerThanValue(2));

final rows = await completed.unionAll(highPriority).get();
```
