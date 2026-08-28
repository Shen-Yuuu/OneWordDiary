# Share Note Initialization Safety Design

## Context

Entering the single-day share page now crashes during ShareSingleCard initial rendering. The failing expression is this.visibleNote.length on line 103. The card only reads note visibility, but the previous repair modeled that input as an uninitialized two-way Link.

## Root cause

includeNote is read-only child input and does not require two-way synchronization. During the custom component's first render, the linked value and derived getter can be observed before a stable string result is available. The layout then dereferences length immediately, turning an initialization ordering issue into a fatal exception.

The note resolver also assumes its note argument is always a string. Although the declared application model normalizes database nulls, defensive handling is appropriate at the UI boundary because older or partially initialized runtime values can still be nullish.

## Chosen design

- Replace Link includeNote with Prop includeNote initialized to false in both share cards.
- Pass this.showNote as a concrete parent value. ArkUI's one-way prop synchronization will refresh the cards when the switch changes.
- Add shouldShowNote to ShareSingleCard and use it for layout and conditional rendering. Do not use a derived string's length to decide whether the note area exists.
- Let resolveShareNoteText accept string, null, or undefined and always return a string. Empty and nullish notes use the existing fallback copy when notes are enabled.
- Keep the opaque SVG card surfaces and direct PNG export unchanged.

## Verification

- Unit tests cover enabled notes with normal, empty, null, and undefined values, plus disabled and missing-day behavior.
- Existing share view-model tests verify single and seven-day note mapping.
- A debug HAP build verifies ArkTS decorators, resources, and generated UI code.
- Device acceptance verifies entering single-day share no longer crashes and the note switch still updates both card types.

## Non-goals

- No persistence or schema changes.
- No modification to image snapshot or share-sheet logic.
- No reintroduction of revision-based forced remounting.
