# AGENTS Instructions for Contributing to `ello.ai`

This document provides explicit instructions for AI agents contributing to the `ello.ai` codebase. All agents must follow these conventions to ensure high-quality, consistent contributions.

---

## 🛠️ Code Authoring

1. **Language & Frameworks**
   - Use **Dart** and **Flutter** for all implementations.
   - Follow Flutter's official best practices for UI and state management.

2. **Code Formatting**
   - Run `dart format .` on the project root before submitting code.
   - Do not include unformatted or partially formatted code.

3. **Static Analysis**
   - Run `flutter analyze`.
   - Fix **all** warnings and errors before proceeding.

4. **Documentation**
   - Document **all public classes, methods, and constants**.
   - Use Dart-style doc comments (`///`) with clear intent and context.

---

## 🌿 Branch Naming

- Use **descriptive, conventional commit-compliant** names.
- **Do not** include prefixes like `codex/` or `agent/`.
- Format: `<type>/<feature-description-kebab-case>`
  - Examples:
    - `feat/chat-ui-pagination`
    - `fix/missing-avatar-url`
    - `refactor/session-cache-handler`

---

## 📦 Commit Messages

- Use [Conventional Commit](https://www.conventionalcommits.org/) style.
- Format:
  `<type>(optional-scope): short description`

  `[optional longer explanation]`

- Allowed types:
  - `feat`: New feature
  - `fix`: Bug fix
  - `chore`: Maintenance or tooling change
  - `refactor`: Code reorganization without behavior change
  - `test`: Add or update tests
  - `docs`: Documentation only

**Examples:**
```
feat(auth): add OTP verification flow
fix(api): handle 401 errors gracefully
chore: update dependencies
```

---

## 🔁 Pull Request Creation

- PR **title** must match the conventional commit format.
- PR **description** must include:
  - Summary of what the change does
  - List of key files affected (optional but recommended)
  - Test coverage or validation steps taken

**Example PR:**
```
Title: feat(messages): add infinite scroll to chat view

Description:

Implements lazy loading of messages

Uses ScrollController to trigger batch loads

Affects: chat_screen.dart, chat_repository.dart
```

---

## ✅ Validation & Tests

1. **Test Requirements**
   - Write tests for any new logic, widget, or data layer code.
   - Run all tests using `flutter test` before creating a PR.
   - Do not commit with failing or skipped tests unless annotated with a reason.

2. **Manual Testing (if applicable)**
   - Use `flutter run` to manually verify changes that affect UI or device behavior.

---

## 🔐 Secrets Handling

- Do not include any hardcoded secrets, tokens, or credentials.
- Use placeholders and ensure `.env` or config files are ignored via `.gitignore`.

---

## 🗂️ Project Structure Rules

- Place new features under `lib/features/<name>`.
- Avoid flattening folder hierarchy.
- Use barrel exports (`index.dart`) only where it simplifies imports.

---

## 🧠 Agent Behavior Rules

- Avoid modifying unrelated files.
- Keep changes **atomic and scoped**.
- If unsure, request review via comment in the PR.
- Ensure all generated code is consistent, clean, and tested.

---

## 📌 CI Requirements

- Ensure your PR passes formatting, analysis, and test checks in CI.
- If CI fails, do not request review until resolved.

---

**Agents not following this guide may be restricted from future contributions.**
