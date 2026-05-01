# Duit Capabilities

Duit uses capability delegates to customize framework behavior without changing
the core driver. Read this reference only when the task requires custom
transport, logging, focus behavior, scripting, native modules, controller
management, action execution, or view-model behavior.

## Available Capabilities

Common delegate responsibilities:

| Delegate | Purpose |
|----------|---------|
| `ViewModelCapabilityDelegate` | View model management, UI events, layout structure parsing |
| `TransportCapabilityDelegate` | Transport layer (HTTP, WebSocket, static content) |
| `ServerActionExecutionCapabilityDelegate` | Server action execution and event handling |
| `UIControllerCapabilityDelegate` | UI element controller management (TextField, Checkbox, etc.) |
| `FocusCapabilityDelegate` | Focus management and element navigation |
| `ScriptingCapabilityDelegate` | Embedded script execution |
| `LoggingCapabilityDelegate` | Logging with support for different levels |
| `NativeModuleCapabilityDelegate` | Native code interaction via MethodChannel |

## Creating Custom Implementations

Before implementing a custom capability, check the installed `flutter_duit` and
`duit_kernel` versions. Delegate signatures can change across major versions.

Minimal shape:

```dart
final class MyCustomFocusManager with FocusCapabilityDelegate {
  late final UIDriver _driver;

  @override
  void linkDriver(UIDriver driver) => _driver = driver;

  @override
  void requestFocus(String nodeId) {
    // Custom focus management logic
  }

  @override
  void releaseResources() {
    // Dispose streams, controllers, handles, or listeners owned here.
  }

  // Implement the remaining methods required by the installed package version.
}
```

## Guardrails

- Implement `linkDriver()` when the delegate needs driver access.
- Implement `releaseResources()` for every delegate that owns subscriptions,
  streams, controllers, channels, or handles.
- Keep each capability focused on one responsibility.
- Route errors through the project's logging strategy or Duit logging delegate.
- Add focused tests or a smoke path for custom transport/action/focus behavior.
- Do not replace a built-in delegate just to change one endpoint, header, or UI
  option if the public API already supports it.

## Validation

After implementing a custom capability, run `dart format`, `flutter analyze`,
and focused tests. If the capability touches transport or event execution, also
exercise at least one success path and one failure path.
