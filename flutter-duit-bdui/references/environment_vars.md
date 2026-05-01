# Environment Variables

This reference covers compile-time DUIT flags. Use it only when the task asks
to change unknown-widget behavior, warm-up, inlining, or focus-node override
behavior.

All values are compile-time constants resolved through `bool.fromEnvironment`.
Pass them with `--dart-define` to `flutter run`, `flutter build`, or
`flutter test`.

## Available Variables

1. `duit:throw-on-unspecified-widget-type`

- Package: `flutter_duit`
- Type: `bool`
- Default: `true`
- Purpose: when an unknown widget type is encountered, throw an error instead
  of rendering a fallback empty widget. Keep this enabled in development unless
  the user explicitly wants permissive fallback behavior.

2. `duit:enable-warm-up`

- Package: `duit_kernel`
- Type: `bool`
- Default: `false`
- Purpose: enables attribute warm-up routines that may reduce first-use latency.

3. `duit:prefer-inline`

- Package: `duit_kernel`
- Type: `bool`
- Default: `true`
- Purpose: favors inline function strategies where supported. Treat this as
  advanced performance tuning.

4. `duit:allow-focus-node-override`

- Package: `flutter_duit`
- Type: `bool`
- Default: `false`
- Purpose: controls whether binding a `FocusNode` may override an existing node
  with the same `nodeId`.

## Examples

```bash
flutter run -d macos \
  --dart-define=duit:throw-on-unspecified-widget-type=false \
  --dart-define=duit:enable-warm-up=true \
  --dart-define=duit:prefer-inline=true
```

```bash
flutter test \
  --dart-define=duit:throw-on-unspecified-widget-type=true
```

## Guardrails

- Do not use runtime environment variables for these flags; they must be passed
  through the Flutter/Dart toolchain.
- When changing defaults in scripts or CI, update every relevant run/build/test
  command.
- Mention the chosen flag values in the final response when they affect
  debugging or production behavior.
