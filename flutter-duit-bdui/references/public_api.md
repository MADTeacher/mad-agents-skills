# Public Driver API

## Overview

The Public Driver API (`XDriver`) is the public interface for working with the Duit driver. It represents an **extension type wrapper** over the internal `UIDriver`, providing a convenient interface for initializing and managing a Duit application in various operation modes.

### Architecture

```
XDriver (extension type)
    ↓ wraps
UIDriver (internal)
    ↓ uses
DuitDriverCompat (implementation)
```

`XDriver` implements the `FocusCapabilityDelegate` interface to support focus management in the UI.

## Supported Operation Modes

### 1. Remote (Remote Mode)

- Connection to a remote server through the transport layer
- UI is dynamically loaded from the server
- Support for live updates through the transport
- Ideal for backend-driven UI

### 2. Static (Static Mode)

- Working with predefined JSON content without server requests
- Suitable for offline mode, testing, or applications with fixed UI
- Uses `StubTransportManager` by default

### 3. Native Module (Module Mode)

- Integration of Duit as a module into an existing Flutter application
- Uses `NativeTransportManager` by default for communication with the host application
- Allows embedding Duit UI into native applications

## Capability Delegates (Managers)

The driver supports multiple delegates to extend functionality:

| Delegate | Interface | Purpose |
|----------|-----------|---------|
| `transportManager` | `TransportCapabilityDelegate` | Transport layer management (HTTP/WebSocket/Native) |
| `nativeModuleManager` | `NativeModuleCapabilityDelegate` | Platform code invocation |
| `scriptingManager` | `ScriptingCapabilityDelegate` | Client-side script execution |
| `loggingManager` | `LoggingCapabilityDelegate` | Logging customization |
| `focusManager` | `FocusCapabilityDelegate` | UI element focus management |
| `actionManager` | `ServerActionExecutionCapabilityDelegate` | Server action execution |
| `controllerManager` | `UIControllerCapabilityDelegate` | Widget state management |
| `viewManager` | `ViewModelCapabilityDelegate` | View model management |
| `actionParser` | `Parser<ServerAction>` | Parsing server actions from JSON |
| `eventParser` | `Parser<ServerEvent>` | Parsing server events from JSON |

## Public Methods

### Factory Constructors

#### `XDriver.remote()`

Creates a driver for working with a remote Duit server.

**Required parameters:**

- `transportManager` - transport layer manager

**Optional parameters:**

- `initialRequestPayload` - data for the first request to the server
- All capability delegates

#### `XDriver.static()`

Creates a driver for working with static JSON content.

**Required parameters:**

- `content` - JSON structure describing the UI

**Optional parameters:**

- `initialRequestPayload` - initial data for initialization
- `transportManager` - if not specified, uses `StubTransportManager`
- All capability delegates

**Throws:**

- `StateError` if `content` is empty

#### `XDriver.nativeModule()`

Creates a driver for native module mode.

**Optional parameters:**

- `initialRequestPayload` - initial data from the host application
- `transportManager` - if not specified, uses `NativeTransportManager`
- All capability delegates

#### `XDriver.from()` (internal)

Creates an `XDriver` from an existing `UIDriver` instance.
**For internal library use only.** Marked as `@internal`.

### Lifecycle Methods

#### `init()`

Initializes the driver and prepares it for operation.

**Performs:**

- Transport layer initialization
- Loading of initial UI content (for remote mode)
- Setup of all registered delegates and managers
- Event system preparation

**Returns:** `Future<void>` - completes when the driver is fully ready

**Important:** Call only once. Repeated calls may lead to unpredictable behavior.

#### `dispose()`

Releases resources used by the driver.

**Performs:**

- Closes transport connections
- Cancels external event stream subscriptions
- Clears internal caches and state
- Releases resources of all registered managers
- Removes all event handlers

**Important:** After calling `dispose`, the driver becomes unusable. It is recommended to call this in the `dispose` method of the widget using the driver.

### Event Handling Methods

#### `attachExternalHandler()`

Registers an external event handler.

**Parameters:**

- `type` - event handler type (`UserDefinedHandlerKind`)
- `handle` - handler function (`UserDefinedEventHandler`)

**Example:**

```dart
driver.attachExternalHandler(
  UserDefinedHandlerKind.custom('onButtonClick'),
  (eventData) {
    print('Button clicked: ${eventData['id']}');
  },
);
```

Handlers are called synchronously when the corresponding event occurs in the UI. One type can have only one handler; repeated registration replaces the previous one.

#### `addExternalEventStream()`

Adds an external event stream for processing by the driver.

**Parameters:**

- `stream` - event stream in JSON format (`Stream<Map<String, dynamic>>`)

**Example:**

```dart
final websocketStream = WebSocketChannel.connect(
  Uri.parse('ws://example.com'),
).stream.map((data) => jsonDecode(data));

driver.addExternalEventStream(websocketStream);
```

The driver automatically subscribes to the stream when added and unsubscribes when `dispose` is called. Multiple streams can be added; they will be processed in parallel.

**Important:** Ensure that the event structure matches the expected Duit format or is handled by registered external handlers.

### Internal Methods

#### `asInternalDriver`

Provides access to the internal `UIDriver` instance.

**For internal library use only.** Marked as `@internal`. Should not be used in user code. Direct use of `UIDriver` may break encapsulation and lead to unpredictable behavior.

## Usage Examples

### Remote Mode

```dart
final driver = XDriver.remote(
  transportManager: HttpTransportManager(
    baseUrl: 'https://api.example.com',
  ),
  initialRequestPayload: {
    'userId': '12345',
    'theme': 'dark',
  },
  loggingManager: CustomLogger(),
);

await driver.init();
```

### Static Mode

```dart
final uiContent = {
  'type': 'Column',
  'children': [
    {'type': 'Text', 'data': 'Hello World'},
  ],
};

final driver = XDriver.static(uiContent);
await driver.init();
```

### Native Module Mode

```dart
final driver = XDriver.nativeModule(
  nativeModuleManager: MyNativeModuleManager(),
  initialRequestPayload: {
    'hostVersion': '1.0.0',
    'features': ['analytics', 'payments'],
  },
);

await driver.init();
```

### Lifecycle Management

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final XDriver driver;

  @override
  void initState() {
    super.initState();
    driver = XDriver.remote(
      transportManager: myTransport,
    );
    driver.init();
  }

  @override
  void dispose() {
    driver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ...;
}
```

## Usage Recommendations

1. **Mode Selection:** Use the mode according to the application architecture:
   - Remote - for backend-driven UI
   - Static - for tests or offline mode
   - NativeModule - for integration into existing applications

2. **Lifecycle:** Always call `init()` before using the driver and `dispose()` when finished.

3. **Capability Delegates:** Connect only necessary delegates to optimize performance.

4. **Error Handling:** Wrap `init()` in try-catch to handle initialization errors.

5. **Single Use:** Do not create multiple driver instances for the same session.

## Design Rationale

Using an **extension type** instead of a regular class allows:

- **Performance:** Extension types do not create additional objects at runtime, reducing overhead
- **Encapsulation:** Hides the internal implementation (`UIDriver`) behind a clean public API
- **Compatibility:** Easily integrates with existing code without type changes
- **Easy Extension:** Ability to add new methods without modifying the base implementation

This decision aligns with modern Dart 3.0+ practices and provides an optimal balance between performance and usability.
