# ClassNest - Agent Context

Flutter application built with Material 3 for students of Divine Word College of Legazpi (Group DPinili, CC105A).

ClassNest allows students to manage their class schedules and subjects, view classroom assignments, track room usage, and receive in-app room-change updates. Administrators can manage registered students' profiles, subjects, and schedules.

The app uses **Firebase Authentication and Cloud Firestore as its primary authentication and cloud data backend**. SQLite is retained as a local backup; do not treat it as the primary source of student schedules or subjects.

Naming: the app is called `ClassNest`. The Dart package, folder, and database file are still named `classnav`. Imports use `package:classnav/...`. Do not rename them.

---

## Commands

- `flutter pub get` - install packages.
- `flutter run` - run the app.
- `flutter analyze` - must report no issues.
- `flutter test` - run the project tests.

Run `flutter analyze` after code changes and fix all reported issues.

---

## Architecture

The project is organized under `lib/`.

| Layer | Folder | Responsibility |
|---|---|---|
| UI | `ui/pages`, `ui/templates`, `ui/organisms`, `ui/molecules`, `ui/atoms` | Screens and reusable widgets using Atomic Design |
| State | `providers/` | `ChangeNotifier` classes used by the UI |
| Data access | `services/` | Firebase Authentication, Firestore access, local database, and saved settings |
| Models | `models/` | Plain Dart data classes |
| Core | `core/` | Routes, theme, subject colors, `TimeUtils`, and `Validators` |
| Routing | `routing/` | `AppRouter.onGenerateRoute` and route configuration |

Dependency direction:

- Student pages generally use providers for application state.
- Providers use services for data access.
- Services communicate with Firebase, SQLite, or preferences as appropriate.
- Models contain data and mapping logic.
- Admin management pages may access the shared `FirestoreService` through Provider when their functionality requires direct Firestore operations.

Do not introduce unnecessary dependencies between layers.

---

## Firebase and authentication

Firebase is initialized in `main.dart`.

The app uses:

- Firebase Authentication for account registration, login, and sign-out.
- Cloud Firestore for student profiles, subjects, and schedules.
- `AuthService` to authenticate users and determine their roles.
- `AuthProvider` to expose the current authenticated user and loading state.
- `AuthGate` to direct authenticated users to the correct part of the app.

### User roles

The application supports two roles:

```dart
enum UserRole {
  student,
  admin,
}
```

### AppUser model

`AppUser` currently contains:

- `uid`
- `email`
- `role`
- `name` (nullable)
- `year` (nullable)
- `course` (nullable)

It also provides the `roleLabel` getter:

- `Student` for `UserRole.student`
- `Admin` for `UserRole.admin`

The student profile fields are nullable because admin accounts do not require student information and older student accounts may not have these fields.

Use `UserRole.student` and `UserRole.admin` rather than comparing role labels throughout the application.

### Role resolution

`AuthService` checks the authenticated user's admin document first:

1. Check `admin/{uid}`.
2. If a valid admin record exists with `role == "admin"` and a valid email, return an admin user.
3. Otherwise, check `users/{uid}`.
4. A valid student record with `role == "student"` and a valid email is returned as a student.
5. For student users, load `name`, `year`, and `course` from Firestore when available.
6. Invalid or missing role records must not be treated as authorized users.

Admin accounts do not need `name`, `year`, or `course`.

### Registration

Registration creates student accounts only.

The registration form collects:

- Full name
- Year level
- Course
- Email
- Password

The year-level options are:

- `1st Year`
- `2nd Year`
- `3rd Year`
- `4th Year`

The course is entered by the student.

`AuthService.register()` validates the profile fields, creates the Firebase Authentication account, and saves the student profile in Firestore.

The student document includes:

```text
users/{studentUID}
  uid
  email
  role: "student"
  name
  year
  course
  createdAt
```

Do not allow ordinary student registration to assign the admin role.

After successful registration, the returned `AppUser` should also contain the newly registered student's name, year, and course.

### Role-based navigation

`AuthGate` handles authentication and navigation:

- Loading authentication state -> loading indicator.
- Signed out -> `SignInPage`.
- Signed in as student -> existing `HomePage`.
- Signed in as admin -> `AdminDashboardPage`.

Keep student and admin navigation separate. Do not accidentally send admins to the student home page.

---

## Firestore data structure

The primary cloud data structure is:

```text
users/{studentUID}
  uid
  email
  role: "student"
  name
  year
  course
  createdAt

admin/{adminUID}
  email
  role: "admin"

subjects/{subjectDocID}
  studentId
  code
  name
  instructor
  colorValue

schedules/{scheduleDocID}
  studentId
  subjectId
  dayOfWeek
  startMinutes
  endMinutes
  room
  previousRoom
  roomChangedAtMillis
```

