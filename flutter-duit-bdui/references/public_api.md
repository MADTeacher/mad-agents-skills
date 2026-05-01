# Public Driver API

Use this reference after `SKILL.md` has routed you here. It summarizes the
driver API patterns the agent should verify and use; it is not a replacement for
checking the installed package version.

## Version Rule

`flutter_duit` 4.x examples use `XDriver` factories and
`DuitViewHost.withDriver`. Older `DuitDriver(...)` examples and transport option
wrappers may still appear in historical docs, blog posts, or old projects. Match
the target project's installed major version before editing code.

## Common Modes

| Mode | Use when | 4.x starting point |
|---|---|---|
| Remote | Layout comes from a backend endpoint | `XDriver.remote(...)` with an HTTP transport manager |
| Static | Layout is local JSON for tests, previews, or fixtures | `XDriver.static(...)` |
| Native module | Duit UI is embedded and communicates with a host/native layer | `XDriver.nativeModule(...)` after checking the current API |

## Remote HTTP Example

```dart
late final XDriver driver;

@override
void initState() {
  super.initState();
  driver = XDriver.remote(
    transportManager: HttpTransportManager(
      url: "/layout",
      baseUrl: "https://api.example.com",
      defaultHeaders: {
        "Content-Type": "application/json",
      },
    ),
  );
}

@override
void dispose() {
  driver.dispose();
  super.dispose();
}
```

```dart
DuitViewHost.withDriver(
  driver: driver,
  placeholder: const CircularProgressIndicator(),
);
```

## Static Layout Example

```dart
final driver = XDriver.static(
  {
    "type": "Text",
    "id": "hello",
    "attributes": {
      "data": "Hello, World!",
    },
  },
  transportManager: StubTransportManager(),
);
```

Use static mode for local smoke tests before introducing backend transport
complexity.

## Lifecycle Rules

- Create the driver in an owner with a clear lifecycle, usually `State.initState`
  or an existing dependency owner.
- Dispose the driver in the matching cleanup method.
- Avoid creating a new driver on every `build`.
- Handle loading and error states when the host widget/API supports them.
- Keep auth headers and base URLs consistent with the project's existing
  networking layer.

## Event And Stream Work

When adding external event streams, custom event handlers, actions, or WebSocket
transport, verify names and signatures against the current API docs. Treat
server event schema as a backend contract, not something to infer from widget
names alone.

## Do Not Use Without Verification

Avoid these shapes unless the installed package version explicitly supports
them:

```dart
XDriver(
  transportManager: HttpTransportManager(
    options: HttpTransportOptions(...),
  ),
);
```

```dart
WSTransportManager(
  options: WSTransportOptions(...),
);
```

These forms may reflect older or mixed documentation and can produce code that
does not compile on current 4.x packages.
