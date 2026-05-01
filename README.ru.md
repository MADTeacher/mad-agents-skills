# MAD Agents Skills

Коллекция агентских навыков для AI-ассистентов, работающих с Dart и Flutter проектами, реализованная в формате [**Agent Skills**](https://agentskills.io/home) - открытого стандарта для расширения возможностей AI-агентов.

Каждый навык содержит **структурированные знания** на основе официальной документации, готовые примеры кода и подробные справочные материалы, которые могут использовать AI-агенты.

## 📋 Содержание

- [Обзор](#-обзор)
- [Навыки](#️-навыки)
  - [AGENTS.md Generator](#agents-md-generator)
  - [Dart Drift](#dart-drift)
  - [Flutter Adaptive UI](#flutter-adaptive-ui)
  - [Flutter Animations](#flutter-animations)
  - [Flutter Architecture](#flutter-architecture)
  - [Flutter Drift](#flutter-drift-1)
  - [Flutter Internationalization](#flutter-internationalization)
  - [Flutter Navigation](#flutter-navigation)
  - [Flutter Networking](#flutter-networking)
  - [Flutter Testing](#flutter-testing)
  - [Flutter Backend-driven UI with Duit](#flutter-backend-driven-ui-with-duit)
- [Файловая структура](#-файловая-структура)
- [Как использовать](#-как-использовать)
- [Матрица применения навыков](#-матрица-применения-навыков)
- [Лицензия](#-лицензия)
- [Вклад в проект](#-вклад-в-проект)
- [Дополнительные ресурсы](#-дополнительные-ресурсы)

## 🎯 Обзор

Этот репозиторий содержит набор специализированных навыков для разработки на Dart и Flutter, организованных в соответствии с открытым стандартом [**Agent Skills**](https://agentskills.io/home).

### Что такое Agent Skills?

Agent Skills - это открытый формат для предоставления AI-агентам новых возможностей и экспертизы. Это структурированные папки с инструкциями, скриптами и ресурсами, которые агенты могут обнаруживать и использовать для выполнения задач более точно и эффективно.

**Формат разработан:** Anthropic  
**Статус:** Открытый стандарт  
**Поддержка:** Ведущие AI-инструменты разработки

### Состав навыка

Каждый навык включает:

- **SKILL.md** - описание навыка с метаданными и условиями применения
- **Справочную документацию** - детальные руководства в папке `references/`
- **Примеры кода** - готовые шаблоны и примеры в папке `assets/`
- **Лучшие практики** - рекомендации по использованию
- **Скрипты** (опционально) - вспомогательные утилиты в папке `scripts/`

### Возможности Agent Skills

✨ **Domain expertise** - специализированные знания в конкретных областях  
🚀 **New capabilities** - новые возможности для агентов  
🔄 **Repeatable workflows** - стандартизированные рабочие процессы  
🔗 **Interoperability** - переиспользование между различными AI-инструментами

## 🛠️ Навыки

### AGENTS.md Generator

**Директория:** `agents-md-generator/`

**Описание:** Создание и обновление минималистичных AGENTS.md файлов в корне репозитория и в директориях вложенных модулей с использованием progressive disclosure. Работает с гетерогенными проектами без привязки к фиксированной структуре папок агентов.

**Когда использовать:**

- AGENTS.md отсутствует, перегружен, противоречив или устарел
- Появился новый пакет/сервис/модуль
- Изменилась структура репозитория (рост или разделение монорепозитория)
- Командам нужен единообразный контекст для агентов в разнородных стеках

**Ключевые возможности:**

- Обнаружение структуры репозитория (git root, маркеры языков/инструментов)
- Определение границ модулей (манифесты сборки, deployable units)
- Генерация корневого AGENTS.md (≤60 строк): назначение, toolchain, команды, ссылки на docs
- Генерация вложенных AGENTS.md (≤40 строк): назначение модуля, локальные команды
- Progressive disclosure: AGENTS.md лаконичен, детали — в docs/skills
- Адаптивные ссылки на навыки (локальные или внешние)

**Результат:**

- `<repo_root>/AGENTS.md`
- `<module_dir>/AGENTS.md` (для независимых пакетов/сервисов)

**Справочные материалы:**

- `AGENTS_TEMPLATE_ROOT.md` — Шаблон корневого AGENTS.md
- `AGENTS_TEMPLATE_MODULE.md` — Шаблон вложенного модуля

---

### Dart Drift

**Директория:** `dart-drift/`

**Описание:** Операционный workflow для добавления, исправления, миграции и проверки Drift persistence в Dart CLI, server-side и не-Flutter desktop приложениях.

**Когда использовать:**

- Добавление локального SQLite storage через `package:drift/native.dart`
- Подключение server-side приложений к PostgreSQL через `drift_postgres`
- Написание типобезопасных tables, queries, writes и reactive streams
- Реализация и проверка миграций схемы БД
- Исправление сбоев `build_runner`, `drift_dev` и generated code

**Ключевые возможности:**

- Настройка с `sqlite3`, `drift_postgres` и `package:postgres`
- Определение таблиц и ограничений
- SELECT, WHERE, JOIN, агрегации
- INSERT, UPDATE, DELETE, транзакции
- Реактивные stream-запросы
- Миграции схемы базы данных и generated migration tests
- Детерминированная smoke-проверка через `scripts/verify-examples.sh`

**Справочные материалы:**

- `setup.md` - Настройка SQLite и PostgreSQL
- `postgres.md` - PostgreSQL-специфичные функции
- `tables.md` - Определение таблиц
- `queries.md` - Запросы к БД
- `writes.md` - Операции записи
- `streams.md` - Реактивные потоки
- `migrations.md` - Миграции схемы

---

### Flutter Adaptive UI

**Директория:** `flutter-adaptive-ui/`

**Описание:** Создание адаптивных и отзывчивых Flutter UI, которые отлично работают на всех платформах и размерах экранов.

**Когда использовать:**

- Создание приложений для множества платформ (mobile, tablet, desktop, web)
- Адаптация layouts под разные размеры экранов
- Поддержка различных устройств ввода (touch, mouse, keyboard)
- Реализация responsive navigation patterns
- Оптимизация для больших экранов и складных устройств
- Использование паттернов Capability и Policy для platform-specific поведения

**Ключевые концепции:**

- **3-шаговый подход:** Abstract → Measure → Branch
- **Breakpoints:** Compact (<600), Medium (600-840), Expanded (≥840)
- **Layout правило:** Constraints go down. Sizes go up. Parent sets position.
- **Capability/Policy паттерн** для платформо-специфичного поведения

**Справочные материалы:**

- `layout-constraints.md` - Система constraints с 29 примерами
- `layout-basics.md` - Основные layout виджеты
- `layout-common-widgets.md` - Container, GridView, ListView, Stack
- `adaptive-workflow.md` - Детальный 3-шаговый подход
- `adaptive-best-practices.md` - Лучшие практики дизайна
- `adaptive-capabilities.md` - Паттерн Capability/Policy

**Примеры:**

- `responsive_navigation.dart` - Переключение NavigationBar ↔ NavigationRail
- `capability_policy_example.dart` - Примеры классов Capability/Policy

---

### Flutter Animations

**Директория:** `flutter-animations/`

**Описание:** Комплексное руководство по реализации анимаций во Flutter.

**Когда использовать:**

- Добавление движения и визуальных эффектов в приложение
- Имплементация implicit animations (простые переходы)
- Создание explicit animations (полный контроль)
- Реализация hero animations (shared element transitions)
- Создание staggered animations (последовательные/перекрывающиеся)
- Использование physics-based animations

**Типы анимаций:**

**Implicit Animations** - для простых случаев:

- AnimatedContainer, AnimatedOpacity
- TweenAnimationBuilder
- Анимация триггерится изменением состояния

**Explicit Animations** - для полного контроля:

- AnimationController, Tween, CurvedAnimation
- AnimatedWidget, AnimatedBuilder
- Мониторинг состояния анимации
- Множественные одновременные анимации

**Hero Animations** - shared element transitions:

- Стандартные hero transitions
- Radial hero animations
- Навигация между экранами

**Staggered Animations** - последовательные эффекты:

- Interval-based timing
- Ripple effects
- Меню с последовательным появлением

**Physics-Based** - естественные движения:

- Spring simulations
- Fling animations
- Gravity-based анимации

**Справочные материалы:**

- `implicit.md` - Implicit анимации
- `explicit.md` - Explicit анимации с AnimationController
- `hero.md` - Hero transitions
- `staggered.md` - Staggered паттерны
- `physics.md` - Physics-based анимации
- `curves.md` - Справочник по Curves

**Шаблоны:**

- `implicit_animation.dart`
- `explicit_animation.dart`
- `hero_transition.dart`
- `staggered_animation.dart`

---

### Flutter Architecture

**Директория:** `flutter-architecture/`

**Описание:** Комплексное руководство по архитектуре Flutter приложений с использованием MVVM паттерна и feature-first организации.

**Когда использовать:**

- Проектирование или рефакторинг архитектуры Flutter приложения
- Выбор между feature-first и layer-first структурой проекта
- Реализация MVVM паттерна во Flutter
- Создание масштабируемой структуры для команд
- Добавление новых функций к существующей архитектуре
- Применение лучших практик и паттернов проектирования

**Организация проекта:**

**Feature-First (рекомендуется для команд):**

- Организация по бизнес-функциям
- Средние и большие приложения (10+ функций)
- Командная разработка (2+ разработчика)
- Самодостаточные feature-модули

**Layer-First (традиционный):**

- Организация по архитектурным слоям
- Малые и средние приложения
- Соло-разработчики или малые команды
- Простая бизнес-логика

**Архитектурные слои:**

- **UI Layer:** Views (widgets) и ViewModels (UI логика)
- **Data Layer:** Repositories (SSOT) и Services (источники данных)
- **Domain Layer:** Use-cases для сложной бизнес-логики (опционально)

**Паттерны проектирования:**

- Command Pattern - инкапсуляция действий
- Result Type - типобезопасная обработка ошибок
- Repository Pattern - абстракция над источниками данных
- Offline-First - оптимистичные UI обновления

**Справочные материалы:**

- `concepts.md` - Основные принципы архитектуры
- `feature-first.md` - Feature-first организация
- `mvvm.md` - Реализация MVVM паттерна
- `layers.md` - Слои и их взаимодействие
- `design-patterns.md` - Общие паттерны

**Примеры:**

- `command.dart` - Шаблон Command паттерна
- `result.dart` - Result type для обработки ошибок
- `examples/` - Примеры применения архитектуры

---

### Flutter Drift

**Директория:** `flutter-drift/`

**Описание:** Полное руководство по использованию библиотеки drift для локального хранилища в Flutter приложениях.

**Когда использовать:**

- Создание Flutter приложений с локальной SQLite базой данных
- Необходимость типобезопасных запросов
- Реализация реактивных stream-запросов
- Миграции схемы базы данных
- Эффективные CRUD операции
- Кроссплатформенная поддержка (mobile, web, desktop)

**Ключевые возможности:**

- Настройка с `drift_flutter` пакетом
- Интеграция StreamBuilder для реактивного UI
- Паттерны Provider/Riverpod
- Platform-specific настройка (mobile, web)
- In-memory database для тестирования
- Миграции схемы с версионированием

**Справочные материалы:**

- `setup.md` - Flutter-специфичная настройка
- `tables.md` - Определение таблиц
- `queries.md` - SELECT запросы
- `writes.md` - INSERT, UPDATE, DELETE
- `streams.md` - Реактивные потоки
- `migrations.md` - Миграции БД
- `flutter-ui.md` - Интеграция с Flutter UI

---

### Flutter Internationalization

**Директория:** `flutter-internationalization/`

**Описание:** Полное руководство по интернационализации Flutter приложений с использованием gen-l10n и intl пакетов.

**Когда использовать:**

- Добавление поддержки локализации в Flutter приложение
- Перевод UI текста на множество языков
- Форматирование чисел и дат для разных локалей
- Настройка мультиязычной поддержки для Material/Cupertino
- Реализация RTL (right-to-left) языков
- Управление ARB файлами и переводами

**Подходы:**

**gen-l10n (рекомендуется):**

- Современный, автоматизированный подход
- ARB файлы + кодогенерация
- Лучше для новых проектов и команд

**intl package:**

- Ручной контроль
- Code-based переводы
- Для простых или legacy проектов

**Custom/Manual:**

- Максимальная гибкость
- Map-based lookup
- Очень простые приложения

**Типы сообщений:**

- Простые сообщения
- С placeholders (параметры)
- Plural messages (множественное число)
- Select messages (выбор по значению)
- Форматирование чисел и дат

**Справочные материалы:**

- `l10n-config.md` - Конфигурация l10n.yaml
- `arb-format.md` - Формат ARB файлов
- `number-date-formats.md` - Форматирование чисел и дат

**Примеры:**

- `app_en.arb` - Пример ARB файла
- `l10n.yaml` - Конфигурационный файл

---

### Flutter Navigation

**Директория:** `flutter-navigation/`

**Описание:** Комплексное руководство по навигации и роутингу во Flutter, включая Navigator API, go_router, deep linking и web-навигацию.

**Когда использовать:**

- Реализация переходов между экранами
- Настройка системы роутинга
- Настройка deep links (iOS, Android, Web)
- Обработка browser history
- Управление navigation state
- Передача и возврат данных между экранами

**Выбор подхода:**

**Navigator API (императивный):**

- Простые приложения без deep linking
- Базовые навигационные стеки
- Быстрое прототипирование
- Переходы single-screen → multi-screen

**go_router (декларативный, рекомендуется):**

- Приложения с deep linking
- Web приложения с browser history
- Сложные навигационные паттерны
- URL-based навигация
- Production приложения

**Избегать Named Routes:**

- Flutter team НЕ рекомендует
- Ограничения в кастомизации deep links
- Нет поддержки browser forward button

**Общие задачи:**

- Передача данных между экранами
- Возврат данных с экранов
- Настройка deep linking (Android, iOS, Web)
- Web URL strategy (hash vs path)
- Route guards (authentication)
- Nested routes
- Error handling (404)

**Справочные материалы:**

- `navigation-patterns.md` - Сравнение подходов
- `go_router-guide.md` - Детальное руководство по go_router
- `deep-linking.md` - Настройка deep links
- `web-navigation.md` - Web-специфичная навигация

**Примеры:**

- `navigator_basic.dart` - Базовый Navigator
- `go_router_basic.dart` - Базовый go_router
- `passing_data.dart` - Передача данных
- `returning_data.dart` - Возврат данных

---

### Flutter Networking

**Директория:** `flutter-networking/`

**Описание:** Реализация, отладка, ревью и усиление сетевого слоя Flutter, включая HTTP/REST API, WebSocket flows, аутентификацию, обработку ошибок и производительность.

**Когда использовать:**

- Реализация HTTP запросов (GET, POST, PUT, DELETE)
- WebSocket соединения для real-time коммуникации
- Аутентифицированные запросы с headers и tokens
- Background parsing с isolates
- REST API интеграция
- Отладка или ревью существующего сетевого кода
- Адаптация к существующим `http`, Dio, Retrofit, Chopper или custom clients
- Обработка сетевых ошибок
- Оптимизация производительности сетевых операций

**HTTP методы:**

- **GET** - получение данных
- **POST** - создание ресурсов
- **PUT** - обновление ресурсов
- **DELETE** - удаление ресурсов

**WebSocket:**

- Соединения с `web_socket_channel`
- Stream-based обмен сообщениями
- Real-time коммуникация

**Аутентификация:**

- Bearer Token
- Basic Auth
- API Key
- Custom headers

**Обработка ошибок:**

- HTTP status codes
- Network exceptions
- Timeout handling
- Retry logic с exponential backoff

**Производительность:**

- Background parsing с `compute()`
- Caching стратегии
- Connection pooling
- Request throttling

**Архитектурные паттерны:**

- Service Layer (HTTP endpoints)
- Repository Layer (caching, aggregation)
- ViewModel Layer (UI transformation)

**Справочные материалы:**

- `http-basics.md` - HTTP CRUD операции
- `websockets.md` - WebSocket реализация
- `authentication.md` - Стратегии аутентификации
- `error-handling.md` - Паттерны обработки ошибок
- `performance.md` - Оптимизация

**Примеры:**

- `fetch_example.dart` - GET запрос с FutureBuilder
- `post_example.dart` - POST запрос
- `websocket_example.dart` - WebSocket клиент
- `auth_example.dart` - Аутентифицированный запрос
- `background_parsing.dart` - compute() для JSON

**Шаблоны:**

- `http_service.dart` - HTTP service шаблон
- `repository_template.dart` - Repository паттерн

---

### Flutter Testing

**Директория:** `flutter-testing/`

**Описание:** Комплексное руководство по тестированию Flutter приложений: unit, widget и integration тесты.

**Когда использовать:**

- Написание unit тестов для функций/методов/классов
- Создание widget тестов для проверки UI компонентов
- Разработка integration тестов для end-to-end тестирования
- Мокирование зависимостей и plugin взаимодействий
- Отладка частых ошибок тестирования
- Тестирование Flutter plugins с native кодом
- Запуск тестов в разных build modes

**Типы тестов:**

**Unit Tests:**

- Тестирование отдельных функций/классов
- Мокирование внешних зависимостей
- Избегание disk I/O и UI rendering
- Быстрое выполнение, высокая maintainability

**Widget Tests:**

- Тестирование UI виджетов
- Проверка пользовательских взаимодействий
- Тестирование разных ориентаций
- Валидация изменений состояния

**Integration Tests:**

- Тестирование полных user flows
- Проверка множества экранов/страниц
- Тестирование навигации
- Performance profiling

**Trade-offs:**

|                  | Unit   | Widget | Integration |
|------------------|--------|--------|-------------|
| Confidence       | Low    | Higher | Highest     |
| Maintenance cost | Low    | Higher | Highest     |
| Execution speed  | Quick  | Quick  | Slow        |

**Работа с Plugins:**

- Мокирование platform channels
- Тестирование app кода с plugins
- Тестирование самих plugins
- Native code тестирование

**Частые ошибки:**

- RenderFlex overflow
- Unbounded height/width
- setState during build
- Plugin crashes в тестах

**Build Modes:**

- **Debug** - разработка с hot reload
- **Profile** - анализ производительности
- **Release** - deployment (assertions disabled)

**Лучшие практики:**

- Test Pyramid (больше unit/widget, меньше integration)
- Descriptive test names
- Arrange-Act-Assert структура
- Test independence
- Mock external dependencies
- CI автоматизация

**Справочные материалы:**

- `unit-testing.md` - Unit тесты и mocking
- `widget-testing.md` - Widget finding и взаимодействия
- `integration-testing.md` - End-to-end тестирование
- `mocking.md` - Мокирование зависимостей
- `common-errors.md` - Решения частых ошибок
- `plugin-testing.md` - Тестирование plugins

---

### Flutter Backend-driven UI with Duit

**Директория:** `flutter-duit-bdui/`

**Описание:** Агентский workflow для интеграции, исправления, ревью и проверки BDUI-фреймворка [flutter_duit](https://pub.dev/packages/flutter_duit) во Flutter-приложениях.

**Когда использовать:**

- Интеграция flutter_duit в проект
- Создание и регистрация кастомных виджетов
- Регистрация компонентов
- Переопределения базовой функциональности фреймворка путем реализации capabilities
- Нужна справочная информацию по публичному API фреймворка

**Справочные материалы**

- [capabilities.md](./flutter-duit-bdui/references/capabilities.md) — Примечания к проектированию на основе capability и переопределению основных частей фреймворка.
- [troubleshooting.md](./flutter-duit-bdui/references/troubleshooting.md) - Примечания о распространенных проблемах интеграции фреймворков
- [environment_vars.md](./flutter-duit-bdui/references/environment_vars.md) — Примечания о доступных переменных окружения и их использовании.
- [public_api.md](./flutter-duit-bdui/references/public_api.md) — Примечания к публичному API драйвера
- <https://duit.pro/docs/en> — Официальный сайт с документацией

## 📁 Файловая структура

Каждый навык организован следующим образом:

```
skill-name/
├── SKILL.md              # Основное описание навыка
├── references/           # Справочная документация
│   ├── topic1.md
│   ├── topic2.md
│   └── ...
├── assets/              # Примеры кода и шаблоны
│   ├── examples/
│   ├── templates/
│   └── ...
└── scripts/            # Вспомогательные скрипты (опционально)
```

## 🚀 Как использовать

Этот репозиторий следует открытому формату [Agent Skills](https://agentskills.io/home) - стандарту для предоставления AI-агентам новых возможностей и экспертизы. Agent Skills - это папки с инструкциями, скриптами и ресурсами, которые агенты могут обнаруживать и использовать для выполнения задач более точно и эффективно.

### Совместимость

Навыки из этого репозитория могут использоваться любыми AI-ассистентами, поддерживающими формат Agent Skills, включая:

- Anthropic Claude (с поддержкой Agent Skills)
- Cursor IDE
- Другие совместимые инструменты разработки

### Преимущества Agent Skills

**Для разработчиков навыков:**

- Создайте навык один раз, используйте в множестве AI-инструментов
- Version control через Git
- Портативность между проектами и командами

**Для команд и организаций:**

- Захват организационных знаний в структурированном формате
- Стандартизация подходов к разработке
- Переиспользование лучших практик

**Для AI-агентов:**

- Расширяемая база знаний без переобучения
- Контекстно-зависимая экспертиза
- Повторяемые рабочие процессы

## 📊 Матрица применения навыков

| Задача | Навык | Когда использовать |
|--------|-------|-------------------|
| AGENTS.md / контекст репозитория | agents-md-generator | Создание/обновление AGENTS.md, структура монорепо |
| Локальная БД (Dart) | dart-drift | CLI, server-side, non-Flutter desktop |
| Локальная БД (Flutter) | flutter-drift | Flutter приложения, mobile/web/desktop |
| Адаптивный UI | flutter-adaptive-ui | Multi-platform, responsive layouts |
| Анимации | flutter-animations | Motion effects, transitions |
| Архитектура проекта | flutter-architecture | MVVM, feature-first, scalable structure |
| Мультиязычность | flutter-internationalization | Localization, translations, i18n |
| Навигация | flutter-navigation | Routing, deep linking, screen transitions |
| Backend-driven UI (BDUI) | flutter-duit-bdui | DUIT, server-driven UI, backend-driven screens |
| Сетевые запросы | flutter-networking | HTTP, WebSocket, REST API |
| Тестирование | flutter-testing | Unit, widget, integration tests |

## 📝 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🤝 Вклад в проект

Вклад в развитие навыков приветствуется! Пожалуйста:

- Следуйте [спецификации Agent Skills](https://agentskills.io/specification)
- Следуйте существующей структуре навыков в репозитории
- Добавляйте практические примеры в `assets/`
- Документируйте условия применения в `SKILL.md`
- Включайте best practices и справочные материалы в `references/`
- Используйте метаданные в frontmatter файлов `SKILL.md`

## 📚 Дополнительные ресурсы

### Agent Skills

- [Agent Skills - Официальный сайт](https://agentskills.io/home)
- [Спецификация формата Agent Skills](https://agentskills.io/specification)
- [Интеграция Agent Skills](https://agentskills.io/integrate-skills)
- [Agent Skills на GitHub](https://github.com/agentskills/agentskills)

---

**Версия:** 1.0  
**Последнее обновление:** Январь 2026
