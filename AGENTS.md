# Project: PadelScore Master (Antigravity Edition)

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

### 1. Incremental Development (MANDATORY)
- **Small Batches**: Do not modify more than 2-3 files significantly in a single turn. 
- **Commit-Style Logic**: Work in "Atomic" changes. Complete one small logic piece, verify it, and then proceed.
- **Readability**: Ensure code diffs are easy for a human to follow.

### 2. The "Auto-Healing" Loop (MANDATORY)
- If any terminal command (build, test, or deploy) returns a non-zero exit code:
    1. **Capture**: Read the full error output.
    2. **Hypothesize**: Identify if it's a syntax error, logic break, or environment issue.
    3. **Remediate**: Apply a fix and rerun the command.
    4. **Escalate**: Only prompt the user if 3 distinct remediation attempts fail.

### 3. Test-Driven Development (TDD)
- No scoring logic is "complete" until `swift test` in `PadelCore` passes 100%.
- Every bug fix must include a new test case to prevent regression.

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

## 🚀 Initial Boot Sequence
1. **Task 1**: Scaffold `PadelCore` with initial unit tests. Run the tests.
2. **Task 2**: If tests pass, initialize Firebase (Standard Hosting) and Cloud Functions.
3. **Task 3**: Create a "HelloWorld" sync test: Write to Local Firestore and verify the Web app sees it.
4. **Task 4**: Report a "System Healthy" status once all local emulators and tests are green.