### Data ownership

- Every subject belongs to a student through `studentId`.
- Every schedule belongs to a student through `studentId`.
- Every schedule references a subject through `subjectId`.
- Firestore document IDs are used as record IDs.
- Student data must remain isolated by authenticated UID.
- Students must only read and modify their own subjects and schedules.
- Admins can read and manage all student subjects and schedules.

Firestore security rules are essential. Never rely only on UI filtering to protect student data.

Admin account documents must not be writable by ordinary student clients. Keep admin authorization controlled by trusted setup and Firestore security rules.

### Shared Firestore service

`FirestoreService` is provided through Provider and handles Firestore operations.

Important methods include:

- `getStudents()`
- `getSubjects({required String studentId})`
- `saveSubject({String? id, required Map<String, dynamic> data})`
- `deleteSubject(String id)`
- `getSchedules({required String studentId})`
- `getAllSchedules()`
- `saveSchedule({String? id, required Map<String, dynamic> data})`
- `deleteSchedule(String id)`
- `hasScheduleConflict(...)`

Firestore document results are mapped to Dart maps containing an `id` field.

Reuse these service methods instead of duplicating Firestore queries in widgets.

---

## Main application structure

`main.dart` initializes Firebase and configures the application's providers.

The shared providers include:

- `ThemeProvider`
- `AuthProvider`
- `FirestoreService`
- `ScheduleProvider`

`ScheduleProvider` receives the current student's UID from `AuthProvider`.

When authentication changes, update the provider's student ID so student schedule data is loaded for the correct account.

Do not allow schedules from a previously signed-in student to remain visible after switching accounts.

---

## Student interface

The student interface remains the existing four-tab `HomePage`, using an `IndexedStack` and `NavigationBar`.

Tabs:

1. Schedule
2. Subjects
3. Rooms
4. Settings

### Schedule

- Displays the authenticated student's own schedules.
- Supports adding and editing class sessions.
- Uses `ScheduleProvider` for schedule state.
- Uses the existing schedule form components.
- Keeps schedule conflict validation.

### Subjects

- Displays only the authenticated student's subjects.
- Supports adding and editing subjects.
- Subjects are stored in Firestore and associated with the student's UID.

### Rooms

- Displays room usage based on schedule information.
- Keeps existing room-tracking behavior and room-change notifications.
- Do not create a separate room collection unless explicitly requested.

### Settings

The Settings page displays the authenticated user's account information.

For student accounts, display:

- Student name
- Email
- Year level
- Course
- Account type / role

For admin accounts, display the account email and admin role. Do not require student profile fields for administrators.

If student profile fields are missing, show appropriate fallback text such as:

- `Name not provided`
- `Year not set`
- `Course not set`

The Settings page also keeps:

- Sign-out functionality
- System theme selection
- Light theme selection
- Dark theme selection
- ClassNest About information

Use `AuthProvider` to access the current `AppUser` and `ThemeProvider` for theme settings.

---

## Admin interface

`AdminDashboardPage` is the landing page for authenticated administrators.

It provides access to four management sections:

1. Students
2. Subjects
3. Schedules
4. Room Management

Keep the admin dashboard and its navigation separate from the student tab interface.

### Common admin search and filters

The admin Students, Subjects, Schedules, and Room Management pages include student search/filter functionality.

Where applicable, support:

- Search by student name or email.
- Filter by year level: All Years, 1st Year, 2nd Year, 3rd Year, 4th Year.
- Filter by course using available student course values from Firestore.

Course filter options should be generated dynamically from student records rather than maintained as a hard-coded course list.

The filters affect displayed results only. They must not modify stored student profile data.

Display student profile details where appropriate:

- Name
- Email
- Year level
- Course

Keep existing admin management functionality and navigation intact when adding or changing filters.

### Students management

`StudentsManagementPage` displays registered student accounts.

It supports:

- Search by student name or email.
- Filter by year level.
- Filter by course.
- Display student name, email, year, and course.
- Refresh student data.

Selecting a student opens `StudentDetailsPage`, passing the student's Firestore document ID as `studentId` and email.

Existing accounts without profile fields should display fallback values rather than causing errors.

### Student details

`StudentDetailsPage`:

- Displays the selected student's email.
- Loads that student's subjects.
- Loads that student's schedules.
- Resolves subject names from their subject IDs.
- Provides access to adding a schedule for that student.

### Subject management

`AdminSubjectsManagementPage` displays registered students and lets the administrator select a student.

The student list supports:

