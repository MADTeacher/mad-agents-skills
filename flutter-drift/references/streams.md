---
title: Stream Queries
description: Use Drift reactive query streams in Flutter
---

## Basic Streams

Every runnable Drift select can become a stream.

```dart
final todosStream = database.select(database.todoItems).watch();
```

Flutter can consume the stream with `StreamBuilder`:

```dart
StreamBuilder<List<TodoItem>>(
  stream: database.select(database.todoItems).watch(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    final todos = snapshot.data ?? [];
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(todos[index].title));
      },
    );
  },
)
```

Drift streams emit an up-to-date value after listening. You usually do not need to call `get()` before `watch()`.

## Single Row Streams

Use `watchSingle()` only when exactly one row must exist:

```dart
final todoStream = (database.select(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .watchSingle();
```

Use `watchSingleOrNull()` when the row may not exist:

```dart
final todoStream = (database.select(database.todoItems)
      ..where((t) => t.id.equals(id)))
    .watchSingleOrNull();
```

## Filtered Streams

```dart
final activeTodos = (database.select(database.todoItems)
      ..where((t) => t.isCompleted.equals(false)))
    .watch();
```

```dart
final sortedTodos = (database.select(database.todoItems)
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
      ]))
    .watch();
```

## StreamBuilder With State

```dart
class TodoList extends StatelessWidget {
  const TodoList({required this.database, super.key});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TodoItem>>(
      stream: (database.select(database.todoItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final todos = snapshot.data ?? [];
        if (todos.isEmpty) {
          return const Center(child: Text('No todos yet'));
        }

        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return CheckboxListTile(
              value: todo.isCompleted,
              title: Text(todo.title),
              onChanged: (value) {
                (database.update(database.todoItems)
                      ..where((t) => t.id.equals(todo.id)))
                    .write(
                  TodoItemsCompanion(
                    isCompleted: Value(value ?? false),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
```

## Riverpod StreamProvider

Do not treat `AsyncValue<List<TodoItem>>` as a list. Use `when`.

```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final todosProvider = StreamProvider<List<TodoItem>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.todoItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosProvider);

    return todosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Error: $error'),
      data: (todos) => ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(todos[index].title));
        },
      ),
    );
  }
}
```

## Join Streams

```dart
class TodoWithCategory {
  TodoWithCategory({required this.todo, required this.category});

  final TodoItem todo;
  final TodoCategory? category;
}

Stream<List<TodoWithCategory>> watchTodosWithCategory(AppDatabase database) {
  final query = database.select(database.todoItems).join([
    leftOuterJoin(
      database.categories,
      database.categories.id.equalsExp(database.todoItems.category),
    ),
  ]);

  return query
      .map(
        (row) => TodoWithCategory(
          todo: row.readTable(database.todoItems),
          category: row.readTableOrNull(database.categories),
        ),
      )
      .watch();
}
```

## Custom Query Streams

For custom SQL, use `customSelect(...).watch()` and always declare `readsFrom` so Drift knows which tables invalidate the stream.

```dart
Stream<List<TodoItem>> watchCompletedTodos(AppDatabase database) {
  return database
      .customSelect(
        '''
        SELECT * FROM todo_items
        WHERE is_completed = ?
        ORDER BY created_at DESC
        ''',
        variables: [Variable.withBool(true)],
        readsFrom: {database.todoItems},
      )
      .watch()
      .map(
        (rows) => rows
            .map((row) => database.todoItems.map(row.data))
            .toList(),
      );
}
```

## Table Update Events

Use `tableUpdates` for low-level update events:

```dart
final subscription = database
    .tableUpdates(
      TableUpdateQuery.onTable(
        database.todoItems,
        limitUpdateKind: UpdateKind.update,
      ),
    )
    .listen((updates) {
  for (final update in updates) {
    debugPrint('Todo table update: $update');
  }
});
```

Cancel subscriptions you create manually:

```dart
await subscription.cancel();
```

## Manual Update Trigger

If a write happens outside Drift and streams must refresh, manually notify the affected table:

```dart
database.notifyUpdates({
  TableUpdate.onTable(
    database.todoItems,
    kind: UpdateKind.update,
  ),
});
```

## Stream Transformations

Map streams to lightweight UI state when widgets do not need full rows:

```dart
final titlesStream = database
    .select(database.todoItems)
    .watch()
    .map((todos) => todos.map((todo) => todo.title).toList());
```

Debounce user input before rebuilding the query in UI state. Do not depend on a `debounceTime` extension unless the app already imports a package that provides it.

## Limitations

- Updates outside Drift do not trigger query streams unless you call `notifyUpdates`.
- Drift stream invalidation is table-based, so streams can rerun more often than the exact row changes require.
- Keep stream queries indexed and reasonably small for UI use.
