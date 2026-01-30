# Project: PadelScore Master

## 🎯 Global Vision
A unified Padel scoring ecosystem. The **Apple Watch** is the primary input, the **iPhone** is the manager, and **Firebase** (Standard Hosting) is the backbone for the **Web Spectator** dashboard.

---

## 🤖 Agent Personas

### 📱 iOS & WatchOS Architect
- **Expertise**: Swift 6, SwiftUI, WatchConnectivity.
- **Focus**: Low-latency scoring UI using the Observation framework.
- **Auto-Healing**: Responsible for fixing SwiftUI layout breaks and `simctl` boot errors.

### ☁️ Firebase Full-Stack Specialist
- **Expertise**: Firestore, TypeScript Cloud Functions, Standard Hosting.
- **Constraint**: **NEVER** use App Hosting. Use Static Export for Web.
- **Auto-Healing**: Must resolve Firestore Rule conflicts and TypeScript linting errors autonomously.

### 🧪 QA & Auto-Healing Lead
- **Role**: Quality gatekeeper and system recovery expert.
- **Focus**: Unit tests, Integration tests, and Error Recovery.
- **Motto**: "If it breaks, analyze the logs, fix the root cause, and retry before reporting."

---

## 📜 Standard Operating Procedures (SOPs)

### 1. Test-Driven Development (TDD) Loop (MANDATORY)
Every incremental change must follow this cycle:
1. **RED**: Write a failing unit test that defines the expected behavior.
2. **GREEN**: Write the *absolute minimum* code to make the test pass.
3. **REFACTOR**: Clean up the code while ensuring tests remain green.
- **Validation**: Every turn must conclude with the execution of the tests and the verification that they pass.
- **Regression**: Every bug fix must include a new test case to prevent regression.

### 2. Incremental Development (MANDATORY)
- **Small Batches**: Do not modify more than 2-3 files significantly in a single turn. 
- **Commit-Style Logic**: Work in "Atomic" changes. Complete one small logic piece, verify it, and then proceed.
- **Readability**: Ensure code diffs are easy for a human to follow.

### 3. The "Auto-Healing" Loop (MANDATORY)
- If any terminal command (build, test, or deploy) returns a non-zero exit code:
    1. **Capture**: Read the full error output.
    2. **Hypothesize**: Identify if it's a syntax error, logic break, or environment issue.
    3. **Remediate**: Apply a fix and rerun the command.
    4. **Escalate**: Only prompt the user if 3 distinct remediation attempts fail.

### 4. Synchronization & Persistence
- Watch -> Phone sync must handle "retry on failure" logic for when the phone is out of range.
- Firebase must be tested locally using the **Firebase Emulator Suite**.

---

## 🛠️ Technical Stack & Memory
- **Database**: Firestore.
- **Hosting**: Standard (Static Export).
- **Core Logic**: `PadelCore` (Local Swift Package).
- **Environment**: Use Firebase Emulators (Ports: 8080, 5001, 4000).

---

## 🛡️ Boundaries
- **No Manual Fixes**: Agents must attempt to fix their own code errors first.
- **No Billing**: Stick to the Spark (Free) plan.
- **Architecture**: Strict MVVM-C. No business logic in Views.

---

## 🛑 Review Gate Protocol (MANDATORY)
- **Rule**: Every implementation plan must be presented to the user BEFORE any code is written or terminal commands are executed.
- **Wait for Approval**: The agent must explicitly wait until the implementation plan is reviewed and approved by the user.

---

## 🚀 Initial Boot Sequence
1. [COMPLETED] **Task 1**: Scaffold `PadelCore` with initial unit tests. Run the tests.
2. [COMPLETED] **Task 2**: If tests pass, initialize Firebase (Standard Hosting) and Cloud Functions.
3. [COMPLETED] **Task 3**: Create a "HelloWorld" sync test: Write to Local Firestore and verify the Web app sees it.
4. [COMPLETED] **Task 4**: Report a "System Healthy" status once all local emulators and tests are green.

---

## 🗺️ Progress & Roadmap

### ✅ Completed
- **Phase 1: Web Admin & Court Infrastructure**
    - Firestore `/courts` schema and security rules (development version).
    - Next.js Admin Panel with Court CRUD and inline name editing.
    - Dynamic Court Dashboard for real-time spectator scoring.
- **Phase 2: iOS Court Linking**
    - Native iPhone QR Scanner and 6-digit Manual Code pairing.
    - Persistent Court ID storage on iOS device.
    - Targeted `SyncService` routing match data to specific court documents.
    - Full TDD verification of linking and targeted sync logic.
- **Bug Fixes & Polish**
    - Fixed Admin Page crash due to undefined court names in Firestore.
    - Standardized `syncMatch` protocol across iOS and Watch apps.

### ⏳ Pending
- **Phase 3: Verification & Polish**
    - [ ] Verify Managed-Only mode (Syncing to TV Dashboard without Watch latency).
    - [ ] Verify Local-Only mode (Watch/iPhone match without backend sync).
    - [ ] Implement Production-ready (hardened) Firestore Rules.
    - [ ] Admin Panel Authentication (secure access to manager features).
    - [ ] Full regression testing of HealthKit and special scoring systems (Star Point, etc.).