- Search by name or email.
- Year-level filter.
- Course filter.
- Display name, email, year, and course.

`AdminStudentSubjectsPage` manages the selected student's subjects.

Administrators can:

- Add subjects.
- Edit subjects.
- Delete subjects when they are not referenced by existing schedules.

When deleting a subject, check whether schedules reference its ID. Prevent deletion if it would leave schedules with invalid subject references.

Use the existing `SubjectForm` rather than creating a separate form implementation.

Keep the selected student's ID when loading, saving, and deleting subjects.

### Schedule management

`AdminSchedulesManagementPage` displays schedules across students.

It supports:

- Viewing all schedules.
- Searching for students by name or email.
- Filtering by year level.
- Filtering by course.
- Selecting an individual student or All Students.
- Adding schedules for a selected student.
- Editing existing schedules.
- Deleting schedules.
- Viewing the subject, student information, day, time, and room.
- Sorting schedules by day and start time.

When adding a schedule with All Students selected, allow the administrator to choose the student for whom the schedule is being created.

Use `AdminScheduleData` to load and organize student, subject, and schedule information.

Use `AdminSessionFormPage` for adding and editing schedules.

When editing, pass the existing `ClassSession` as `initial` so the form retains its current values.

Student email search should filter the student selection or displayed schedules, not modify stored student email data.

### Room management

`AdminRoomManagementPage` displays room assignments grouped by room.

Room assignments are stored in the `room` field of schedule documents. Do not create a separate room collection for ordinary room management.

The room management page supports:

- Search by student name or email.
- Filter by year level.
- Filter by course.
- Display student name, email, year, and course for each matching schedule.
- Show the number of room groups and scheduled classes matching the filters.
- Group matching schedules by room.
- Sort rooms alphabetically.
- Sort schedules within each room by day and start time.
- Expand and collapse room groups.
- Edit existing room assignments.

Editing a room assignment should update the associated schedule through the existing admin schedule form.

Use `AdminSessionFormPage` and pass the existing `ClassSession` as `initial`.

Keep the existing room grouping and editing behavior when updating this page.

### Admin schedule data

`AdminScheduleData` is responsible for loading:

- Registered students.
- All schedules.
- Each student's subjects.

It provides helpers for resolving:

- Student email from student ID.
- Subject details from a schedule's subject ID.
- Subject name.
- Subject code.

Reuse `AdminScheduleData` instead of repeating student/subject/schedule loading logic across admin pages.

---

## Models

### Subject

`Subject` contains:

- `id`
- `code`
- `name`
- `instructor`
- `colorValue`

It provides:

- `toMap()`
- `fromMap()`

Subject records are associated with a student in Firestore through `studentId`.

### ClassSession

`ClassSession` contains:

- `id`
- `studentId`
- `subjectId`
- `dayOfWeek`
- `startMinutes`
- `endMinutes`
- `room`
- `previousRoom`
- `roomChangedAtMillis`

It provides:

- `toMap()`
- `fromMap()`
- `copyWith()`

Preserve all existing fields when editing a schedule. In particular, do not accidentally discard room-change information.

### AppUser

`AppUser` currently contains:

```dart
enum UserRole {
  student,
  admin,
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.year,
    this.course,
  });

  final String uid;
  final String email;
  final UserRole role;

  final String? name;
  final String? year;
  final String? course;

  String get roleLabel =>
      role == UserRole.admin ? 'Admin' : 'Student';
}
```

The `name`, `year`, and `course` properties are nullable.

`AuthService` loads these fields from the student's Firestore document when available.

Admin users do not require student profile fields.

When changing `AppUser`, update all relevant constructors and mappings, including:

- `AuthService.register()`
- `AuthService._getAppUser()`
- Any test fakes or mock `AppUser` construction that needs updating.

Do not remove the nullable behavior for older accounts or admin accounts.

### RoomStatus

`RoomStatus` represents computed room information, including current, next, and changed class information.

Room status is derived from schedule data; it is not a separate Firestore entity.

---

## Schedule and room behavior

### Schedule conflict checking

Use `FirestoreService.hasScheduleConflict(...)` when saving a schedule.

The check must:

- Compare schedules belonging to the same student.
- Check the same day.
- Detect overlapping time ranges.
- Exclude the current schedule when editing.

Do not remove existing conflict validation when modifying schedule forms.

### Room tracking

Keep the existing room-tracking functionality.

Room status is derived from schedule information:

- A current class is one running today where `startMinutes <= now < endMinutes`.
- The next class is the next scheduled class later that day.
- Room comparisons should use trimmed, case-insensitive room names.
- Keep the existing sorting and display behavior.

