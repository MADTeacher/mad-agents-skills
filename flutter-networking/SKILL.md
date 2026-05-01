---
name: flutter-networking
description: >-
  Implement, fix, debug, review, or refactor Flutter networking code for
  HTTP/REST APIs, WebSocket realtime flows, authentication and token refresh,
  request headers, timeouts, retries, JSON parsing, caching, background isolates,
  repositories, services, and adaptation to existing http, Dio, Retrofit,
  Chopper, or custom API clients. Use when asked to add network requests,
  investigate network errors, harden API clients, handle auth, or validate
  Flutter network behavior.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "2.0"
---

# Flutter Networking

You are a networking agent for Flutter apps. Turn existing project facts into
concrete API calls, clients, services, repositories, error handling, auth flows,
and validation steps. Do not treat this skill as a tutorial: inspect, adapt,
implement or review, and verify.

## Core Contract

1. Confirm the target is a Flutter or Dart package by inspecting `pubspec.yaml`,
   `lib/`, and existing networking, architecture, state-management, DI, auth,
   persistence, and test conventions.
2. Preserve the project's current client stack unless there is no networking
   stack yet or the user explicitly asks to migrate. Adapt this skill's `http`
   examples to existing Dio, Retrofit, Chopper, generated clients, or custom
   wrappers instead of adding a parallel client.
3. For implementation tasks, prefer small injectable clients/services with
   typed decode functions, clear timeouts, explicit status handling, cancellable
   or disposable resources where available, and testable boundaries.
4. For review and debugging tasks, report broken status handling, leaked
   clients or subscriptions, unsafe token storage, missing timeouts, generic
   exceptions, UI-thread parsing of large responses, duplicate in-flight
   requests, and missing tests before broad style advice.
5. Keep UI networking thin. Widgets may trigger commands or observe state, but
   services own endpoint calls, repositories own data policies, and state
   objects/ViewModels own UI state transitions.
6. Validate with the repo's normal commands. Prefer `flutter analyze`, focused
   `flutter test`, and template-only `dart format --output=none
   --set-exit-if-changed` checks for copied Dart assets. Explain skipped checks.

## Clarification Rules

Ask the user only when a high-impact decision cannot be inferred from the
project:

- API contract, endpoint base URL, auth mechanism, or token lifecycle is absent;
- realtime behavior needs product semantics such as reconnect policy, ordering,
  delivery guarantees, or offline behavior;
- cache freshness, optimistic updates, pagination, or retry policy would change
  user-visible data correctness;
- the project already has multiple networking stacks and the intended target is
  ambiguous.

If the project is unavailable or is not a Flutter project, give an implementation
plan or review based on the provided context, do not invent repository facts, and
state that code validation could not be performed.

## Resource Routing

Read only the references and assets needed for the current task:

| Need | Read | Use for |
|---|---|---|
| Basic HTTP CRUD or JSON models | [http-basics.md](references/http-basics.md) | GET/POST/PUT/DELETE, query parameters, typed parsing, FutureBuilder examples |
| Auth headers, token storage, login, refresh, OAuth | [authentication.md](references/authentication.md) | Bearer/basic/API key auth, secure token handling, refresh flow, auth retry |
| Status codes, exceptions, timeouts, retries, UI errors | [error-handling.md](references/error-handling.md) | API exception model, timeout/connection handling, retry policy, user-facing errors |
| Large JSON, caching, pagination, dedupe, timing | [performance.md](references/performance.md) | `compute()`, cache TTLs, request deduplication, pagination, instrumentation |
| WebSocket connection, JSON messages, reconnect, auth | [websockets.md](references/websockets.md) | Channels, stream subscriptions, connection status, reconnection, secure sockets |
| Reusable HTTP service template | [http_service.dart](assets/code-templates/http_service.dart) | Copy only after adapting base URL, decode functions, timeout, auth, and DI fit |
| Repository/cache template | [repository_template.dart](assets/code-templates/repository_template.dart) | Copy only when the app lacks an equivalent repository/cache boundary |
| Standalone examples | [examples](assets/examples/) | Use as illustrative snippets, then adapt imports, state management, disposal, and errors |

Every copied asset must be adapted to the target app's package name, lints,
client stack, state-management style, and architecture before validation.

## Networking Defaults

- Use `http: ^1.6.0` and `web_socket_channel: ^3.0.3` only for new simple
  clients. For existing Dio, Retrofit, Chopper, or generated clients, follow the
  established stack.
- Inject clients instead of constructing them deep inside services. Close owned
  `http.Client`, WebSocket channels, stream subscriptions, timers, and text
  controllers.
- Treat `200..299` as success only when the endpoint contract allows it. Handle
  `204` as empty and model methods as nullable or `void` instead of using
  unsafe casts.
- Decode JSON into typed models at service/repository boundaries. Use
  background isolates for large responses, but avoid isolate overhead for small
  payloads.
- Add request timeouts and retry only transient failures. Do not retry unsafe
  mutations unless the API is idempotent or the user confirms the product policy.
- Store sensitive tokens with `flutter_secure_storage: ^10.0.0` or the app's
  existing secure storage. Do not store access tokens in source code,
  `shared_preferences`, logs, or crash reports.
- Use `wss://` for WebSockets. Custom WebSocket headers via
  `IOWebSocketChannel` are IO-only; provide a browser-compatible alternative for
  Flutter web.
- Do not manually set `Accept-Encoding` as a default with `package:http`; let the
  platform/client negotiate compression unless the project has a measured need.

## Validation

Before finishing an implementation or review:

1. Check that endpoint calls are behind testable services or repositories and
   that UI code does not own raw HTTP/WebSocket details.
2. Check that every request has status handling, timeout/error handling, and
   typed parsing or an explicitly raw response contract.
3. Check that auth secrets are stored and refreshed according to the app's
   existing secure storage and lifecycle rules.
4. Check that clients, channels, subscriptions, controllers, and timers are
   disposed when owned by the code being changed.
5. Run the closest available validation:
   - `flutter analyze`
   - focused `flutter test` suites for changed network/auth/repository code
   - `dart format --output=none --set-exit-if-changed` for copied Dart assets
   - this skill's `scripts/verify-examples.sh` when changing bundled examples or
     templates
6. Report commands run, failures, skipped checks, and residual networking risks.
