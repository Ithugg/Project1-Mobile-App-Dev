# Architecture Decisions

## Overview

Fitness Quest follows a simple layered architecture suitable for a solo undergraduate project while maintaining clean separation of concerns.

## Layers

### 1. Presentation Layer (lib/screens/)
All UI screens are StatefulWidgets that directly call service methods. Each screen manages its own loading state and refreshes data after mutations.

**Why**: For a project of this scope, this is simpler and more maintainable than implementing full BLoC or MVVM patterns.

### 2. Service Layer (lib/services/)
- **DatabaseHelper** — Singleton that manages SQLite connections, schema creation, seeding, and all CRUD operations. Uses the sqflite package.
- **PreferencesService** — ChangeNotifier wrapper around SharedPreferences. Notifies the widget tree when settings change (e.g., dark mode toggle).
- **AITrainerService** — Rule-based recommendation engine. Queries DatabaseHelper for recent workout history and generates suggestions. No cloud APIs.
- **AchievementChecker** — Evaluates current progress against badge criteria after each workout log.

### 3. Data Layer (lib/models/)
Plain Dart classes with `toMap()` and `fromMap()` factory constructors for SQLite serialization. No external ORM — keeps the data layer transparent and easy to debug.

## State Management

- **Provider** is used at the app root for dependency injection: DatabaseHelper, PreferencesService, and AITrainerService are provided to all screens.
- **PreferencesService** extends ChangeNotifier for reactive theme/settings updates.
- Individual screens use **setState** for local UI state (loading indicators, form fields, workout progress).

**Why Provider + setState**: Provider handles app-wide concerns (theme, database access) while setState keeps screen-level logic simple. This avoids over-engineering for a 7-screen app.

## Database Design

Seven normalized tables with foreign key relationships. The schema avoids redundancy (DRY) while keeping queries straightforward. Exercises are seeded on first launch so the library is immediately useful.

## AI Trainer Logic

The AI trainer uses simple if/then scoring:
1. Query workout_logs and set_logs from the last 7 days
2. Count sets per muscle group
3. Identify the least-trained group
4. Factor in days since last workout and current streak
5. Generate a suggestion with human-readable reasoning
6. Store user feedback (thumbs up/down) to weight future suggestions

This approach is fully local, explainable, and demo-friendly.
TY