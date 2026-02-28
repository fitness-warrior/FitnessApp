# User Stories — Exercise Detail & Video Feature

This document contains user stories, priorities, and acceptance criteria for the exercise detail + video feature.

---

## Overview
Feature purpose: Allow users to discover, view and follow exercise instructions (text + video), and allow admins to manage exercise content and link exercises to workout plans.

---

## Story format
As a <role>, I want <action>, so that <benefit>.

Each story includes priority (MUST / SHOULD / NICE-TO-HAVE), acceptance criteria, and an implementation mapping to endpoints/components.

---

### 1) View exercise detail (MUST)
- Story: As a user, I want to open an exercise and read a description and view a how-to video so that I can perform the exercise correctly.
- Acceptance criteria:
  - Given an exercise exists, when the app requests GET `/api/exercises/{exer_id}`, then the response returns `exer_name`, `exer_descrip`, `exer_vid` (may be empty), `exer_equip`, and optional `plan` (sets/reps).
  - The frontend displays the description text immediately.
  - If `exer_vid` is a non-empty, valid URL, the UI provides a visible action to open/play that video; otherwise a "No video available" placeholder is shown.
  - Response is JSON and returns 200 for existing exercises, 404 if not found.
- Mapping: `exercises_api.py` GET `/api/exercises/<id>`, `ExerciseDetailWidget`.

---

### 2) List & filter exercises (MUST)
- Story: As a user, I want to browse exercises filtered by equipment, body area, or type so that I can find exercises I can perform.
- Acceptance criteria:
  - GET `/api/exercises` supports query params: `equipment[]`, `area`, `type`, `name`.
  - When filter params are sent, returned list only contains exercises matching those filters.
  - Query supports multiple `equipment` values (IN semantics).
  - Response is 200 with an array of exercise objects.
- Mapping: `exercises_api.py` GET `/api/exercises`, `ExerciseService.listExercises()`.

---

### 3) Pre-filter by user equipment (MUST)
- Story: As a user, I want the exercise list pre-filtered by equipment I own so that I see performable exercises by default.
- Acceptance criteria:
  - Frontend calls `auto_equipment(user_id)` then GET `/api/exercises?equipment=...` before rendering the list.
  - If user has no equipment, UI shows items requiring `Bodyweight Only` and a message explaining optional equipment-based filters.
- Mapping: `exersie.py` `auto_equipment(user_id)` and frontend integration.

---

### 4) Add new exercise (ADMIN - MUST)
- Story: As an admin, I want to create a new exercise with description, equipment and an optional video URL so that users can view it in the app.
- Acceptance criteria:
  - POST `/api/exercises` accepts JSON with required fields `exer_name`, `exer_body_area`, `exer_type`, `exer_equip`; optional `exer_descrip`, `exer_vid`.
  - Successful creation returns 201 and payload `{ "exer_id": <id> }`.
  - Invalid payload (missing required fields or invalid enum values) returns 400 and does not insert.
- Mapping: `exercises_api.py` POST `/api/exercises`, `AdminAddExercise` widget.

---

### 5) Link exercise to plan (ADMIN - SHOULD)
- Story: As a plan owner/admin, I want to link an exercise to a work plan with sets and reps so the plan shows exact instructions.
- Acceptance criteria:
  - POST `/api/plan_exercises` accepts `{ work_id, exer_id, sets, reps }` and returns 201 with `plan_exer_id`.
  - After linking, GET `/api/exercises/{exer_id}` includes `plan` containing the `sets`/`reps` for that plan entry (or the plan list when multiple plans exist).
- Mapping: `exercises_api.py` POST `/api/plan_exercises` and `plan_exercise` table.

---

### 6) Edit exercise (ADMIN - SHOULD)
- Story: As an admin, I want to edit exercise details (text/video/equipment) so I can keep content accurate.
- Acceptance criteria:
  - PATCH or PUT `/api/exercises/{exer_id}` accepts allowed fields and returns 200 on success.
  - Invalid values return 400; non-existent `exer_id` returns 404.
- Mapping: API extension (not implemented yet), admin UI form extension.

---

### 7) Graceful fallback when video invalid or missing (MUST)
- Story: As a user, I want to still access the description when the video is missing or invalid so I can perform the exercise.
- Acceptance criteria:
  - If `exer_vid` is empty, UI shows placeholder and description remains visible.
  - If `exer_vid` exists but opening it fails, UI shows a non-blocking error and retains the description.
- Mapping: `ExerciseDetailWidget` behavior.

---

### 8) Prevent duplicate exercise entries (NICE-TO-HAVE)
- Story: As an admin, I want the system to warn or prevent creating duplicate exercises (same name/body area) to avoid clutter.
- Acceptance criteria:
  - POST `/api/exercises` returns 409 conflict if an exercise with same `exer_name` and `exer_body_area` exists (or returns existing `exer_id`).
- Mapping: API validation logic (optional enhancement).

---

### 9) Audit & logging for admin actions (NICE-TO-HAVE)
- Story: As a product owner, I want admin create/edit actions logged so I can review content changes.
- Acceptance criteria:
  - Admin POST/PATCH responses are persisted to an audit table or logged with `admin_id`, action, timestamp.
- Mapping: Backend logging/audit improvements.

---

## Prioritization summary (MUST / SHOULD / NICE-TO-HAVE)
- MUST: 1 (View), 2 (List/Filter), 3 (Pre-filter), 4 (Add exercise), 7 (Fallback)
- SHOULD: 5 (Link to plan), 6 (Edit exercise)
- NICE-TO-HAVE: 8 (Duplicate prevention), 9 (Audit logging)

---

## QA checklist (quick)
- [ ] GET `/api/exercises` returns list and filters correctly.
- [ ] GET `/api/exercises/{id}` returns description and `exer_vid` when present.
- [ ] POST `/api/exercises` validates fields and returns 201 for valid data.
- [ ] Admin UI can create exercises and new items appear in lists.
- [ ] `auto_equipment(user_id)` returns equipment names and frontend uses them to filter.

---

End of user stories document.
