# Tinnitus Research and Tracking App

## 1. Project Overview
We are building an iOS research app that measures tinnitus loudness using calibrated headphone‑based psychoacoustic tasks. Participants complete pitch‑matching and loudness‑matching tasks that produce scientifically interpretable, repeatable data.

**Data collection:**
*   Baseline hearing thresholds (via HealthKit Audiograms).
*   Longitudinal Tinnitus Loudness-Match (LM) and Pitch-Match (PM) measurements.

## 2. Why we’re building it
*   **Objectivity:** Tinnitus is subjective; standardized calibration (dB SL/HL) allows for inter-subject and longitudinal comparison.
*   **Hardware Consistency:** Apple devices (specifically AirPods Pro) provide known acoustic profiles, enabling clinical-grade accuracy outside a sound booth.
*   **Temporal Resolution:** Daily measurements could capture the volatile nature of tinnitus, revealing patterns missed in infrequent clinical visits.

## 3. V1 User Journey

### A. Authentication (Login / Sign Up)
Upon downloading the app, the user is prompted to either **Log In** or **Sign Up**.

*   **Log In:** If the user already has an account, they authenticate and proceed into the app.
*   **Sign Up:** If the user does not have an account, they complete account creation. During signup we collect:
    *   Name
    *   Date of birth (DOB)
    *   Sex

Once the account is created (or the user logs in), the user is taken to the **Home Dashboard**.

### B. Home Dashboard (Studies List)
The Home Dashboard shows a list of **open studies currently recruiting**.

*   If the user is **not enrolled** in a study, selecting a study displays:
    *   Study description
    *   Inclusion criteria
    *   Exclusion criteria
*   The user can then choose to:
    *   **Enroll** in the study, or
    *   **Exit** (return to the studies list)

### C. Enrollment & eConsent
If the user chooses to enroll, they are prompted with an **eConsent** flow.

*   Upon agreement/submission, the app generates a signed consent PDF and logs a ConsentEvent (Participant ID, Version, Timestamp) to the backend.
*   After eConsent is completed, the user is taken to the **Study Home Page**.

### D. Study No. 1: Audiogram Import (HealthKit) Prerequisite
For Study No. 1, the first requirement is importing an **audiogram from HealthKit**.

*   **Audiogram Check:** The app queries HealthKit for an existing valid audiogram.
*   **If no audiogram is available:** the app prompts the user to complete a hearing test from the native Apple flow (via **Apple Settings** or the **Health app**, depending on iOS version/device).
*   **Import:** Once available, the app imports the audiogram data and proceeds to enable the study tasks.

### E. Study No. 1: Loudness-Match (LM) Tasks
Users complete loudness-matching tasks at specific times of day.

*   **Task execution:** Each task follows a structured validation and measurement flow:

    1.  **Headphone gating (AirPods Pro 2 required):**
        *   When the user taps **Start Task**, the app verifies the connected audio output device.
        *   Only **AirPods Pro (2nd generation)** are permitted for Study No. 1.
        *   If the correct headphones are **not connected**, the task cannot proceed.
            *   The user is shown a blocking message instructing them to connect AirPods Pro (2nd generation).
            *   The task remains locked until the correct headphones are detected.
        *   If the correct headphones are connected, the app proceeds to environmental validation.

    2.  **Quiet-room gating (environmental noise check):**
        *   The user is prompted to confirm they are in a quiet environment.
        *   The app measures ambient environmental noise using the device microphone.
        *   A predefined environmental threshold (X dB SPL, to be finalized during validation testing) determines acceptability.
        *   If environmental noise exceeds the threshold:
            *   The task cannot begin.
            *   The user is instructed to move to a quieter location.
            *   Ambient noise is continuously monitored.
        *   Once environmental noise falls below the threshold:
            *   The task becomes available to start.

    3.  **Continuous monitoring during task:**
        *   Environmental noise continues to be monitored throughout the Loudness-Match task.
        *   If ambient noise rises above the allowed threshold at any point:
            *   A visible on-screen alert indicates that the environment is too loud.
            *   Tone adjustment is temporarily paused or disabled.
        *   When environmental noise returns below the threshold:
            *   The alert automatically disappears.
            *   The user may resume the task.

    4.  **Loudness-matching procedure:**
        *   The user adjusts the volume of a **1,000 Hz pure tone** until it matches their tinnitus loudness.
        *   The match is recorded in calibrated units (dB HL and/or dB SL).
        *   The user submits the match and receives a confirmation that the task has been completed.

## 4. Scientific & Engineering Core
*   **Calibration:** Implements RETSPL tables to convert generic dB SPL to clinical dB HL (Hearing Level) and dB SL (Sensation Level).
*   **Hardware Gating:** Allow-list enforcement for headphones with known sensitivity profiles to prevent uncalibrated data collection.

## 5. System Architecture

### Frontend (iOS)
*   **UI/UX:** SwiftUI
*   **Frameworks:**
    *   **HealthKit:** For audiogram retrieval.
    *   **ResearchKit (StanfordBDHG Fork):** We use [StanfordBDHG’s SPM fork of Apple ResearchKit](https://github.com/StanfordBDHG/ResearchKit).

### Backend
*   **Supabase:** PostgreSQL + Auth.

## 6. Backend Responsibilities
*   **Authentication:** Email/password login and account signup via Supabase Auth. Users authenticate by logging in to an existing account or signing up for a new account (collecting name, DOB, and sex during signup).
*   **Row Level Security (RLS):** Policies ensuring users can only insert/read their own data, while researchers can read all anonymized data.

## 7. Version Plan

### Version 1 (MVP)
*   User account creation and login (signup collects name, DOB, sex)
*   Home dashboard that lists available recruiting studies
*   Users can view study description + inclusion/exclusion criteria
*   Users can enroll in a study via eConsent
*   Study No. 1 built and available for loudness matching
*   For study No. 1:
    *   Consent + permissions
    *   Prompt Apple hearing test (if needed) and import audiogram via HealthKit
    *   Headphone gating for Apple Airpods Pro 2
    *   Quiet-room gating
    *   Single-frequency (1kHz) LM
    *   4 tasks per day for 7 days
    *   Daily local push notifications

### V2 (Future Work)
*   Home screen lists all available studies
*   Users can enroll in multiple studies
*   Study No. 2 built and available for LM and multi-frequency PM (Pitch Match) testing. Have the user both frequency match and loudness match their tinnitus.
*   Add compatibility for AirPods Pro 3
*   Login with biometric auth (faceid or fingerprint)
*   EMA Questionnaires.
*   Researcher dashboard to access participant data.
*   In-app hearing test (bypassing Apple native test).

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
