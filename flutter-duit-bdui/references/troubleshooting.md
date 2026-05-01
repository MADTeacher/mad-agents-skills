# Troubleshooting

Use this reference when a Duit screen fails to render, initialize, update, or
clean up correctly.

## Widget Not Rendering

- Confirm the server JSON has a supported `type`, a stable unique `id`, and the
  expected `attributes` shape.
- For custom widgets, confirm registration runs before the layout is rendered.
- Keep `duit:throw-on-unspecified-widget-type=true` during development when
  schema errors should fail loudly.
- Render a minimal `XDriver.static` layout to separate framework setup issues
  from backend payload issues.

## Driver Initialization Failing

- Verify the installed `flutter_duit` version and constructor shape.
- Verify `baseUrl`, route, auth headers, and server response content type.
- Check whether the project expects relative routes such as `/layout` plus
  `baseUrl`, or a fully composed URL.
- Add loading and error UI around `DuitViewHost.withDriver` when the current API
  supports it.

## Theme Or Component Not Applying

- Confirm theme/component registration happens before `runApp` or before the
  first Duit layout that uses it.
- Verify the JSON tag/name matches the registered Dart-side identifier exactly.
- Check that dynamic refs point to existing keys in the component `data`.

## Memory Leaks Or Repeated Requests

- Do not create drivers inside `build`.
- Dispose `XDriver` in the matching lifecycle owner.
- Dispose custom transport managers, stream subscriptions, controllers, and
  native handles in `releaseResources` or the owning lifecycle method.

## Validation Checklist

- `flutter pub get` after dependency changes.
- `dart format` on edited Dart files.
- `flutter analyze`.
- Focused tests or `flutter test` for shared behavior.
- Manual or automated render smoke test for at least one static layout and, when
  applicable, one remote layout.
