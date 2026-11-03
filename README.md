# Teachably

A native iPhone app for sharing a little of what you know with your sons, aged 2 and 6. One daily idea becomes a flexible, hands-on half hour together, with a different invitation for each child.

## Run the app

1. Open `Teachably.xcodeproj` in Xcode 26 or newer.
2. Select the **Teachably** scheme and an iPhone simulator.
3. Press **Run**, review your seven preselected interests, and open your first adventure.

The deployment target is iOS 17. Wander's optional on-device generation requires iOS 26 or later, an Apple Intelligence-capable device, Apple Intelligence enabled, and the model downloaded. The app checks availability at runtime; the activity library remains usable on other devices. See [Apple's SystemLanguageModel documentation](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel). To run on your own iPhone, select your development team under **Signing & Capabilities** and use a unique bundle identifier.

## In this prototype

- **My skills:** maths, reading, basic movement, physics, diary writing, coding, and critical thinking are preselected for new profiles. Five other themes are also available. Existing saved choices are preserved; **Use my seven interests** applies the personal starter selection.
- **Today:** a persistent daily suggestion, with another-idea control. Picks come from your selected interests; themes take turns and offered activities rotate before repeating.
- **Wander:** explore a bubble map or readable list. Choose **Apple AI** for fresh on-device branches, explanations, and examples with separate invitations for ages 2 and 6, or **Activity library** for the original curated content. Source labels distinguish them. Keep pinned snapshots with personal notes, search earlier ideas, and share Markdown or JSON exports. [Port details](docs/wander-port.md).
- **Activity guide:** materials checklist, a refresher for the parent, separate prompts for ages 2 and 6, and four flexible steps totalling 30 minutes.
- **Your experience:** write a personal teaching note that appears during the session.
- **Together time:** a pausable timer for each step, manual progression, and the option to finish early.
- **Discover:** browse, search, and filter all 67 original activities, including 42 matched to your seven interests. Every category has at least five activities.
- **Memories:** keep a note and mark an experience you would like to repeat.
- **Your family:** optional nicknames for both children.

Family preferences, daily history, teaching notes, and memories are stored locally in UserDefaults. Wander keeps its trails, pinned snapshots, notes, and view preferences under a separate local key. The app makes no network requests. Removing the app removes its local data; Wander pins can be exported, while family-memory export and cloud sync are future work.

Today and Discover use the finite, curated activity library. When that deck is exhausted, earlier activities return. Wander can generate ideas beyond the library using Apple's Foundation Models framework, with no API key or app server. Generated suggestions need a parent's review and are not added automatically to the daily activity deck. There are no scheduled reminders yet.

Your personal starter pack has six activities for each of your seven interests. With one suggestion per day, a new profile covers every interest once in each of the first six weeks, without repeating an activity. Asking for another idea also counts the previous suggestion as explored and can change that cadence. The five other categories each have five activities. See [your activity pack](docs/your-activity-pack.md) for the full list.

## Structure

```text
Teachably/                      SwiftUI iPhone app and local state
Sources/TeachablyCore/           Models and deterministic daily planner
  Wander*.swift                 Exploration, generation validation, recall, pins
  Resources/en.lproj/activities.json     Original editable activity library
Tests/TeachablyCoreTests/        Planner, content, persistence, and date tests
TeachablyUITests/               First adventure and saved-memory smoke test
docs/product.md                 Product direction and next decisions
```

The Xcode app references the local `TeachablyCore` Swift package. The package can be tested independently:

```sh
swift test
```

## Languages

Teachably supports English, Simplified Chinese, Traditional Chinese, Japanese, Spanish, and Indonesian. It follows the device's preferred language, including the per-app language selected in iOS Settings. English is the fallback for unsupported languages or missing interface strings.

The shared `L10n` helper in `Sources/TeachablyCore/Localization.swift` loads interface, accessibility, error, and export copy from `Resources/<language>.lproj/Localizable.strings`. Wrap interface copy in `L10n.string` before passing it to SwiftUI, whose implicit lookup uses the app bundle. Use `L10n.format` with `%@` and `%lld` placeholders for dynamic labels; translations can reorder arguments with positional placeholders. `Resources/en.lproj/activities.json` remains the English activity source. Each translated `activities.json` lives in its language's `.lproj` folder and keeps the original IDs, skill values, symbols, and timings. Add a language to `AppLanguage`, the package resources, and `Teachably/Info.plist` together.

Names, notes, memories, and saved Wander snapshots retain the text originally entered or saved. After changing the app language, Wander opens a fresh starting map while keeping earlier trails and pins. New Apple Intelligence content is requested in the app language, and the app checks the installed model's language support before generation; the translated activity library remains available when generation is unsupported.

Localisation tests check all interface keys and format arguments, all 67 activities in every language, saved-data references, multilingual recall commands, and language-specific Wander caches and generation context.

In Xcode, **Product → Test** runs simulator tests covering first-run interest selection, opening an adventure, pausing its timer, saving a memory, and finding it after relaunch. A second flow explores Wander, pins an explanation, saves a personal note, restores it after relaunch, and recalls an unselected topic from a saved map. An additional flow attempts Apple generation when available, verifies restoration on success, and verifies preserved state and a usable library on a model-service failure. It skips when system availability is false. Tests use their own local storage suites.

An unsigned simulator build can be produced with:

```sh
xcodebuild -project Teachably.xcodeproj -scheme Teachably \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/teachably-build CODE_SIGNING_ALLOWED=NO build
```

The Debug-only `--demo` launch argument bypasses initial interest selection with your seven interests and selects the library for deterministic UI tests. Add `--apple-ai` to exercise live generation. Use these only in a disposable simulator: subsequent actions can save demonstration preferences.

## Design basis

The app is for the parent to consult while playing together. Activities offer choice, exploration, and different ways to participate; the timer is a guide. This direction draws on [NAEYC's principles of development and learning](https://www.naeyc.org/resources/position-statements/dap/principles/), which describe the importance of play and individual context. The activity text is original prototype content and has not been independently reviewed by an early-years educator.

Navigation uses Apple's native [SwiftUI NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack).

The literacy activities also draw on [NAEYC's guidance on everyday reading and writing](https://www.naeyc.org/our-work/families/everyday-steps-reading-and-writing). Coding games use simple unplugged sequences, repeats, and debugging; Boston College's [DevTech overview](https://sites.bc.edu/devtech/assessments/techcheck/) describes these areas of computational thinking for young learners. Invitations to distinguish observations from guesses and explain an idea with clues are informed by [Project Zero's thinking-routine guidance](https://www.pz.harvard.edu/resources/see-think-wonder). These references inform the design; the activities are original and are not reproduced source lessons.
