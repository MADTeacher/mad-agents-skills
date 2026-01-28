# Environment variables

This page describes compile-time environment variables used across DUIT packages and how to enable/disable them in different workflows.

All variables below are compile-time constants resolved via bool.fromEnvironment, which means they are evaluated at build time and must be provided through the toolchain flags.

## Available variables

1) `duit:throw-on-unspecified-widget-type`

- Package: `flutter_duit`
- Type: `bool` (compile-time)
- Default: `true`
- Purpose: When an unspecified/unknown widget type is encountered, throw `ArgumentError` (when `true`) instead of returning a fallback empty widget (when `false`). Useful during development to surface schema/model issues early.

1) `duit:enable-warm-up`

- Package: `duit_kernel`
- Type: `bool` (compile-time)
- Default: `false`
- Purpose: Enables attribute warm-up routines. When enabled, the kernel may pre-initialize attribute-related structures to reduce first-use latency.

1) `duit:prefer-inline`

- Package: `duit_kernel`
- Type: `bool` (compile-time)
- Default: `true`
- Purpose: Favors inline function strategies in the kernel where supported. Intended for advanced performance tuning and experimentation.

1) `duit:allow-focus-node-override`

- Package: `flutter_duit`
- Type: `bool` (compile-time)
- Default: `false`
- Purpose: Favors inline function strategies in the kernel where supported. Intended for advanced performance tuning and experimentation.
- Назначение: Defines the behavior when binding a `FocusNode` to a driver if an attempt is made to bind a node with the same `nodeId` again.

## How to set

These are compile-time flags and should be passed to the build/test commands.

#### Flutter (run/build/test)

Use `--dart-define` for Flutter CLI commands.

Run the app:

```bash
  flutter run -d macos \
  --dart-define=duit:throw-on-unspecified-widget-type=false \
  --dart-define=duit:enable-warm-up=true \
  --dart-define=duit:prefer-inline=true
```
