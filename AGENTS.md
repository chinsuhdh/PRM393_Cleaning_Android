# Repository Agent Guidance

## Repo Shape

- Mobile frontend lives in this Flutter repo and builds the CleanAI Android/iOS app.
- Keep shared app infrastructure in `lib/core`, API/data access in `lib/data`, and screens/widgets in `lib/ui`.
- Use Riverpod for state management, GoRouter for navigation, and Dio for HTTP work unless existing code in the touched area uses a different local pattern.
- Reusable Codex skills live in `.agents/skills`.
- Use `..\plan.md` for shared plan-driven work unless a repository-local plan file is added later.

## Default Workflow

- Read `..\plan.md` before implementing plan-driven work.
- Keep changes scoped to the explicit request and preserve the existing Flutter project structure.
- Use `$flutter-clean-code-architect` for project-specific architecture, file-size, constants, abstraction, and verification decisions.
- Use `$flutter-apply-architecture-best-practices` when adding or reorganizing UI, state, data, repository, or service layers.
- Use `$flutter-add-widget-test` for focused widget coverage and `$flutter-add-integration-test` for app-flow coverage.
- Use the other installed Flutter skills when the task matches their names, especially routing, HTTP, localization, responsive layout, layout fixes, widget previews, and JSON serialization.
- For review, impact analysis, or broad changes, prefer the installed `code-review-graph` CLI over MCP/hooks:
  - Run `code-review-graph update --brief --base HEAD~1` when a graph already exists.
  - Run `code-review-graph build` first if the graph is missing or stale.
  - Run `code-review-graph detect-changes --brief --base HEAD~1` for read-only impact context after the graph is current.
  - If graph commands fail, report the failure and continue with direct repo inspection.

## Verification

Run the smallest meaningful checks for the change. Flutter checks normally include:

```powershell
flutter pub get
flutter analyze
flutter test
```

For Android packaging or platform changes, add:

```powershell
flutter build apk --debug
```

## Branches And Commits

- Do not create a new branch unless the user explicitly asks, except when the current branch is `main` or `master`.
- If the current branch is `main` or `master` and the user asks to commit/package work, create a focused task branch before committing.
- If already on a non-main task branch, keep using the current branch unless the user asks for a different branch.
- Commit only after implementation and verification are complete.
- Commit summaries should cover: summary, key changes, checks run, code-review-graph context used, and known gaps.
- Push only when the user explicitly asks.
