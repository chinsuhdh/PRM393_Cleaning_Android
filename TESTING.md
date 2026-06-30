# Flutter testing

## Commands

```powershell
# Run every unit, widget, and headless integration test
flutter test

# Run individual checks
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test test\unit --coverage
flutter test test\widget
flutter test test\integration
```

Flutter integration tests run headlessly. They combine screens, Riverpod providers, repositories, models, mocked HTTP, and test platform adapters without an Android emulator or a live backend.

The analyzer currently reports legacy warnings, so CI fails on analyzer errors while existing warnings are paid down incrementally.

## Adding a test

- Put model, formatter, repository, and Riverpod logic tests in `test/unit`.
- Put isolated screen rendering and interaction tests in `test/widget`.
- Put multi-layer headless application flows in `test/integration`.
- Put reusable JSON responses in `test/fixtures` and shared fakes or harnesses in `test/support`.
- Inject `dioProvider` or construct repositories with a test `Dio`; do not add new calls to the deprecated `DioClient.instance` accessor.
- Replace GPS, image picker, secure storage, notifications, and other platform dependencies with test adapters.
- Write test descriptions in Vietnamese and prefix them with IDs such as `[UT-FE-SERVICE-001-01]`, `[WT-FE-BOOK-001-01]`, or `[IT-FE-AUTH-001-01]`.

## CI

Pull requests and default-branch pushes run analysis and `flutter test` as separate checks. The debug APK is built only after both checks pass.
