# Wander in Teachably

Wander is a native SwiftUI tab, adapted from the existing project at `/Users/mier/Documents/Projects/wander`. The source project was read without modification. The port follows its exploration and saving mechanisms using Teachably's local storage, typography, colours, and native navigation. It supports Apple's on-device Foundation Models framework as well as the original curated activity library.

## The experience

Start with a map of your selected interests. The content-source menu offers **Apple AI** when the system model is ready and **Activity library** on every supported device. On-device AI is the default for a new install when available. Each layer identifies its actual source; switching modes returns to the starting map.

In Apple AI mode, tapping a topic generates narrower directions. Questions such as `Why do rainbows form?`, **Explain**, and **Show an example** generate a direct explanation, a practical family example, stage-specific invitations, and a personal prompt. Tap **Save to Library** on a pinned idea to create a four-step activity with a materials list and a sibling role. The result appears in **Discover → Saved from Wander** and joins the daily deck. Review generated activities before sharing them.

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

Each request uses a fresh `LanguageModelSession` and guided `@Generable` Swift output. Exploration uses the concept, question, current stages and known ages, up to four trail titles, sibling topic labels, and up to two relevant library references. Promotion uses the pinned idea and its note. The model receives the children's stages and optional ages. Birth months, years, and nicknames stay in the profile. The app validates the result before saving it and discards cancelled results.

Generated layers store provider identity (including OS version and prompt language), prompt version, and the bounded request context. Cached Apple responses are scoped to the current stages, ages, provider, and prompt version. Pins and JSON exports preserve the provenance, and Markdown identifies generated content. The system manages model downloads and availability.

Semantic embeddings, the professional sample knowledge graph, Sites authentication, Cloudflare D1, and the original server's durable generation leases are outside this native implementation. Recall is local keyword search.

Official references: [model availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel), [generating content](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models), and [guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation).

## Verification

Core tests cover exact reuse, provider separation, replay conflicts, ancestry, early teaching requests, generated-output validation, stale responses, failed-input preservation, invalid parent/bubble references, recall of unselected topics, search scopes, snapshot immutability across generated revisions, note limits, undo, old-storage decoding, state restoration, safe Markdown export, and changing interests without losing old trails. Simulator tests cover the family flow and curated Wander flow. A third flow attempts live Apple generation, checking restored content on success or preserved state and a usable library on service failure.

Live explanation generation and restoration passed on an iOS 27.2 simulator with Apple Intelligence ready. Model-service and asset errors can still occur on simulator runtimes. Wander displays the error and keeps the current map available. Review the facts and instructions in generated content before sharing it with children.
