# HW3 Student Plan

## Approach

### MVC boundary

- **Model** — `Student`, `StudentSeedData`, `StudentStore`. The store is the
  only authoritative collection. It owns subject filtering
  (`students(matchingSubject:)`), lookup by ID (`student(withID:)`), validation
  and the add/update/delete mutations. After every successful mutation it posts
  `StudentStore.didChangeNotification` exactly once; failed mutations post
  nothing and leave `students` unchanged.
- **View** — `StudentTableViewCell` (reusable cell: avatar, name, age, average
  grade, scholarship status), plus the detail and form layouts built with
  SnapKit. `StudentFormatter` turns model values into display strings and
  `AccessibilityID` centralises every identifier.
- **Controller** — `StudentListViewController` (one class for both the full
  list and a subject-filtered list), `StudentDetailViewController`,
  `StudentFormViewController` (add/edit form). Controllers translate user
  actions into store calls and refresh views when the store notifies them.

### One shared `StudentStore`

The app delegate (`StudentDirectoryApp`) owns exactly one `StudentStore` and
attaches `SceneDelegate` as the scene delegate class; `SceneDelegate` injects
that store through initializers into the root controller, and each controller
passes the same instance on when it pushes or presents the next screen. There is no singleton
and no copied array:

- list rows are computed from the store on every reload
  (`store.students` or `store.students(matchingSubject:)`);
- the detail screen stores only the student's `UUID` and re-reads the student
  from the store whenever it refreshes;
- the form never touches the store directly; it receives a throwing submit
  closure from the presenting controller.

Controllers observe `StudentStore.didChangeNotification` (selector-based, scoped
to the injected store), so every visible screen refreshes after a mutation made
anywhere in the navigation stack.

### Subject filtering and how it is tested

Tapping a subject button on the detail screen pushes
`StudentListViewController(filter: .subject(name))`. Its title is the subject and
its rows come from `store.students(matchingSubject:)`, which uses exact,
case-sensitive `contains` and preserves store order. Tests:

- store unit tests: `Math` returns Ada, Katherine, Donald in store order;
  `math` and unknown subjects return nothing;
- controller unit tests: the filtered list's title and row count, and that
  tapping a subject button pushes the filtered list;
- UI test: tap `subjectButton.Math` and check the `Math` navigation bar and the
  presence/absence of specific `studentCell.<id>` cells.

### UI and accessibility decisions

- Required identifiers: `studentList` (table view of every list),
  `studentCell.<student-id>` (`UUID.uuidString`), `studentDetails` (detail root
  view), `subjectButton.<subject>`, `addStudentButton`, `editStudentButton`.
- Extra identifiers for tests: `studentDetails.<field>` value labels,
  `studentNameField`, `studentAgeField`, `saveStudentButton`,
  `cancelStudentButton`, `studentFormError`.
- Dynamic Type: every label and text field uses `preferredFont(forTextStyle:)`
  with `adjustsFontForContentSizeCategory`, labels wrap (`numberOfLines = 0`),
  rows self-size, the detail screen scrolls, and the cell switches to a
  vertical layout at accessibility text sizes.
- VoiceOver: subject buttons carry hints, the detail avatar has a label, the
  "Subjects" caption is a header, form errors are announced.
- Semantic system colours for light and dark mode.
- No force unwraps or force casts in new code; age input is parsed with
  `Int(_:)` behind a `guard`.

### Bonus (add/edit/delete)

- Add: `addStudentButton` on the main list opens a two-field name/age form;
  the list scrolls to the appended student after a successful save.
- Edit: `editStudentButton` on the detail screen opens the same form prefilled
  with name and age only.
- Delete: trailing swipe action on the main list calls
  `store.deleteStudent(id:)`.
- Invalid input keeps the form open, shows an inline error and does not mutate
  the store.

## Milestones

- [x] Student list and reusable cell
- [x] Detail screen and navigation
- [x] Subject-filtered list
- [x] Unit and UI tests
- [x] Optional add/edit/delete bonus, if attempted
- [ ] Local verification and CI review
- [x] Final diff and evidence review

## Verification plan

Focused checks while implementing:

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'generic/platform=iOS Simulator' build-for-testing
```

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:StudentDirectoryTests
```

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:StudentDirectoryUITests
```

Final command from the README:

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The GitHub Actions run of the same command is reviewed separately; a local
pass is not treated as CI evidence.
