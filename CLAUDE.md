# ClassNest - Agent Context

Flutter app (Material 3) for students of Divine Word College of Legazpi (Group LAB'D, CC105). Students keep their class schedule, see which room each class is in, track which rooms are in use, and get notified in-app when a room changes. All data is local to the phone: no backend, no Firebase.

Naming: the app is called ClassNest. The Dart package, folder and database file are still named `classnav` (imports use `package:classnav/...`), so do not rename them.

## Commands
- `flutter pub get` - install packages
- `flutter run` - run the app
- `flutter analyze` - must report no issues (flutter_lints is on)
- `flutter test` - runs `test/time_utils_test.dart` and `test/widget_test.dart`

## Architecture
Layers under `lib/`. Each layer only depends on the ones listed after it.

| Layer | Folder | Job |
|---|---|---|
| UI | `ui/pages`, `ui/templates`, `ui/organisms`, `ui/molecules`, `ui/atoms` | Screens and widgets (Atomic Design) |
| State | `providers/` | `ChangeNotifier`s the UI reads with `provider` |
| Data access | `services/` | Local database, saved settings, account checks |
| Models | `models/` | Plain data classes |
| Core | `core/` | Routes, theme, subject colors, `TimeUtils`, `Validators` |
| Routing | `routing/` | `AppRouter.onGenerateRoute` |

Dependency direction: pages -> providers -> services -> models. Pages never call a service or the database directly.

### Atomic Design rules (`ui/`)
- **atoms**: smallest widgets with no app logic (`AppButton`, `AppTextField`, `ColorDot`).
- **molecules**: small combinations (`DaySelector`, `RoomBadge`, `EmptyState`, `RoleSelector`, pickers, `TimeField`, `confirmDelete`).
- **organisms**: larger sections tied to the app's data (`ClassCard`, `SubjectTile`, `RoomCard`, `SubjectForm`, `SessionForm`, `SignInForm`). Forms receive data and an `onSubmit` callback; they do not save anything themselves.
- **templates**: `PageTemplate` is the only page layout (app bar, safe area, 640 px max width, optional FAB and bottom bar). Every page uses it.
- **pages**: wire providers to organisms. They own screen-level state (selected day, saving flag).

### Startup and navigation flow
`main.dart` -> `MultiProvider` (ThemeProvider, AuthProvider, ScheduleProvider) -> `ClassNestApp` -> route `/` -> `AuthGate`:
- loading -> spinner; signed out -> `SignInPage`; signed in -> `HomePage`.
- `HomePage` holds four tabs in an `IndexedStack` with a `NavigationBar`: Schedule, Subjects, Rooms, Settings. FABs show only on Schedule ("Add class") and Subjects ("Add subject").
- Only the two form pages are pushed routes (`AppRoutes.subjectForm`, `AppRoutes.sessionForm`), with the item to edit passed as `arguments`.

## Data
- `Subject`: id, code (unique, case-insensitive), name, instructor?, colorValue.
- `ClassSession`: id, subjectId, dayOfWeek, startMinutes, endMinutes, room, previousRoom?, roomChangedAtMillis?. `hasRoomChange` is true when both room-change fields are set.
- `RoomStatus`: room, current?, next?, changed?. Computed in `ScheduleProvider.roomStatuses(now)`; never stored.
- `AppUser`: email, role (`UserRole.student` or `UserRole.admin`).
- SQLite (`classnav.db`, version 2): `subjects`, `class_sessions` (FK to subjects, ON DELETE CASCADE), `users`. Any schema change needs a version bump and an `onUpgrade` step.

## Key behavior (keep it working)
- **Room change detection** happens in `DatabaseService.updateSession`: if the trimmed room differs from the stored one, it saves `previousRoom` = old room and `roomChangedAtMillis` = now. Forms must carry the existing `previousRoom` and `roomChangedAtMillis` through when editing. "Got it" calls `dismissRoomChange`, which clears both.
- **Overlap check**: `saveSession` rejects a class that overlaps any other class on the same day (`hasConflict`, ignoring the session being edited).
- **Room Tracker**: `roomStatuses` groups sessions by trimmed, lower-cased room, finds the class running now (today, start <= now < end), the next class later today, and the latest changed class; sorted A to Z. `RoomsPage` refreshes with a one-minute `Timer` and cancels it in `dispose`.
- **Auth**: `AuthService` lower-cases and trims emails and stores `sha256(salt + password)` with a random salt. `AuthProvider` saves the signed-in email in `PreferencesService` and restores it in `load()`. The role is only shown in Settings; it does not restrict anything yet.

## Conventions
- **Values**: days are 1 (Monday) to 7 (Sunday). Times are minutes since midnight (0-1440). Format them only through `TimeUtils`.
- **Routes**: use `AppRoutes` constants; never hard-code route strings.
- **Validation**: text-input rules live in `Validators` and return an error string or null.
- **Provider methods that save or delete** return `Future<String?>`: an error message, or null on success. Pages show the message in a `SnackBar`. Providers catch exceptions and return friendly text; they do not throw to the UI.
- **After any `await` in a widget**, check `mounted` before using `context` or `setState`. Read providers (`context.read`) and the messenger before the `await` when the widget may be disposed.
- Use `context.watch` in `build`, `context.read` in callbacks.
- **Preferences and database calls** are wrapped in `try/catch`; a failed save must not break the current session (add a short comment in empty `catch` blocks).
- Imports are relative (`../../...`), files are `snake_case.dart`, one main class per file, constructors use `super.key` and `const` where possible.
- Add a short `///` comment on classes and non-obvious methods; keep comments plain.
- Every list or page that can be empty uses `EmptyState` with a clear title and message.
- Theme colors come from `Theme.of(context).colorScheme`; subject colors come from `subjectColorValues`. Do not hard-code other colors in widgets.

## Scope
Keep changes small and inside this structure. Do not add packages, screens or features that were not asked for. If a new field is added to a model, update `toMap`, `fromMap`, `copyWith`, the database schema (with migration) and the form that edits it.
