# Wander in Teachably

Wander is a new native SwiftUI tab, adapted from the existing project at `/Users/mier/Documents/Projects/wander`. The source project was read without modification. The port follows its exploration and saving mechanisms using Teachably's activity library, local storage, typography, colours, and native navigation.

## The experience

Start with a map of your selected interests. Tap an interest, then an activity idea, then a perspective: **The little discovery**, **An example to try**, or **Questions worth asking**. Maps offer **Explain** and **Show an example** immediately. An explanation includes the idea, a practical example, separate invitations for ages 2 and 6, a personal prompt, and a link to the full 30-minute adventure.

The map supports pinch zoom, zoom buttons, fit, and dragging when zoomed in. A Map/List picker is available. Automatic layout chooses a list for long labels or more than seven topics; accessibility text sizes always use the readable list. Returning to a saved layer restores its map position. Breadcrumbs and the back control reopen earlier layers.

The composer recognises known library topics and explicit teaching questions. `Explain shadows` opens an explanation; `coding` opens that area's map. `find shadows` opens recall in the Library. Unknown topics leave the current layer intact and report that the library has no matching idea.

## Saving and recall

- **Keep this idea** pins the complete current layer and viewport. The saved content is immutable; a personal note of up to 600 characters is separate metadata.
- **Unpin** archives a pin and offers Undo. Re-pinning the original layer restores its original snapshot and note.
- **Reload this layer** makes a new revision from the library while preserving the earlier layer and its pins. With unchanged curated content, the revision can contain the same ideas.
- **Library → Explored** searches labels and summaries from every map or explanation already opened, including bubbles that were visible but never selected. Exact labels rank first. Search can be scoped to all trails, a branch, or an exact layer and a depth range.
- Opening a search hit returns to the saved layer and highlights its bubble. Opening a pin restores the original snapshot and viewport.
- Pins can be shared as readable Markdown files or JSON containing the original snapshot and current note. Sharing uses the native iOS share sheet.

## Implementation

| Source mechanism | Native implementation |
| --- | --- |
| Parent layers, selected bubbles, branch IDs, lineage | `WanderLayer` and `WanderEngine` |
| Exact reuse and request replay | Content/profile-versioned SHA-256 cache identities and saved request receipts |
| Explicit explanations and examples | Intent detection plus curated lesson output at any map depth |
| Deterministic bubble positions, zoom, list fallback | `WanderTopicView` |
| Immutable pins with mutable notes and reversible unpin | `WanderSnapshot`, `WanderPin`, and engine operations |
| Recall over previously displayed bubbles | Local keyword search over stored layer content, with branch/layer/depth filters |
| Session and view persistence | `WanderState`, saved under `teachably.wander.v1` |
| Readable notes and original JSON export | `WanderPin.markdown` and native file sharing |

Wander state is stored separately from `teachably.family.v1`. Existing family data and memories do not need a migration. Existing Wander layers remain available when the selected interests change; new starting maps reflect the new selection. A content fingerprint changes cache identity when the activity library changes. Saved and pinned content remains intact.

This is the local library version of Wander. Live model generation, semantic embeddings, the professional sample knowledge graph, Sites authentication, Cloudflare D1, and the original server's durable generation leases are outside this native implementation. Connecting a live provider needs an authenticated mobile service and a family-oriented generation contract; provider secrets should remain on that service. The app currently makes no network requests.

## Verification

Core tests cover exact reuse, replay conflicts, ancestry, early teaching requests, failed-input preservation, invalid parent/bubble references, recall of unselected topics, search scopes, snapshot immutability, note limits, undo, state restoration, safe Markdown export, and changing interests without losing old trails. The iPhone UI test covers drill-down, pinning, a note surviving relaunch, and recall returning to the saved map.
