# Bidan Operational Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Bidan screens useful for triage, validation, PMT, and reporting with richer operational context.

**Architecture:** Keep Clean Architecture and Riverpod. Extend existing referral response fields from Laravel to Flutter entities; Flutter still only calls Laravel and never Flask.

**Tech Stack:** Flutter, Riverpod, Laravel REST API, widget tests.

---

### Task 1: Regression Tests

**Files:**
- Modify: `test/posyandu_app_test.dart`

- [ ] Add widget tests for Bidan referral cards showing age and BB/TB context.
- [ ] Add widget tests for referral detail showing validation context and ethical screening copy.
- [ ] Add widget tests for PMT stock cards showing stock/minimum/action context.

### Task 2: Backend Referral Context

**Files:**
- Modify: `backend/app/Http/Controllers/ApiController.php`
- Modify: `backend/tests/Feature/PosyanduMvpTest.php`

- [ ] Extend `/api/rujukan` rows with `tanggal_lahir`, `berat_badan`, `tinggi_badan`, and `tanggal_ukur`.
- [ ] Test that Bidan receives those fields from the referral list.

### Task 3: Flutter Referral Model

**Files:**
- Modify: `lib/features/bidan/domain/entities/referral.dart`
- Modify: `lib/features/bidan/data/models/bidan_models.dart`

- [ ] Add optional age/measurement source fields to `Referral`.
- [ ] Parse fields from Laravel JSON.

### Task 4: Bidan UI

**Files:**
- Modify: `lib/features/bidan/presentation/pages/bidan_dashboard_page.dart`

- [ ] Redesign referral rows to show age, measurement, status, and risk.
- [ ] Redesign referral bottom sheet to show child context, measurement, validation decision, note, and CTA.
- [ ] Redesign PMT stock rows to show stock/minimum and low-stock state more clearly.

### Task 5: Verification

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `php artisan test`.
- [ ] Run ML API unittest.
- [ ] Push mobile and backend changes; deploy backend to VPS if Laravel changed.
