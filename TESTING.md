# Flutter testing

## Commands

```powershell
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter test test\unit
flutter test test\widget
.\tool\run-e2e.ps1
```

The E2E command requires Docker and a running Android emulator. It creates an isolated PostgreSQL database and starts the backend on port `5001`; Android reaches it through `10.0.2.2`.

The analyzer currently reports legacy warnings, so CI fails on analyzer errors while existing warnings are paid down incrementally.

## Adding a test

- Put model, formatter, repository, and Riverpod logic tests in `test/unit`.
- Put screen rendering and interaction tests in `test/widget`.
- Put device-level flows in `integration_test`.
- Inject `dioProvider` or construct repositories with a test `Dio`; do not add new calls to the deprecated `DioClient.instance` accessor.
- Store reusable JSON responses in `test/fixtures` and helpers in `test/support`.
- Write test descriptions in Vietnamese and prefix them with IDs such as `[UT-FE-SERVICE-001-01]` or `[WT-FE-BOOK-001-01]`.
