---
name: flutter-clean-code-architect
description: Project-specific clean-code and architecture guidance for the CleanAI Flutter app. Use when Codex is implementing, refactoring, reviewing, or generating Flutter/Dart code in PRM393_Cleaning_Android and must preserve the existing lib/core, lib/data, lib/ui structure, keep files focused, avoid magic values, choose the minimum useful abstraction, and run appropriate Flutter verification.
---

# Flutter Clean Code Architect

## Operating Mode

Work as a pragmatic Flutter architect. Preserve the app's current structure unless the user explicitly asks for a redesign.

Before changing code:

- Inspect nearby widgets, providers, routes, models, services, repositories, tests, and naming conventions.
- Prefer the repository's conventions over generic Flutter examples.
- Identify the narrowest change that solves the explicit request.
- Use official Flutter, Dart, Riverpod, GoRouter, Dio, or package documentation when an API is unfamiliar, version-sensitive, recently changed, or not clearly demonstrated by local code.
- Use `$flutter-apply-architecture-best-practices` for broader feature layering decisions.
- Use `$flutter-add-widget-test` or `$flutter-add-integration-test` for test strategy when behavior changes.

## Structure Rules

- Keep shared configuration, theme, routing, constants, and network clients in `lib/core`.
- Keep API models, repositories, and services in `lib/data`.
- Keep presentation code in `lib/ui`, organized by feature plus shared widgets.
- Keep widgets focused on rendering and local UI interaction. Put app state, async loading, and business decisions behind Riverpod providers, not directly in large widget build methods.
- Keep API calls and serialization out of widgets.
- Do not move files, rename public classes, or reorganize folders unless required by the task.
- Avoid unrelated refactors, formatting churn, and architectural cleanup outside the requested behavior.

## File Size And Decomposition

- Keep implementation files under 500 lines when practical.
- Split oversized files along existing Flutter boundaries: screen widgets, reusable child widgets, providers, repositories, services, models, or route definitions.
- Allow justified exceptions for generated files, platform files, large static maps, localization output, and framework entrypoints.
- Do not create a new abstraction only to satisfy the line limit. Prefer clearer local extraction that matches the project.
- Refactor or delete unnecessary code only when it is directly related to the requested change and verified as unused.

## Constants And Magic Values

- Avoid unexplained literals for route names, API paths, roles, storage keys, asset paths, durations, breakpoints, text styles, colors, limits, status strings, and error codes.
- Put meaningful shared values in the closest existing constants, enum, theme, route, options, or domain type.
- Create a new constants or enum type only when the value is reused, part of a contract, or easier to audit when named.
- Leave obvious local values inline when naming them adds noise, such as `0`, `1`, simple loop bounds, or one-off test data.

## Abstraction Discipline

- Implement the minimum abstraction required by the explicit problem.
- Do not add single-use base widgets, factories, generic helpers, extension methods, service locators, or future plugin points.
- Reuse existing providers, repositories, services, and widgets when they already express the dependency boundary.
- Add a new abstraction only when it removes real duplication, isolates an actual external dependency, matches an existing pattern, or is required for testability.

## Quality Bar

- Keep behavior explicit and traceable from route or widget entrypoint to provider, repository, service, and model.
- Prefer readable control flow over clever compression.
- Keep loading, empty, error, and success states consistent with nearby screens.
- Keep validation and error handling consistent with nearby code.
- Add or update focused tests when the repo has relevant coverage or when the change affects shared behavior, app flows, providers, serialization, routing, or reusable widgets.
- Run the smallest meaningful Flutter verification command available, and report warnings or checks that could not be run.
