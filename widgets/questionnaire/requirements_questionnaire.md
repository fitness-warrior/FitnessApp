
# Questionnaire Module — Requirements Specification

## 1. Document Purpose
- Summary: Define functional, non-functional, data, UI, validation, and acceptance criteria for the Questionnaire Module used during onboarding to collect fitness data for personalized plans and game balancing.
- Scope: Covers questionnaire flow, question definitions, input validation, temporary storage, output schema, UI constraints, performance, maintainability, and extension points.

## 2. Glossary
- Questionnaire Module: The onboarding component collecting user fitness data.
- Response Payload: Structured JSON produced when questionnaire completes.
- Mandatory question: Question that must be answered before completion.

## 3. Actors
- End User: Person completing the questionnaire.
- Client UI: Mobile app screens rendering questions.
- Backend / Account Service: Optional consumer of final JSON.

## 4. Functional Requirements
- FR-Flow-01: Present one question per screen.
  - AC-FR-Flow-01: Verify only a single prompt and its controls are visible when a question is shown.
- FR-Flow-02: Provide navigation controls: Next and Previous.
  - AC-FR-Flow-02: User can move forward/back without losing previously entered answers.
- FR-Flow-03: Display questionnaire progress (progress bar, percentage, or step).
  - AC-FR-Flow-03: Progress updates when navigating or answering.
- FR-Flow-04: Persist responses locally during the session.
  - AC-FR-Flow-04: Closing a question and returning retains inputs until session ends.
- FR-Flow-05: Detect completion when all mandatory questions are answered and expose Submit/Complete action.
  - AC-FR-Flow-05: Submit is enabled only when all mandatory answers are valid.
- FR-Question-01: Each question includes: unique ID, prompt, input type, options (if any), validation rules, and mandatory flag.
  - AC-FR-Question-01: UI renders metadata-driven question controls without hardcoded UI text.

## 5. Question Set (canonical)
- Q001 — Age
  - Type: Integer (input or slider)
  - Mandatory: Yes
  - Validation: 13 <= age <= 100
- Q002 — Fitness Goal
  - Type: Single Choice
  - Mandatory: Yes
  - Options: Fat Loss; Muscle Gain; Endurance Improvement; General Fitness; Athletic Performance; Injury Rehabilitation
- Q003 — Fitness Experience Level
  - Type: Single Choice
  - Mandatory: Yes
  - Options: Beginner; Intermediate; Advanced
- Q004 — Workout Frequency
  - Type: Single Choice or Slider
  - Mandatory: Yes
  - Options: 1-2 Days; 3 Days; 4 Days; 5 Days; 6+ Days
- Q005 — Workout Duration Preference
  - Type: Single Choice or Slider
  - Mandatory: Yes
  - Options: 20-30 Minutes; 30-45 Minutes; 45-60 Minutes; 60+ Minutes
- Q006 — Equipment Availability
  - Type: Multi-select
  - Mandatory: Yes
  - Options: Bodyweight Only; Dumbbells; Barbells; Resistance Bands; Gym Machines; Cardio Machines
- Q007 — Workout Location
  - Type: Single Choice
  - Mandatory: Yes
  - Options: Home; Gym; Outdoors; Mixed Locations
- Q008 — Training Preference
  - Type: Multi-select
  - Mandatory: Yes
  - Options: Strength Training; Cardio Training; HIIT; Flexibility / Mobility; Mixed Training
- Q009 — Injuries or Physical Limitations
  - Type: Multi-select with optional free-text for "Other"
  - Mandatory: No
  - Options: None; Knee Issues; Back Issues; Shoulder Issues; Joint Pain; Other (text)

## 6. Input Validation Requirements
- FR-Validation-01: Mandatory questions must be answered before permitting completion.
- FR-Validation-02: Numeric inputs must enforce defined min/max.
- FR-Validation-03: Multi-select mandatory questions must require at least one choice.
- FR-Validation-04: If "Other" is selected, a non-empty text detail must be provided.

## 7. Data Storage & Output
- DS-Temp-01: Responses shall be stored locally in-session (memory or secure ephemeral local storage) until submitted.
- DS-Output-01: Final response shall be emitted as JSON according to the schema below.
- DS-Privacy-01: Store minimal PII and follow platform storage best practices.

### JSON Output Schema
{
  "age": Integer,
  "fitnessGoal": String,
  "fitnessLevel": String,
  "workoutFrequency": String,
  "workoutDuration": String,
  "equipmentAccess": [String],
  "workoutLocation": String,
  "trainingPreference": [String],
  "injuries": [String],
  "injuryDetails": String|null
}

### Example Instance
{
  "age": 28,
  "fitnessGoal": "Muscle Gain",
  "fitnessLevel": "Intermediate",
  "workoutFrequency": "4 Days",
  "workoutDuration": "45-60 Minutes",
  "equipmentAccess": ["Dumbbells","Resistance Bands"],
  "workoutLocation": "Home",
  "trainingPreference": ["Strength","Flexibility / Mobility"],
  "injuries": ["None"],
  "injuryDetails": null
}

## 8. User Interface Requirements
- UI-Display-01: Each question screen shows: prompt, control(s), progress indicator, and navigation buttons.
- UI-Usability-01: Controls must be touch-friendly, fonts readable on mobile, and color contrast meet WCAG AA.
- UI-Responsive-01: Layout must adapt to mobile portrait/landscape and common screen sizes.

## 9. Non-Functional Requirements
- NFR-Perf-01: Question screens must render within 2 seconds on target devices.
- NFR-Reliability-01: User responses must not be lost during navigation or on temporary app backgrounding.
- NFR-Maintain-01: Question content and ordering must be configurable via data-driven structure (no hardcoded UI text).
- NFR-Security-01: Any persisted temporary data must be stored securely per platform guidelines.

## 10. Acceptance Criteria — Module Completion
- AC-Complete-01: All listed questions are implemented and configurable.
- AC-Complete-02: Navigation, progress, and validation work as specified.
- AC-Complete-03: Module outputs valid JSON matching the schema with tested example instances.
- AC-Complete-04: UI meets usability and accessibility minimums.
- AC-Complete-05: Temporary storage and recovery for the session are validated.

## 11. Traceability / IDs
- Functional requirements: `FR-` prefix.
- Validation requirements: `FR-Validation-`.
- Data/Storage: `DS-`.
- Non-functional: `NFR-`.
- Acceptance criteria: `AC-`.

## 12. Extensibility Requirements
- EX-01: New questions, answer types, and ordering must be addable via a JSON configuration file.
- EX-02: The module shall expose hooks/callbacks for integration with account creation and backend APIs.

## 13. Testing Notes
- Automated unit tests for:
  - Validation rules per question.
  - Serialization to JSON schema.
  - Navigation state preservation.
- Manual acceptance tests for accessibility and UI responsiveness.

## 14. Implementation Recommendation
- Use a JSON-driven config (question id, prompt, type, options, validation, mandatory).
- UI builds question screen from config; state held in a single in-memory model, serialized to JSON on completion.
- Optionally persist an encrypted local draft for session recovery.
