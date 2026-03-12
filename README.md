# Fitness Quest — Training Challenge Hub

A gamified workout tracking and training challenge app built with **Flutter** and **Dart**. Transform your fitness routine into an engaging quest-based experience with badges, streaks, and a local AI trainer.

## Team

- **Ismail El Ktiri EL Idrissi** — Solo Developer (Undergraduate)

## Features

- **Workout Quest Builder** — Create custom multi-session workout missions with exercises, sets, reps, and weight targets
- **Smart Exercise Library** — 26 pre-loaded exercises filterable by muscle group, equipment, and difficulty. Add custom exercises
- **Active Workout Logger** — Timed workout sessions with per-set tracking, completion checkboxes, and post-workout rating
- **Streak & Badge System** — 10 achievement badges, daily streak tracking, and a 5-week activity heatmap
- **Progress Dashboard** — Weekly volume line chart and muscle group pie chart powered by fl_chart
- **AI Trainer Suggestions** — Local rule-based engine that analyzes your last 7 days and recommends balanced training
- **Profile & Settings** — Dark mode toggle, weight unit preference (kg/lbs), editable name and fitness goal
- **Data Export** — Export workout history as JSON for backup

## Screenshots

_Add screenshots here after building the app._

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter 3.x | Cross-platform framework |
| Dart | Programming language |
| sqflite | SQLite database |
| shared_preferences | Key-value settings storage |
| provider | State management |
| fl_chart | Charts and data visualization |
| uuid | Unique ID generation |
| intl | Date formatting |

## Installation

1. **Prerequisites**: Install [Flutter](https://flutter.dev/docs/get-started/install) (latest stable)
2. **Clone the repo**:
   ```bash
   git clone https://github.com/[username]/fitness-quest.git
   cd fitness-quest
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the app**:
   ```bash
   flutter run
   ```
5. **Build release APK**:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

## Usage Guide

1. **Home** — View your stats, streak heatmap, and AI trainer suggestion. Tap a quest to start a workout.
2. **Quests** — Create new quests by tapping "+". Add exercises from the library, set target sets/reps/weight, and define session goals. Swipe to delete. Long press to edit.
3. **Library** — Browse, search, and filter exercises. Tap "+" to add a custom exercise. Tap any exercise for details.
4. **Workout** — Tap a quest from Home or Quests to open the logger. Press "Start Workout" to begin the timer. Check off sets as you complete them. Press "Finish" to log and rate.
5. **Profile** — Toggle dark mode, change units, edit your name/goal, view achievements, or export data.

## Database Schema

| Table | Columns |
|---|---|
| exercises | id, name, muscle_group, equipment, difficulty, is_custom, image_path, notes |
| quests | id, title, description, created_at, target_sessions, completed_sessions, is_active |
| quest_exercises | id, quest_id, exercise_id, target_sets, target_reps, target_weight, order_index |
| workout_logs | id, quest_id, date, duration_minutes, notes, rating |
| set_logs | id, workout_log_id, exercise_id, set_number, reps, weight, completed |
| achievements | id, title, description, icon, unlock_criteria, unlocked_at |
| ai_feedback | id, suggestion_text, date, thumbs_up |

## Architecture

- **lib/models/** — Data models with toMap/fromMap serialization
- **lib/services/** — Database helper (SQLite CRUD), preferences service, AI trainer, achievement checker
- **lib/screens/** — All 7 app screens
- **Provider** used for dependency injection (DatabaseHelper, PreferencesService, AITrainerService)

## Known Issues

- Heatmap grid scrolls horizontally; a fixed calendar view would be more intuitive
- Export currently shows JSON in a dialog rather than saving to file system

## Future Enhancements

- Photo progress timeline
- Import data from JSON backup
- Biometric authentication
- Custom workout templates
- Social sharing of achievements

## License

MIT License
