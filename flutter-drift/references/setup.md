---
title: Setup
description: Set up Drift for Flutter applications with drift_flutter
---

## Dependencies

Prefer package commands so the project resolves current compatible versions:

```bash
dart pub add drift drift_flutter path_provider dev:drift_dev dev:build_runner
```

Use `flutter pub add` instead of `dart pub add` if that is the local project convention.

If a document must pin versions, verify them against pub.dev first. At the time this skill was revised, current package pages showed:

- `drift: ^2.32.1`
- `drift_dev: ^2.32.1`
- `drift_flutter: ^0.3.0`
- `build_runner: ^2.15.0`

## Canonical Database

Create `lib/database.dart` or follow the app's existing database module layout.

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

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

@DriftDatabase(tables: [Categories, TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'app_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;
}
```

Run the generator:

```bash
dart run build_runner build
```

Use watch mode during active development:

```bash
dart run build_runner watch
```

## Web Support

Flutter web needs the sqlite3 WASM module and Drift worker in `web/`:

- `sqlite3.wasm`
- `drift_worker.js`

Do not claim web support is complete until those assets are present and the app has been tested in a browser.

## Manual Database Setup

Use manual setup only when `driftDatabase` is not flexible enough.

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_db.sqlite'));

    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;

    return NativeDatabase.createInBackground(file);
  });
}
```

## Isolate Sharing

Enable `shareAcrossIsolates` only when multiple isolates must access the same database, such as foreground app code plus background work.

```dart
@DriftDatabase(tables: [Categories, TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase.defaults()
      : super(
          driftDatabase(
            name: 'app_db',
            native: const DriftNativeOptions(
              shareAcrossIsolates: true,
            ),
          ),
        );

  @override
  int get schemaVersion => 1;
}
```

When isolate sharing is enabled, always close database instances explicitly so the shared server can shut down.

## Testing Setup

Keep the constructor injectable so tests can use an in-memory executor:

```dart
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```
