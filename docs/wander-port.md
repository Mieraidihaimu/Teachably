# Wander in Teachably

Wander is a native SwiftUI tab, adapted from the existing project at `/Users/mier/Documents/Projects/wander`. The source project was read without modification. The port follows its exploration and saving mechanisms using Teachably's local storage, typography, colours, and native navigation. It supports Apple's on-device Foundation Models framework as well as the original curated activity library.

## The experience

Start with a map of your selected interests. The content-source menu offers **Apple AI** when the system model is ready and **Activity library** on every supported device. On-device AI is the default for a new install when available. Each layer identifies its actual source; switching modes returns to the starting map.

In Apple AI mode, tapping a topic generates narrower directions. Questions such as `Why do rainbows form?`, **Explain**, and **Show an example** generate a direct explanation, a practical family example, separate invitations for ages 2 and 6, and a personal prompt. Generated lessons have no fabricated link to a curated adventure. They can be pinned and used directly, but are not automatically added to Today or Discover. Generated examples require a parent's review.

In library mode, tap an interest, then an activity idea, then a perspective: **The little discovery**, **An example to try**, or **Questions worth asking**. Library explanations link to their full 30-minute adventure.

The map supports pinch zoom, zoom buttons, fit, and dragging when zoomed in. A Map/List picker is available. Automatic layout chooses a list for long labels or more than seven topics; accessibility text sizes always use the readable list. Returning to a saved layer restores its map position. Breadcrumbs and the back control reopen earlier layers.

The composer accepts new topics in Apple AI mode and recognises known topics in library mode. `Explain shadows` opens an explanation; `coding` opens a map. `find shadows` opens recall in the Library. An unknown library topic, model error, invalid response, or cancellation leaves the current layer intact. Generation shows progress and a Cancel control; navigation is disabled while a response is pending.

## Saving and recall

- **Keep this idea** pins the complete current layer and viewport. The saved content is immutable; a personal note of up to 600 characters is separate metadata.
- **Unpin** archives a pin and offers Undo. Re-pinning the original layer restores its original snapshot and note.
- **Reload this layer** makes a new revision using its source while preserving the earlier layer and its pins. Library revisions can contain the same ideas; Apple AI revisions generate again.
- **Library → Explored** searches labels and summaries from every map or explanation already opened, including bubbles that were visible but never selected. Exact labels rank first. Search can be scoped to all trails, a branch, or an exact layer and a depth range.
- Opening a search hit returns to the saved layer and highlights its bubble. Opening a pin restores the original snapshot and viewport.
- Pins can be shared as readable Markdown files or JSON containing the original snapshot and current note. Sharing uses the native iOS share sheet.

## Implementation

| Source mechanism | Native implementation |
| --- | --- |
| Parent layers, selected bubbles, branch IDs, lineage | `WanderLayer` and `WanderEngine` |
| Exact reuse and request replay | Content/profile/provider/prompt-versioned SHA-256 identities and saved request receipts |
| Explicit explanations and examples | Intent detection plus guided model generation or curated lesson output |
| Deterministic bubble positions, zoom, list fallback | `WanderTopicView` |
| Immutable pins with mutable notes and reversible unpin | `WanderSnapshot`, `WanderPin`, and engine operations |
| Recall over previously displayed bubbles | Local keyword search over stored layer content, with branch/layer/depth filters |
| Session and view persistence | `WanderState`, saved under `teachably.wander.v1` |
| Readable notes and original JSON export | `WanderPin.markdown` and native file sharing |

Wander state is stored separately from `teachably.family.v1`. Existing family data and memories do not need a migration. Existing Wander layers remain available when the selected interests change; new starting maps reflect the new selection. A content fingerprint changes cache identity when the activity library changes. Saved and pinned content remains intact.

## Apple Foundation Models

`FoundationModelWanderProvider` checks `SystemLanguageModel.default.availability`. Generation needs iOS 26+, an eligible Apple Intelligence device, Apple Intelligence enabled, and a ready model. The UI explains an unavailable state and offers the library; it never silently presents library content as AI. Saved generated layers can be read without generating again.

Each request uses a fresh `LanguageModelSession` and guided `@Generable` Swift output. The prompt contains the concept, question, ages, up to four trail titles, sibling labels, and up to two relevant library references. It excludes child names, memories, personal teaching notes, and pin notes. Instructions address the parent, adapt participation to ages 2 and 6, prefer simple supervised play, and retain the system guardrails. A bounded context avoids accumulating a long chat transcript. Output is validated before becoming an immutable layer; late results are rejected after navigation or interest changes. Cancellation also prevents committing a result.

Generated layers store provider identity (including OS version and prompt language), prompt version, and the bounded request context. Cache identity separates Apple generation from the library and changes with provider/prompt versions. It does not claim to identify Apple's exact downloaded model asset. Pins and JSON exports preserve this provenance; Markdown identifies generated content. No API key, authenticated mobile service, or app-owned network request is needed. The system manages model downloads and availability.

Semantic embeddings, the professional sample knowledge graph, Sites authentication, Cloudflare D1, and the original server's durable generation leases are outside this native implementation. Recall is local keyword search.

Official references: [model availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel), [generating content](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models), and [guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation).

## Verification

Core tests cover exact reuse, provider separation, replay conflicts, ancestry, early teaching requests, generated-output validation, stale responses, failed-input preservation, invalid parent/bubble references, recall of unselected topics, search scopes, snapshot immutability across generated revisions, note limits, undo, old-storage decoding, state restoration, safe Markdown export, and changing interests without losing old trails. Simulator tests cover the family flow and curated Wander flow. A third flow attempts live Apple generation, checking restored content on success or preserved state and a usable library on service failure.

Real map and explanation generation beyond the curated library was verified using the app's provider on the host Mac. The installed iOS 27 simulator advertises model availability, but its model service fails with missing model-catalog assets and an unknown guardrail token. On that runtime the app displays a clear error and preserves the map. Successful generation inside the iPhone app still needs verification on a supported physical iPhone or a working simulator runtime. Generated text is not fact-checked by output-shape validation; live checks produced inaccuracies, so the parent-review label is intentional.
