# SmritiSetu (স্মৃতি সেতু / स्मृति सेतु)

### AI-Based Cognitive Gaming & Monitoring Companion for Elderly Dementia Patients in North Eastern Region
**SIH Problem Statement:** SIH26003  
**Category:** Healthcare & Assistive Technologies / Cross-Platform Mobile & Cloud  

---

## 🛑 Important Product Positioning & Ethical Notice
**SmritiSetu is strictly an assistive cognitive-support and non-clinical monitoring prototype.**  
- It **does NOT** diagnose dementia or Alzheimer's disease.  
- It **does NOT** medically classify patients, prescribe pharmaceutical treatments, or determine clinical therapy.  
- It **does NOT** replace certified medical doctors, neurologists, or clinical psychometric evaluations.  
- Any computed scores represent internal application/game engagement metrics and behavioral trends, not clinical diagnostic measurements.

---

## 🌟 Key Features

1. **4 Accessible Cognitive Mini-Games:**
   - **Family Face Match:** Visual memory & social connection.
   - **Pattern Completion:** Executive function and cultural motif logic.
   - **Activity Sequence:** Daily living procedural memory (e.g., Making Assam Tea).
   - **Object Sorting:** Working memory and categorization.
2. **Deterministic Adaptive Difficulty Engine:**
   - Evaluates accuracy, response time latency, hesitation pauses, and error count.
   - Multi-session rolling damping prevents volatility from single mistakes.
   - Clamped deterministically between Levels 1 and 5.
3. **Multilingual Regional & International Architecture:**
   - Tier 1 North Eastern Indian languages: Assamese, Manipuri, Bengali, Bodo, Khasi, Mizo, Garo.
   - Tier 2 Pan-Indian languages: Hindi, Odia, Telugu, Tamil, etc.
   - Tier 3 International languages with full Arabic RTL bidirectional support.
   - Zero hard-coded UI strings.
4. **Voice Service Abstraction (Bhashini AI + Offline Fallback):**
   - Integrated with Digital India Bhashini for indigenous regional speech.
   - Graceful offline fallback to native device speech synthesis and pre-rendered audio prompts.
5. **Offline-First Architecture & Sync Queue:**
   - Complete functionality operates offline using local SQLite.
   - Transactional `sync_queue` with exponential backoff and idempotent batch synchronization.
6. **Elderly-First Accessibility (WCAG AAA):**
   - Minimum 20px readable body text, high-contrast visual tokens, minimum 56px touch targets, zero complex swipe gestures.
7. **Caregiver Monitoring & Non-Clinical Analytics:**
   - Medication reminder schedules and adherence tracking.
   - Cognitive activity engagement trends and session frequency reports.

---

## 📁 Repository Structure

```
d:/SIH hackathon/
├── docs/                        # Formal Technical Specifications
│   ├── ARCHITECTURE.md          # Clean Architecture & Data Flow
│   ├── ADAPTIVE_DIFFICULTY.md   # Mathematical Model & Decision Rules
│   ├── OFFLINE_SYNC.md          # Idempotent Sync Queue & Protocol
│   ├── LOCALIZATION.md          # Multilingual Engine & RTL Specs
│   ├── VOICE.md                 # Bhashini & Speech Fallback Cascade
│   ├── SECURITY.md              # Threat Model, RBAC, Data Privacy
│   └── TESTING.md               # QA Matrix & Test Pyramid
├── mobile/                      # Flutter Client Application
│   ├── lib/                     # Clean Architecture Source Code
│   └── test/                    # Unit, Database, & Accessibility Tests
└── backend/                     # NestJS Synchronization Service
    └── src/                     # Modular Controllers, Services, & DTOs
```

---

## 🚀 Getting Started

### Mobile Application
```bash
cd mobile
flutter pub get
flutter test
flutter run
```

### Backend Service
```bash
cd backend
npm install
npm run start:dev
```

---

## Build Android APK using GitHub Actions

Follow these practical steps to build and install the release Android APK directly from the cloud without needing Flutter or Android Studio installed on your laptop:

1. Push the project to the existing GitHub repository.
2. Open GitHub → Actions.
3. Select the Android APK workflow.
4. Click Run workflow.
5. Wait for the build to complete.
6. Open the successful workflow.
7. Download the SmritiSetu-Android-APK artifact.
8. Extract the artifact.
9. Transfer the .apk to an Android phone.
10. Install the APK.