### Room changes

Preserve the existing room-change fields:

- `previousRoom`
- `roomChangedAtMillis`

When a room changes, preserve the previous room and the change timestamp according to the existing room-change logic.

The student-facing room-change notification and its dismissal behavior must continue to work.

Do not remove these fields from `ClassSession`, its mapping methods, or the relevant forms.

---

## Forms and Atomic Design

Keep the existing Atomic Design structure under `ui/`.

- **Atoms:** small reusable widgets such as `AppButton`, `AppTextField`, and `ColorDot`.
- **Molecules:** combinations such as `DaySelector`, `RoomBadge`, `EmptyState`, `RoleSelector`, pickers, `TimeField`, and `confirmDelete`.
- **Organisms:** larger components such as `ClassCard`, `SubjectTile`, `RoomCard`, `SubjectForm`, `SessionForm`, and `SignInForm`.
- **Templates:** reusable page layouts where applicable.
- **Pages:** connect data services/providers to UI components and own screen-level state.

Forms should receive initial data and callbacks. They should not independently create Firestore queries or bypass the page/service save flow.

Use the existing `SubjectForm` and `SessionForm` for both student and admin workflows where appropriate.

`SessionForm` supports an optional `studentId` for administrator workflows. When no student ID is supplied, use the authenticated student's UID.

`AdminSessionFormPage` must support both adding and editing schedules.

---

## SQLite backup

SQLite remains part of the project as a local backup.

The database file remains named `classnav.db`.

Do not assume SQLite is the primary source of truth for current student or admin schedule-management screens. Those workflows use Firestore.

If changing SQLite schema or backup behavior:

- Update the database version.
- Add the appropriate `onUpgrade` migration.
- Keep existing data compatibility in mind.
- Do not remove SQLite functionality without an explicit request.

---

## Conventions

### Values

- Days use integers from 1 (Monday) to 7 (Sunday).
- Times are minutes since midnight.
- Valid time values are from 0 to 1440.
- Use `TimeUtils` for time formatting where applicable.

### Routes

Use `AppRoutes` constants and `AppRouter.onGenerateRoute` for named routes. Do not hard-code route strings when a route constant exists.

Use `MaterialPageRoute` for existing admin navigation patterns unless the routing structure is intentionally being changed.

### Validation

Text-input validation belongs in `Validators`.

Validators return an error message or `null`.

### Provider and state

- Use `context.watch` in `build` when the UI should react to provider changes.
- Use `context.read` in callbacks and one-time service access.
- Keep screen-specific state inside the relevant page.
- Keep shared application state inside providers.
- Do not duplicate authentication or schedule state unnecessarily.

### Async safety

After an `await` in a widget, check `mounted` before calling `setState` or using `context`.

Handle Firebase and database exceptions appropriately. Show understandable feedback through `SnackBar` or the existing error UI.

### Code style

- Imports should follow the existing project conventions.
- Use relative imports where the existing files do.
- File names use `snake_case.dart`.
- Prefer one main class per file.
- Use `const` constructors where possible.
- Use `super.key` in widget constructors.
- Add short `///` documentation comments to classes and non-obvious methods.
- Avoid unnecessary packages and duplicate implementations.

### UI styling

- Use `Theme.of(context).colorScheme` for theme colors.
- Use `subjectColorValues` for subject colors.
- Keep Material 3 styling consistent.
- Do not introduce arbitrary hard-coded colors into widgets.
- Keep existing student UI behavior and appearance unless a change is requested.

---

## Scope and development rules

1. Preserve existing Firebase Authentication and Firestore functionality.
2. Preserve student/admin role separation.
3. Never expose one student's schedules or subjects to another student.
4. Keep admin access protected by Firestore security rules.
5. Keep existing student tabs, theme behavior, room tracking, and room-change notifications.
6. Keep SQLite as a backup; do not replace Firestore with SQLite.
7. Reuse existing models, services, providers, and forms before adding new implementations.
8. Do not rename the `classnav` package or database.
9. Do not add packages, screens, or features that were not requested.
10. When adding model fields, update mapping methods, forms, Firestore data handling, and SQLite migrations if applicable.
11. Run `flutter analyze` after changes and resolve all reported issues.
12. Prefer complete, consistent file updates over isolated snippets when replacing an existing file.
13. When modifying an existing file, request or inspect its current complete contents before replacing it if the current implementation is not available.
14. Preserve existing behavior unless a change is explicitly requested.
15. For code updates, provide complete replacement files when practical, with file paths and clear testing steps.
16. Do not assume older student accounts already have profile fields. Handle missing values safely and do not break authentication for those accounts.
