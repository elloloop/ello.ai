# CLAUDE.md

## How I expect you to write code

**No shortcuts. "Simple" never means "sloppy."** A small diff that hardcodes,
duplicates, or skips a test isn't simpler — it's deferred cost.

1. **Fix causes, not symptoms.** Find the root cause before fixing. If you're
   applying a workaround, say so explicitly and explain why. Never swallow an
   exception or silence an error to make a problem disappear.

2. **Think about consequences.** Before changing shared or widely-used code,
   trace its callers and the invariants they rely on. A fix that's locally
   correct but breaks something elsewhere — now or later — is not a fix.

3. **SOLID, sensibly.** One responsibility per class/widget/function. Separate
   pure logic from I/O so it can be tested. Inject dependencies that cross a
   boundary so they're mockable. Don't add abstractions for things that don't
   cross a boundary.

4. **DRY about knowledge, not appearance.** Don't duplicate a rule or decision.
   Code that merely looks similar but changes for different reasons stays
   separate. When unsure, prefer duplication over a premature/wrong abstraction.

5. **No hardcoded values.** No magic numbers or strings inline — give them
   names. Environment/tenant/feature-specific values go in typed config in
   application code, never scattered literals, never the database.

6. **Readable & maintainable.** Clear names, short flat functions, early
   returns over deep nesting. Comments explain *why*, not *what*. Match the
   existing style of the file you're editing.

7. **Testable, and prove it.** Ship a test for behavior you add or change. If
   something is hard to test, that's a design smell — restructure until it
   isn't. "Works but can't be tested" means it isn't done.

A change is done only when: the cause (not a symptom) is fixed, no new hardcoded
values, a test covers it, and the analyzer/formatter are clean.

## Project facts

> Keep these current as the repo evolves; only write what you've confirmed.

- **Setup command:** `flutter pub get`
- **Analyze/lint command:** `flutter analyze --fatal-infos --fatal-warnings`
- **Test command (all):** `flutter test`
- **Test command (single file/test):** `flutter test test/path/to/file_test.dart` (add `--name "<test name>"` for a single case)
- **Format command:** `dart format .` (CI gate: `dart format --set-exit-if-changed .`)
- **Run an app:** `flutter run -d chrome` (web); `flutter run -d <device>` for other platforms
- **Repo layout:** `lib/` Flutter/Dart app source (`lib/src/{core,llm_client,services,models,ui,utils,generated}`); `protos/` proto definitions; `server/` sample Go gRPC server; `server_dart/` Dart dev-tool server (excluded from analysis); `test/` Flutter tests; `tools/` & `scripts/` proto-gen and pre-push helpers; `android/ios/web/macos/windows/linux/` platform runners
- **State management / data layer:** Flutter + Riverpod (`flutter_riverpod`) for state; gRPC (`grpc`/`protobuf`) clients in `lib/src/services` and `lib/src/llm_client` talk to the backend; provider-based `ChatClient` abstraction per LLM provider
- **Generated files NOT to hand-edit:** `lib/src/generated/` (proto/gRPC output: `*.pb.dart`, `*.pbenum.dart`, `*.pbgrpc.dart`, `*.pbjson.dart`); regenerate via `flutter pub run build_runner build --delete-conflicting-outputs` or `tools/generate_protos.sh`
- **Other gotchas:** Run `./scripts/pre-push-check.sh` before pushing (mirrors CI: analyze, format, test, web build, plus Go server checks); CI is `.github/workflows/pr-checks.yml` targeting `main`/`develop`; `main` is branch-protected (status checks + 1 approval); pinned Flutter 3.22.0 / Dart SDK >=3.2.0 <4.0.0; new features go under `lib/features/<name>` (per AGENTS.md); never commit secrets — use `.env`/in-app settings (no `OPENAI_API_KEY` falls back to a built-in mock model)
