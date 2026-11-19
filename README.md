# Teachably

A native iPhone app for sharing what you know with your children. Each daily idea gives both children a way to join in and the older sibling a chance to lead.

## Run the app

1. Open `Teachably.xcodeproj` in Xcode 26 or newer.
2. Select the **Teachably** scheme and an iPhone simulator.
3. Press **Run**, review your seven preselected interests, and open your first adventure.

The deployment target is iOS 17. Wander's optional on-device generation requires iOS 26 or later, an Apple Intelligence-capable device, Apple Intelligence enabled, and the model downloaded. The app checks availability at runtime; the activity library remains usable on other devices. See [Apple's SystemLanguageModel documentation](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel). To run on your own iPhone, select your development team under **Signing & Capabilities** and use a unique bundle identifier.

## In this prototype

- **My skills:** maths, reading, basic movement, physics, diary writing, coding, and critical thinking are preselected for new profiles. Five other themes are also available. Existing saved choices are preserved; **Use my seven interests** applies the personal starter selection.
- **Today** keeps a daily suggestion and rotates through your interests. Combine **Zero prep**, **15 min**, **Outdoors**, and **Low energy** to find another idea that fits the moment. The short versions have their own four-step timings.
- **Print for today:** choose the current Today activity, a tracing worksheet, or a short English poem in **More → Print for today**. Each selection prints on its own page through AirPrint.
- **Poems:** browse 200 English poems across Levels 0–5, from a few short lines to longer poems to read together. Search by title or author and use **Read aloud** to listen with the device's English voice.
- **Show and Tell** includes 60 short English stories. Open a six-picture mosaic, tap **Record our story**, then listen back below the pictures. Tap **Read story** to open the written version.
- **Wander** offers on-device Apple AI exploration and an offline activity library. Pin an idea and tap **Save to Library** to turn it into a four-step, 30-minute activity with Apple Intelligence. Find it in **Discover → Saved from Wander**. [Port details](docs/wander-port.md)
- **Activity guide** includes a materials checklist, a parent refresher, an invitation for each child's developmental stage, and a specific teaching or setup role for the older sibling.
- **Your experience:** write a personal teaching note that appears during the session.
- **Together time:** a pausable timer for each step, manual progression, and the option to finish early.
- **Discover:** browse, search, and filter all 67 original activities, including 42 matched to your seven interests. Every category has at least five activities.
- **Memories:** keep a note and mark an experience you would like to repeat.
- **Your family** stores optional nicknames and birth months and years. Prompts follow the children's stages as they grow, from Toddler (1–3) to Early Years (4–6) and Primary (7–9).

Family preferences, daily history, teaching notes, memories, and activities saved from Wander are stored locally in UserDefaults. Wander trails and pins use a separate local key. Show and Tell recordings are stored as audio files in the app's Application Support directory. Teachably has no account or cloud sync.

Today and Discover use the curated activities and the activities you explicitly save from Wander. When that deck is exhausted, earlier activities return. Review generated activities before sharing them with children.

Your personal starter pack has six activities for each of your seven interests. With one suggestion per day, a new profile covers every interest once in each of the first six weeks, without repeating an activity. Asking for another idea also counts the previous suggestion as explored and can change that cadence. The five other categories each have five activities. See [your activity pack](docs/your-activity-pack.md) for the full list.

## Poetry sources

The bundled library uses public-domain English verse with author credits in the reader. Reading levels are based on length, repetition, and vocabulary. The library preserves stanza breaks and uses familiar display titles for some traditional rhymes.

- Traditional nursery rhymes from [The Real Mother Goose](https://www.gutenberg.org/ebooks/10607), illustrated by Blanche Fisher Wright, 1916.
- Christina Rossetti from [Sing-Song](https://www.gutenberg.org/ebooks/76703), 1893 edition.
- Robert Louis Stevenson from [A Child's Garden of Verses](https://www.gutenberg.org/ebooks/25609), first published in 1885.
- Edward Lear from [Nonsense Songs](https://www.gutenberg.org/ebooks/13647), first published in 1871.

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
