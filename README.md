# Unstuck

> One task at a time, for brains that work differently.

Unstuck is an iOS productivity app built specifically for people with ADHD and executive dysfunction. Most productivity tools assume you can just start. Unstuck is built around the reality that starting is the hardest part.

---

## Features

### Daily Check-in
A 3-tap flow that runs once per day. The user picks their energy level, available time, and mood. The app uses these to personalise the experience and detect struggling days.

### AI Task Breakdown
The user types any task and Gemini 2.0 Flash breaks it into 4 to 6 small, actionable steps with time estimates. The Gemini API key is stored securely in Google Cloud Secret Manager and called via a Firebase Cloud Function — it never lives inside the app binary.

### Active Task View
A live visual timer tracks progress through the steps. Gentle nudges fire at 50%, 100%, and 125% of the estimated time. Completing a task triggers a confetti animation and saves the win to history.

### Reset Activities
On struggling days, a guided reset sheet appears automatically with three options: 2-minute breathing with a live countdown, a quick walk prompt, or one good song. Also accessible mid-task via the "I need a break" button.

### Streak and Wins Tracker
Every completed task is saved with its title, time, step count, and estimated duration. A streak counts consecutive days with at least one completion. The wins history screen shows the last 30 days grouped by day.

### Burnout Detection
If the user checks in as struggling 3 or more times in 7 days, the app surfaces a pattern notice and suggests a gentler day.

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS app | SwiftUI |
| AI model | Gemini 2.0 Flash |
| Backend | Firebase Cloud Functions |
| API key security | Google Cloud Secret Manager |
| Local persistence | UserDefaults |
| Authentication (planned) | Auth0 |
| Database (planned) | Firestore |


---

## Project Structure

```
Unstuck/
├── UnstuckApp.swift          # App entry point, routes to check-in or home
├── AppData.swift             # Shared state, persistence, business logic
├── ContentView.swift         # Home screen and task input
├── CheckInView.swift         # Daily 3-step check-in flow
├── TaskDetailView.swift      # Active task view with timer and nudges
├── WinsView.swift            # 30-day task history and streak
├── ResetActivityView.swift   # Guided reset activities
├── NetworkModels.swift       # BreakdownStep data model
└── functions/
    └── index.js              # Firebase Cloud Function for Gemini breakdown
```

---

## Getting Started

### Prerequisites

- Xcode 15 or later
- iOS 17 or later
- Firebase project with Cloud Functions enabled
- Gemini API key stored in Secret Manager via `firebase functions:secrets:set GEMINI_API_KEY`
- `GoogleService-Info.plist` added to the Xcode project

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/unstuck.git
cd unstuck
```

2. Install Firebase dependencies via Swift Package Manager in Xcode

3. Add your `GoogleService-Info.plist` to the project root

4. Install and deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

5. Build and run in Xcode

---

## Security

The Gemini API key is never stored in the app or the repository. It lives exclusively in Google Cloud Secret Manager and is accessed only by the Cloud Function at runtime. If you fork this project, set your own secret with:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

---

## Roadmap

- Auth0 authentication and login flow
- Firestore sync for cross-device persistence
- Body doubling with live focus rooms
- Smart priority engine that learns from completion history

---

## Built With

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Gemini API](https://ai.google.dev/)
- [Firebase](https://firebase.google.com/)
---

## Authors

Clara Kwon, Sania Jain, Lauren Lee, Prajwalla Sinha
