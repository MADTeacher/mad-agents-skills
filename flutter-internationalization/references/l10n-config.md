# l10n.yaml Configuration

Reference for `l10n.yaml` options used by Flutter's `gen-l10n` tool. Treat
`flutter gen-l10n --help` in the user's project as the final source of truth
when an installed SDK differs from these notes.

## Basic Configuration

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

| Option | Description | Default |
|---|---|---|
| `arb-dir` | Directory containing template and translated ARB files | `lib/l10n` |
| `template-arb-file` | Template ARB file used for generated Dart APIs | `app_en.arb` |
| `output-localization-file` | Filename for generated localization and delegate classes | `app_localizations.dart` |
| `output-class` | Dart class name for generated localizations | `AppLocalizations` |

## Output Location

By default, current Flutter generates localization source into the ARB directory
or the configured `output-dir`. Import the generated file from that source
location:

```dart
import 'l10n/app_localizations.dart';
```

Use a custom output directory only when the project wants generated files outside
`arb-dir`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated/l10n
```

Then import from that directory:

```dart
import 'generated/l10n/app_localizations.dart';
```

Do not configure `synthetic-package: true`. Current Flutter marks the synthetic
package flag as deprecated and it cannot be enabled. Migrate stale imports like
`package:flutter_gen/gen_l10n/app_localizations.dart` to source imports that
match the generated output location.

## Locale Options

```yaml
preferred-supported-locales:
  - en_US
  - es_ES
```

`preferred-supported-locales` changes the generated supported-locale order. Use
it when the app should prefer a specific regional locale instead of alphabetical
ordering.

## Code Generation Options

| Option | Description | Default |
|---|---|---|
| `use-escaping` | Enable single quote escaping syntax for literal braces and quotes | `false` |
| `nullable-getter` | Whether `AppLocalizations.of(context)` returns nullable | `true` |
| `use-named-parameters` | Generate named parameters for message methods | `false` |
| `format` | Run `dart format` after generation | enabled by default in current Flutter |

Use `nullable-getter: false` only when the project accepts non-null generated
getter behavior:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

With the default nullable getter, user code usually needs:

```dart
AppLocalizations.of(context)!.title
```

With `nullable-getter: false`, the generated getter performs the null check and
call sites can omit `!`:

```dart
AppLocalizations.of(context).title
```

## Tracking And Warnings

| Option | Description | Example |
|---|---|---|
| `untranslated-messages-file` | JSON file that lists messages missing from translations | `l10n_untranslated.json` |
| `gen-inputs-and-outputs-list` | Directory for `gen_l10n_inputs_and_outputs.json` | `.` |
| `project-dir` | Root Flutter project directory for generation | `/path/to/project` |
| `required-resource-attributes` | Require metadata entries for all resource ids | `true` |
| `suppress-warnings` | Suppress generator warnings | `true` |
| `relax-syntax` | Treat unmatched braces as literal text in relaxed cases | `true` |

Track untranslated messages when adding or auditing locale coverage:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
untranslated-messages-file: l10n_untranslated.json
```

## Deferred Loading

Deferred loading can reduce initial JavaScript bundle size for web apps with
many locales and many messages. It can add overhead for small locale sets, and
it does not affect mobile or desktop.

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
use-deferred-loading: true
```

Use the normal generated source import:

```dart
import 'l10n/app_localizations.dart';

Future<AppLocalizations> loadLocale(String localeCode) {
  return AppLocalizations.delegate.load(Locale(localeCode));
}
```

## Header Configuration

```yaml
header: "/// Generated localization files."
```

For a longer header, place the file in `arb-dir`:

```text
lib/l10n/header.txt
```

Then configure:

```yaml
header-file: header.txt
```

## Validation

After changing `l10n.yaml`:

1. Run `flutter gen-l10n`.
2. Confirm generated files appear in `arb-dir` or `output-dir`.
3. Confirm app imports match the generated location.
4. Run the narrowest relevant compile check, usually `flutter analyze`.

For placeholder number and date formats, see
[number-date-formats.md](number-date-formats.md).
