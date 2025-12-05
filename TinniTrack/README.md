# Tinnitus Research and Tracking App

## 1. Project Overview
We are building an iOS research app that measures tinnitus loudness using calibrated headphone‑based psychoacoustic tasks. Participants complete pitch‑matching and loudness‑matching tasks that produce scientifically interpretable, repeatable data.

**Data collection:**
*   Baseline hearing thresholds (via HealthKit Audiograms).
*   Longitudinal Tinnitus Loudness-Match (LM) and Pitch-Match (PM) measurements.
*   Device, volume, and environmental noise metrics.

## 2. Why we’re building it
*   **Objectivity:** Tinnitus is subjective; standardized calibration (dB SL/HL) allows for inter-subject and longitudinal comparison.
*   **Hardware Consistency:** Apple devices (specifically AirPods Pro) provide known acoustic profiles, enabling clinical-grade accuracy outside a sound booth.
*   **Temporal Resolution:** Daily measurements capture the volatile nature of tinnitus, revealing patterns missed in infrequent clinical visits.

## 3. V1 User Journey

### A. Onboarding & Permissions
*   **eConsent:** Displays IRB-approved consent forms. Upon agreement, generates a signed consent PDF and logs a ConsentEvent (Participant ID, Version, Timestamp) to the backend.
*   **HealthKit Integration:** Allows importing the user’s Apple-calibrated audiogram to compute baseline thresholds and derive dB SL.
*   **Notification permission:** Requests permission for local push notifications to trigger adherence reminders.

### B. Baseline Hearing Test
*   **Audiogram Check:** The app queries HealthKit for an existing valid audiogram.
*   **The "Apple Hearing Test" Flow:** If no audiogram is present, the app instructs the user to complete the native Apple Hearing Test (accessible via iOS Settings with compatible AirPods).
*   **Import:** Upon completion, the app imports the audiogram data to calculate Sensation Level (dB SL) offsets.

### C. The Loudness-Match (LM) Task
*   **Trigger:** Push notification sent during a time window (20-minute expiry).
*   **Device Validation:** Verifies output route is set to supported hardware (e.g., AirPods Pro 2/3).
*   **Environmental Noise Check:** Uses the microphone to ensure ambient noise is below a specific threshold (e.g., < 40 dBA).
*   **Task Execution:** User adjusts a 1,000 Hz pure tone to equal their tinnitus loudness. This is repeated 3 times to derive a Mean Loudness Value.

### D. Study Protocol (Adherence)
*   **Frequency:** 4 measurements per day for 14 days.
*   **Dropout Logic:** Participants missing >X% of checkpoints (configurable parameter) are flagged as "Non-Compliant" in the researcher dashboard.

## 4. Scientific & Engineering Core
*   **Calibration:** Implements RETSPL tables to convert generic dB SPL to clinical dB HL (Hearing Level) and dB SL (Sensation Level).
*   **Hardware Gating:** Allow-list enforcement for headphones with known sensitivity profiles to prevent uncalibrated data collection.

## 5. System Architecture

### Frontend (iOS)
*   **UI/UX:** SwiftUI
*   **Frameworks:**
    *   **HealthKit:** For audiogram retrieval.
    *   **ResearchKit (StanfordBDHG Fork):** We use [StanfordBDHG’s SPM fork of Apple ResearchKit](https://github.com/StanfordBDHG/ResearchKit).
    *   **Stanford Spezi:** A free and open-source framework for rapid development of modern, interoperable digital health applications. [Website](https://spezi.stanford.edu) | [GitHub](https://github.com/StanfordSpezi).

### Backend
*   **Supabase:** PostgreSQL + Auth.

## 6. Backend Responsibilities
*   **Authentication:** Anonymous login or email/password via Supabase Auth to secure participant data.
*   **Row Level Security (RLS):** Policies ensuring users can only insert/read their own data, while researchers can read all anonymized data.
*   **Data Ingestion:** API endpoints to receive JSON payloads from the Stanford Spezi module.
*   **Compliance:** Storing consent timestamps separately from medical data (if required by IRB).

## 7. Version Plan

### Version 1 (MVP)
*   Consent + permissions
*   Headphone gating
*   Quiet-room gating
*   Prompt Apple hearing test and import audiogram
*   Single-frequency (1kHz) LM
*   Daily local push notifications

### V2 (Future Work)
*   In-app hearing test (bypassing Apple native test)
*   Multi-frequency PM (Pitch Match) testing. Have the user both frequency match and loudness math their tinnitus.
*   Add a wider range of allowed earphone models.
*   EMA Questionnaires.
*   Researcher dashboard.

---

## Appendix: Scientific Background & Vocabulary

### Decibels, Loudness, and Hearing Background

**What sound is:**
Sound is vibrating air creating pressure waves.
*   **Frequency (Hz):** cycles per second → pitch
*   **Amplitude:** size of pressure swings → loudness
*   **Phase:** timing within the cycle
*   **Pressure:** Measured in Pascals (Pa). Speech is a few mPa; threshold of hearing ≈ 20 µPa.
*   **RMS amplitude:** The standard measure for loudness.

**How do we measure loudness:**
The ear reacts to sound logarithmically. Large physical changes in sound often feel like small changes in loudness. Decibels (dB) are a way to describe sound levels on this logarithmic scale. A dB value always compares a sound to a reference point.

### The Decibel Scales (Critical for Calibration)
*   **dB SPL (Sound Pressure Level):** Absolute loudness relative to 20 µPa (physical pressure). Nearly all real‑world sound numbers use dB SPL.
*   **dB HL (Hearing Level):** Normalized clinical scale where "0 dB HL" represents the average human hearing threshold for a specific frequency. Corrects for the ear's varying sensitivity across pitches (e.g., quiet tones at 250 Hz are harder to hear than at 1000 Hz).
*   **dB SL (Sensation Level):** Relative loudness above the user's individual threshold. It expresses loudness relative to your personal ability to hear at a specific frequency.
    *   *Example:* If a user hears a tone at 10 dB HL, and plays a sound at 40 dB HL, the sound is 30 dB SL.

### RETSPL: The Glue Between SPL and HL
**RETSPL = Reference Equivalent Threshold Sound Pressure Level.**
It’s a table (per frequency) giving the SPL that corresponds to 0 dB HL for a specific transducer measured on a standard ear coupler.
*   **Convert HL → SPL:** `SPL = HL + RETSPL(f, transducer)`
*   **Convert SPL → HL:** `HL = SPL − RETSPL(f, transducer)`

Apple’s ResearchKit framework gives us RETSPL tables and device mappings for certain Apple headphones so we can get clinically meaningful dB HL from a phone.

### Other Vocabulary
*   **EMA:** Ecological Momentary Assessment — brief, in‑the‑moment self‑report questions (e.g., tinnitus loudness, annoyance, mood).
*   **Hearing threshold:** (for a given frequency & ear) = the quietest level that a person detects reliably (e.g., 50% of trials).
*   **Audiogram:** a plot of hearing threshold vs frequency for the left and right ear.
