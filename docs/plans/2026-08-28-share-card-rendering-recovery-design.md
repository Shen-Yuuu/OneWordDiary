# Share Card Rendering Recovery Design

## Context

The share preview currently has three device-visible regressions: the single-day card is covered by a black rectangle, seven-day PNG exports remain transparent, and toggling note visibility updates the switch and status label but does not update the card. The diary and share view models already preserve note text correctly, so the repair is limited to presentation and export rendering.

## Root causes

The black/transparent backgrounds were introduced by relying on `Rect.fill` and container `backgroundColor` as snapshot background layers. The device renders these layers inconsistently between the live preview and `ComponentSnapshot`, so they cannot guarantee opaque PNG pixels.

The note switch itself works: `showNote` and the status label update. The remaining failure is the propagation/reconstruction path through builder branches, `renderRevision`, and nested custom-component props. That mechanism is indirect and has not caused the share card subtree to update reliably on the target device.

## Chosen design

### Opaque card surface

Add two small, fully opaque SVG media resources matching the application's warm and plain paper colors. Render the selected resource as an `Image` at the exact card width and height as the lowest child of both card stacks. Remove the `Rect` backgrounds. Since the surface is image content rather than a shape or modifier-only background, it is part of both the live render tree and the component snapshot.

Keep PNG packing direct. Do not allocate or rewrite a second full-resolution `PixelMap`; that earlier approach increased runtime and compatibility risk and caused sharing to fail on the device.

### Reactive note visibility

Bind `SharePreviewPage.showNote` directly into both share card components through `@Link`. Each card receives raw note data and resolves visible note text internally from the linked value. The seven-day card continues to include the note state in each timeline-node key so changing the link reconstructs nodes whose dimensions and content differ.

Remove the page-level `renderRevision`/single-element `ForEach` remount workaround. Mode switches and loaded data already update through normal state and props; note visibility should have one source of truth.

### Export timing

Keep `waitUntilRenderFinished: true` when taking the component snapshot. Because the switch changes a linked property and reconstructs seven-day nodes before the snapshot call, the exported PNG uses the same note state shown in the preview.

## Verification

- Unit tests cover note text resolution for enabled, disabled, empty-note, blank-day, and missing-day cases.
- A debug HAP build verifies ArkTS and resource compilation.
- Device acceptance checks verify single-day and seven-day previews, both paper styles, note toggle on/off, and opaque PNG output in an external image viewer.

## Non-goals

- No diary schema, repository, or stored record changes.
- No change to share-sheet behavior or PNG dimensions.
- No new bitmap post-processing pipeline.
