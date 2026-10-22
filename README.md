# Teachably

A native iPhone app for sharing a little of what you know with your sons, aged 2 and 6. One daily idea becomes a flexible, hands-on half hour together, with a different invitation for each child.

## Run the app

1. Open `Teachably.xcodeproj` in Xcode 26 or newer.
2. Select the **Teachably** scheme and an iPhone simulator.
3. Press **Run**, review your seven preselected interests, and open your first adventure.

The deployment target is iOS 17. To run on your own iPhone, select your development team under **Signing & Capabilities** and use a unique bundle identifier.

## In this prototype

- **My skills:** maths, reading, basic movement, physics, diary writing, coding, and critical thinking are preselected for new profiles. Five other themes are also available. Existing saved choices are preserved; **Use my seven interests** applies the personal starter selection.
- **Today:** a persistent daily suggestion, with another-idea control. Picks come from your selected interests; themes take turns and offered activities rotate before repeating.
- **Wander:** explore your interests as a bubble map or readable list, follow a trail into explanations and examples, and open the matching family activity. Keep pinned snapshots with personal notes, search earlier ideas, and share Markdown or JSON exports. [Port details](docs/wander-port.md).
- **Activity guide:** materials checklist, a refresher for the parent, separate prompts for ages 2 and 6, and four flexible steps totalling 30 minutes.
- **Your experience:** write a personal teaching note that appears during the session.
- **Together time:** a pausable timer for each step, manual progression, and the option to finish early.
- **Discover:** browse, search, and filter all 31 original activities, including 21 matched to your seven interests.
- **Memories:** keep a note and mark an experience you would like to repeat.
- **Your family:** optional nicknames for both children.

Family preferences, daily history, teaching notes, and memories are stored locally in UserDefaults. Wander keeps its trails, pinned snapshots, notes, and view preferences under a separate local key. The app makes no network requests. Removing the app removes its local data; Wander pins can be exported, while family-memory export and cloud sync are future work.

This is a working starter with a finite activity library. It matches broad interests rather than interpreting an arbitrary skill or generating new lessons. When the deck for your selected interests is exhausted, earlier activities return. There are no scheduled reminders yet.

Your personal starter pack has three activities for each of your seven interests. With one suggestion per day, a new profile covers every interest once in each of the first three weeks, without repeating an activity. Asking for another idea also counts the previous suggestion as explored and can change that cadence. See [your activity pack](docs/your-activity-pack.md) for examples.

## Structure

```text
Teachably/                      SwiftUI iPhone app and local state
Sources/TeachablyCore/           Models and deterministic daily planner
  Wander*.swift                 Local exploration, recall, and pinned snapshots
  Resources/activities.json     Original editable activity library
Tests/TeachablyCoreTests/        Planner, content, persistence, and date tests
TeachablyUITests/               First adventure and saved-memory smoke test
docs/product.md                 Product direction and next decisions
```

The Xcode app references the local `TeachablyCore` Swift package. The package can be tested independently:

```sh
swift test
```

In Xcode, **Product → Test** runs simulator tests covering first-run interest selection, opening an adventure, pausing its timer, saving a memory, and finding it after relaunch. A second flow explores Wander, pins an explanation, saves a personal note, restores it after relaunch, and recalls an unselected topic from a saved map. Tests use their own local storage suites.

An unsigned simulator build can be produced with:

```sh
xcodebuild -project Teachably.xcodeproj -scheme Teachably \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/teachably-build CODE_SIGNING_ALLOWED=NO build
```

The Debug-only `--demo` launch argument bypasses the initial interest selection with your seven interests selected. Use it only in a disposable simulator: subsequent actions can save those demonstration preferences.

## Design basis

The app is for the parent to consult while playing together. Activities offer choice, exploration, and different ways to participate; the timer is a guide. This direction draws on [NAEYC's principles of development and learning](https://www.naeyc.org/resources/position-statements/dap/principles/), which describe the importance of play and individual context. The activity text is original prototype content and has not been independently reviewed by an early-years educator.

Navigation uses Apple's native [SwiftUI NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack).

The literacy activities also draw on [NAEYC's guidance on everyday reading and writing](https://www.naeyc.org/our-work/families/everyday-steps-reading-and-writing). Coding games use simple unplugged sequences, repeats, and debugging; Boston College's [DevTech overview](https://sites.bc.edu/devtech/assessments/techcheck/) describes these areas of computational thinking for young learners. Invitations to distinguish observations from guesses and explain an idea with clues are informed by [Project Zero's thinking-routine guidance](https://www.pz.harvard.edu/resources/see-think-wonder). These references inform the design; the activities are original and are not reproduced source lessons.
