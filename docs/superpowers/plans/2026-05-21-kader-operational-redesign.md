# Kader Operational Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Kader flow feel like a real Posyandu work surface: richer child rows, faster measurement actions, useful session mode, and less dated shared UI.

**Architecture:** Keep the current Clean Architecture and Riverpod structure. This pass is presentation-heavy and uses existing Kader entities/API data; no Flutter-to-Flask calls and no new backend endpoints.

**Tech Stack:** Flutter, Riverpod, existing Laravel REST API, widget tests.

---

### Task 1: Kader Regression Tests

**Files:**
- Modify: `test/posyandu_app_test.dart`

- [ ] Add widget tests proving that Balita rows show age/last measurement context, the child action sheet exposes profile wording/history, and the Sesi tab is a work queue rather than a duplicate empty page.
- [ ] Run `flutter test test\posyandu_app_test.dart --plain-name "Kader registry rows"` and confirm the test fails before implementation.

### Task 2: Shared Row Alignment

**Files:**
- Modify: `lib/shared/widgets/ledger_widgets.dart`

- [ ] Update `LedgerListRow` so trailing content and chevron are vertically centered and visually grouped.
- [ ] Keep tap target comfortable and preserve existing caller API.

### Task 3: Kader Balita Registry

**Files:**
- Modify: `lib/features/kader/presentation/pages/kader_dashboard_page.dart`

- [ ] Reposition `Tambah Balita` as a full-width/clearly grouped quick action near search instead of a cramped header button.
- [ ] Make child rows display age, mother name, last BB/TB, and session status using existing entity fields.
- [ ] Rename ambiguous `Edit data` to `Edit profil balita`.

### Task 4: Kader Action Sheet and Sesi Mode

**Files:**
- Modify: `lib/features/kader/presentation/pages/kader_dashboard_page.dart`

- [ ] Add child detail context to the bottom sheet: age, last measurement, and recent history preview.
- [ ] Turn the `Sesi` tab into “Kerja hari ini”: active session summary, measured/not-yet-measured counts, and quick access to the next child.

### Task 5: Verification

**Files:**
- Test: `test/posyandu_app_test.dart`

- [ ] Run `dart format lib\features\kader\presentation\pages\kader_dashboard_page.dart lib\shared\widgets\ledger_widgets.dart test\posyandu_app_test.dart`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Prefer `flutter run` for emulator iteration; build APK only for install/share/demo handoff.
