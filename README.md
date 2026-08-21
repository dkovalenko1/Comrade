# Comrade

Comrade is a native iOS productivity companion that brings task planning, Pomodoro-style focus sessions, scheduling, achievements, and a social-credit score into one offline-first app.

Built as an Apple Platform Development final project.

## Features

- **Focus timer** — run configurable work, short-break, and long-break cycles with visual progress and completion notifications.
- **Focus modes** — choose Casual or Hardcore mode; Hardcore sessions affect the social-credit score when they are abandoned after the grace period.
- **Pomodoro templates** — select preset routines or create, edit, and delete custom templates with their own durations and cycle counts.
- **Task management** — create tasks with descriptions, categories, tags, priorities, deadlines, reminders, and task dependencies.
- **Calendar** — browse tasks with deadlines in week or month views, grouped by priority for the selected day.
- **Categories and tags** — manage reusable labels and category colors to organize work.
- **Dependencies** — require prerequisite tasks to be completed before dependent tasks can be finished.
- **Achievements** — unlock progress-based milestones for focus time, streaks, task completion, and template usage.
- **Local notifications** — receive reminders for deadlines and alerts when focus sessions or breaks end.
- **Offline persistence** — Core Data stores tasks, sessions, templates, achievements, categories, tags, reminders, and social-credit history locally on the device.

## Requirements

- macOS with Xcode that supports the project’s **iOS 26.0** deployment target
- An iOS 26.0+ simulator or device
- An Apple developer signing team to run on a physical device

## Getting started

1. Clone the repository.
2. Open [Comrade.xcodeproj](Comrade.xcodeproj) in Xcode.
3. Allow Xcode to resolve Swift Package dependencies.
4. Select the `Comrade` scheme and an iOS 26.0+ destination.
5. Build and run (`⌘R`).
6. Allow notifications when prompted to enable task and timer alerts.

The app has no backend or additional environment configuration.

## Testing

The repository includes unit tests for Core Data, services, view models, timer sessions, templates, achievements, and social credit, plus UI tests for the timer, tasks, calendar, categories, and achievements.

Run the test suite in Xcode with `⌘U`, or from Terminal:

```sh
xcodebuild test \
  -project Comrade.xcodeproj \
  -scheme Comrade \
  -testPlan Comrade \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

If `iPhone 17` is unavailable, replace it with an installed simulator name from `xcrun simctl list devices available`.

## Architecture

Comrade uses UIKit with programmatic views and a lightweight MVVM-style organization:

```text
Comrade/
├── Controllers/          App flow, timer, templates, achievements
├── Modules/
│   ├── Tasks/            Task screens, components, and view models
│   └── Calendar/         Calendar screens, cells, and view model
├── Core/
│   ├── Models/           Domain models
│   ├── Services/         Core Data, tasks, sessions, notifications, and more
│   └── Theme/            Shared colors
├── ViewModels/           Timer and achievement presentation logic
└── Views/                Reusable UI components
```

`CoreDataStack` is the persistence boundary. Feature services encapsulate data access and business rules, while view models expose display-ready state to UIKit view controllers.

## Dependencies

- [SnapKit](https://github.com/SnapKit/SnapKit) 5.7.1 for Auto Layout constraints.

All other functionality uses Apple frameworks, including UIKit, Core Data, and UserNotifications.

## Data and privacy

Comrade stores its data only in the app’s local Core Data store. It does not require an account or a network connection. Notification permission is requested at launch and can be changed later in iOS Settings.
