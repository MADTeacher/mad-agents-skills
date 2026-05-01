#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/dart_drift_verify_$$"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$TMP_ROOT"

cd "$TMP_ROOT"
cat > pubspec.yaml <<'YAML'
name: dart_drift_verify
publish_to: none
environment:
  sdk: ">=3.5.0 <4.0.0"
YAML

dart pub add drift sqlite3 drift_postgres postgres test
dart pub add dev:drift_dev dev:build_runner

mkdir -p lib test

cat > build.yaml <<'YAML'
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialects:
              - sqlite
              - postgres
YAML

cat > lib/app_database.dart <<'DART'
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'app_database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Words extends Table {
  TextColumn get word => text()();
  IntColumn get usages => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>>? get primaryKey => {word};
}

@DriftDatabase(tables: [TodoItems, Words])
class SqliteTodoDatabase extends _$SqliteTodoDatabase {
  SqliteTodoDatabase([QueryExecutor? executor])
      : super(executor ?? openSqliteForFile(File('verify.sqlite')));

  @override
  int get schemaVersion => 1;
}

QueryExecutor openSqliteForFile(File file) {
  return NativeDatabase.createInBackground(file);
}

class PgUsers extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
  JsonColumn get settings => customType(PgTypes.jsonb)();
  Column<List<String>> get tags => customType(PgTypes.textArray)();
  TimestampColumn get createdAt =>
      customType(PgTypes.timestampWithTimezone).withDefault(now())();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [PgUsers])
class PostgresUserDatabase extends _$PostgresUserDatabase {
  PostgresUserDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

PostgresUserDatabase openPostgresDatabase() {
  return PostgresUserDatabase(
    PgDatabase(
      endpoint: pg.Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: pg.ConnectionSettings(
        sslMode: pg.SslMode.disable,
        connectTimeout: const Duration(seconds: 10),
        queryTimeout: const Duration(seconds: 30),
      ),
    ),
  );
}

PostgresUserDatabase openPooledPostgresDatabase() {
  final pool = pg.Pool.withEndpoints(
    [
      pg.Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
    ],
    settings: pg.PoolSettings(maxConnectionCount: 5),
  );

  return PostgresUserDatabase(PgDatabase.opened(pool));
}

Future<void> trackWord(SqliteTodoDatabase db, String word) {
  return db.into(db.words).insert(
        WordsCompanion.insert(word: word),
        onConflict: DoUpdate(
          (old) => WordsCompanion.custom(
            usages: old.usages + const Constant(1),
          ),
        ),
      );
}

Stream<List<QueryRow>> watchCompletedRows(SqliteTodoDatabase db) {
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

Stream<List<TodoItem>> watchCompletedTodos(SqliteTodoDatabase db) {
  return watchCompletedRows(db).map(
    (rows) => rows.map((row) => db.todoItems.map(row.data)).toList(),
  );
}

Stream<Set<TableUpdate>> todoUpdateEvents(SqliteTodoDatabase db) {
  return db.tableUpdates(TableUpdateQuery.onTable(db.todoItems));
}

void notifyExternalTodoUpdate(SqliteTodoDatabase db) {
  db.notifyUpdates({
    TableUpdate.onTable(db.todoItems, kind: UpdateKind.update),
  });
}
DART

cat > test/app_database_test.dart <<'DART'
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:dart_drift_verify/app_database.dart';

void main() {
  late SqliteTodoDatabase db;

  setUp(() {
    db = SqliteTodoDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('sqlite query, upsert, stream, and update notification examples compile and work', () async {
    final id = await db.into(db.todoItems).insert(
          TodoItemsCompanion.insert(title: 'Learn Drift'),
        );

    final todo = await (db.select(db.todoItems)
          ..where((item) => item.id.equals(id)))
        .getSingle();
    expect(todo.title, 'Learn Drift');

    await trackWord(db, 'drift');
    await trackWord(db, 'drift');
    final word = await (db.select(db.words)
          ..where((entry) => entry.word.equals('drift')))
        .getSingle();
    expect(word.usages, 2);

    final completedExpectation =
        expectLater(watchCompletedTodos(db), emitsThrough(isNotEmpty));
    await db.into(db.todoItems).insert(
          TodoItemsCompanion.insert(
            title: 'Ship verified examples',
            isCompleted: const Value(true),
          ),
        );
    await completedExpectation;

    final updateExpectation = expectLater(todoUpdateEvents(db), emits(isNotEmpty));
    notifyExternalTodoUpdate(db);
    await updateExpectation;
  });
}
DART

dart run build_runner build
dart analyze
dart test

echo "Verified dart-drift examples from $ROOT_DIR"
