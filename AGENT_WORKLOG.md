# HW3 Agent Worklog

If no agent or AI tool was used, say so explicitly. If one was used, record
each material task, inspect the resulting diff, and record one recommendation
you rejected or revised; if none was rejectable, explain why.

| Date | Tool/task | Student review | Evidence |
| --- | --- | --- | --- |
| 2026-11-08 | Claude Opus 5.5 (Claude Code): consulted on the plan — MVC boundary, one injected `StudentStore` with change notifications, ID-based detail screen, accessibility identifiers, test strategy | Plan checked line by line against `TASKS_AND_GRADES.md` (required identifiers, exact case-sensitive filter in store order, bonus validation rules, test restrictions) before any implementation | `PLAN.md`, commit `07e6360` |
| 2026-11-08 | Claude Sonnet 5.5 (Claude Code sub-agent): wrote the UIKit/SnapKit app code and tests from the plan — list, cell, detail, subject filter, add/edit form, swipe delete, 12 store tests, 10 controller tests, 7 UI tests | Full diff inspected file by file: no comments, no force unwraps/casts, SnapKit-only layout, identifiers match the spec, form never mutates the store directly, starter files untouched | `git diff` of the implementation commit; `StudentDirectory/`, `StudentDirectoryTests/`, `StudentDirectoryUITests/` |
| 2026-11-08 | Review of the generated code (Opus 5.5) and revisions applied by Sonnet 5.5 | Three generated choices revised (see Final review) | Implementation commit diff |
| 2026-11-08 | Local environment: Xcode 26.3 had no iOS Simulator runtime; installed iOS 26.3.1 runtime with `xcodebuild -downloadPlatform iOS`; first test run stalled on simulator boot and was re-run after booting the `iPhone 17` simulator manually | Verified the `iPhone 17` destination exists before running the README command | `xcrun simctl list devices available` |
| 2026-11-08 | GitHub Actions run of commit `336e949` (Xcode 16.4 runner): all unit tests and the starter UI tests passed; all 7 new flow UI tests failed. Diagnosis (Opus 5.5): the generated Info.plist has an empty `UISceneConfigurations`, so `SceneDelegate` was never attached and the app launched to an empty window. Fix written by Sonnet 5.5: the app delegate sets `delegateClass = SceneDelegate.self` and owns the single `StudentStore`; UI test waits raised to 15 s for slow CI simulators | Failure traced to the generated scene manifest in the built `Info.plist` rather than to the tests; fix diff reviewed | https://github.com/Kyrylo0206/apd-hw-3/actions/runs/42523762154 |
| 2026-11-08 | Local verification with the exact README command | Build of the app, unit-test and UI-test targets succeeded with no errors; earlier test runs stalled on simulator boot and then the disk filled up, so the simulator was reset and the run restarted; the full test result was not yet available when this was committed | `xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test` |

## Final review

- Agent/tool disclosure: Claude Code was used. Claude Opus 5.5 was consulted
  on the plan and reviewed the generated code; Claude Sonnet 5.5 wrote the
  application code and the new tests from that plan. No other AI tools.
- Accepted and rejected/revised recommendations:
  - Accepted: one `StudentStore` created in `SceneDelegate` and injected
    everywhere; lists compute rows from the store; the detail screen keeps
    only the student ID; the store posts `didChangeNotification` once per
    successful mutation so every visible screen refreshes.
  - Revised: the generated cell coloured the scholarship text `.systemGreen`,
    which fails text contrast on a light background and relies on colour; it
    now uses `.label` / `.secondaryLabel` and the wording carries the meaning.
  - Revised: generated controller tests kept the hosting `UIWindow` alive only
    through `_ = window`, which does not guarantee lifetime; the window is now
    a stored property released in `tearDown`.
  - Revised: generated UI tests matched any static text on screen (the detail
    navigation title contains the same name); assertions now target text
    inside the specific `studentCell.<id>` cell.
  - Design decision kept from the plan: swipe-to-delete is offered only on
    the main list, not on subject lists, so a detail screen lower in the
    navigation stack can never show a deleted student.
  - Revised after CI: the plan kept the store in `SceneDelegate`; it moved to
    the app delegate because the generated manifest allows multiple scenes,
    and one store per scene would duplicate the authoritative data.
- Exact local test command and result:
  `xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test`
  — the build step succeeds; a completed local test run had not been
  recorded when this was committed.
- CI URL/status:
  https://github.com/Kyrylo0206/apd-hw-3/actions/runs/42523762154 — failed
  for commit `336e949` (unit tests passed, 7 flow UI tests failed because the
  scene delegate was not attached). The fix is in the following commit; its
  CI run is listed at https://github.com/Kyrylo0206/apd-hw-3/actions and had
  not finished when this was committed.
- Known limitation or remaining risk: local runs used the iOS 26.3.1
  simulator runtime with the iOS 26.2 SDK; GitHub Actions uses the runner's
  own Xcode and simulator, so CI is the reference result. UI tests depend on
  English system strings (`Delete`, `Clear text`); the tests force the
  English locale through launch arguments.
