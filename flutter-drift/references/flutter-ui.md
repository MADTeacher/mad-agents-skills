---
title: Flutter UI Integration
description: Wire Drift databases into Flutter widgets with Provider or Riverpod
---

## Provider Package

Use this pattern when the app uses the `provider` package.

```dart
Provider<AppDatabase>(
  create: (_) => AppDatabase(),
  dispose: (_, database) => database.close(),
  child: const MyApp(),
)
```

Read the database from widgets with `Provider.of` or `context.read`.

```dart
final database = Provider.of<AppDatabase>(context, listen: false);
```

## Riverpod

Use this pattern when the app uses `flutter_riverpod`.

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
```

Consume `AsyncValue` with `when`, not as a list.

```dart
class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosProvider);

    return todosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Error: $error'),
      data: (todos) {
        if (todos.isEmpty) {
          return const Center(child: Text('No todos yet'));
        }

        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            return TodoTile(todo: todos[index]);
          },
        );
      },
    );
  }
}
```

## StreamBuilder

Use `StreamBuilder` directly when the widget owns the query and no state-management wrapper is needed.

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
            return TodoTile(todo: todos[index]);
          },
        );
      },
    );
  }
}
```

## Todo Tile

Use partial updates for checkbox changes. Do not replace a full row unless every non-nullable field is present.

```dart
class TodoTile extends StatelessWidget {
  const TodoTile({required this.todo, super.key});

  final TodoItem todo;

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context, listen: false);

    return CheckboxListTile(
      value: todo.isCompleted,
      title: Text(todo.title),
      subtitle: todo.content == null ? null : Text(todo.content!),
      onChanged: (value) async {
        await (database.update(database.todoItems)
              ..where((t) => t.id.equals(todo.id)))
            .write(
          TodoItemsCompanion(
            isCompleted: Value(value ?? false),
          ),
        );
      },
      secondary: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await (database.delete(database.todoItems)
                ..where((t) => t.id.equals(todo.id)))
              .go();
        },
      ),
    );
  }
}
```

## Add Todo Dialog

Dispose controllers in a `StatefulWidget` and insert with a companion.

```dart
class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context, listen: false);

    return AlertDialog(
      title: const Text('Add Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;

            await database.into(database.todoItems).insert(
                  TodoItemsCompanion.insert(
                    title: title,
                    content: Value(
                      _contentController.text.trim().isEmpty
                          ? null
                          : _contentController.text.trim(),
                    ),
                  ),
                );

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
```

## Filtered List

For nullable filters, branch the query so `null` means the intended behavior.

```dart
Stream<List<TodoItem>> watchTodosByCategory(
  AppDatabase database,
  int? categoryId,
) {
  final query = database.select(database.todoItems)
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

  if (categoryId == null) {
    query.where((t) => t.category.isNull());
  } else {
    query.where((t) => t.category.equals(categoryId));
  }

  return query.watch();
}
```

## Search With Debounce

Debounce the input state, then rebuild the query from the debounced value.

```dart
class SearchTodoList extends StatefulWidget {
  const SearchTodoList({required this.database, super.key});

  final AppDatabase database;

  @override
  State<SearchTodoList> createState() => _SearchTodoListState();
}

class _SearchTodoListState extends State<SearchTodoList> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = (widget.database.select(widget.database.todoItems)
          ..where((t) => t.title.contains(_query))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(labelText: 'Search todos'),
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState(() => _query = value.trim());
            });
          },
        ),
        Expanded(
          child: StreamBuilder<List<TodoItem>>(
            stream: stream,
            builder: (context, snapshot) {
              final todos = snapshot.data ?? [];
              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  return TodoTile(todo: todos[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## Pagination

For simple pagination, load pages with `limit` and `offset`. For infinite scroll, keep an accumulated list in state instead of replacing the list with only the last page.

```dart
Future<List<TodoItem>> loadTodoPage(
  AppDatabase database, {
  required int page,
  int pageSize = 20,
}) {
  return (database.select(database.todoItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(pageSize, offset: page * pageSize))
      .get();
}
```

## UI Checklist

- Close the database from the provider owner.
- Keep database objects out of `build` methods unless they are read from a provider.
- Handle loading, empty, error, and data states.
- Use partial companion updates for row edits from controls.
- Do not call broad update or delete statements from row-level UI actions.
- Avoid rebuilding expensive streams on every keystroke; debounce or use provider parameters.
