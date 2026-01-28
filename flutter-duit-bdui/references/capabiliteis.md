# About Duit capability-based API design

Duit framework uses a capability-based architecture that allows developers to customize and extend core functionality through modular delegates. This design pattern separates concerns and provides flexibility in how different aspects of the framework are implemented.

## Available Capabilities

The flutter_duit package provides a concrete implementation for each delegate:

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

To create a custom capability implementation, simply create a class with the corresponding mixin:

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
    // Resource cleanup
  }

  // Implementation of remaining methods...
}
```

## Best Practices

1. **Always call `linkDriver()`** when implementing custom capabilities to enable communication with the driver
2. **Implement `releaseResources()`** to clean up resources (close connections, cancel streams, etc.)
3. **Use proper error handling** and log errors via `driver.logError()`
4. **Keep capabilities focused** on a single responsibility
5. **Document custom implementations** for maintainability

---

## Conclusion

Duit's capability-based API provides a powerful and flexible architecture for building backend-driven UI applications. By understanding and customizing capabilities, you can:

- Extend functionality without modifying core framework code
- Optimize for specific use cases (mobile, web, embedded)
- Integrate with existing systems (analytics, logging, authentication)
- Add platform-specific features (native modules, JS execution)
- Improve testing and debugging capabilities

The modular design makes Duit adaptable to various requirements while maintaining a clean separation of concerns.
