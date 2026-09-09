# Immersive Foreground Top Offset Acceptance

## Result

The window uses full-screen layout again. Background layers continue through the status and navigation bar regions, while only the foreground page content receives a shared 32vp top offset.

## Scope Verification

- `EntryAbility` calls `setWindowLayoutFullScreen(true)` and keeps both system bars transparent.
- `app.float.immersive_top_content_offset` is defined once with a default value of `32vp`.
- The resource is applied to the foreground columns in Index, TodayConfirmation, Detail, Scroll, Settings, Backup, Privacy, and SharePreview.
- Root stacks, `PaperBackdrop`, `DiaryBackground`, loading states, and error states were not padded.
- `PHOTO_IMAGE_OPACITY` remains `0.10` as configured before this change.
- No application profile, module profile, package dependency, signing, database version, diary data, sharing data, or backup data configuration was changed.
- `git diff --check` passed and the edited source contains no U+FFFD replacement characters.

## Automated Verification

- Hypium: 70 tests run, 70 passed, 0 failures, 0 errors, 0 ignored.
- Debug HAP build: successful.
- Artifact: `OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`
- Size: 5,312,696 bytes.
- Built: 2026-09-09 11:38:08 +08:00.
- SHA-256: `C74ADF029D91341FEE08809CC6C634C498411864FEE39791D748685E3B391426`.

## Device Verification

`hdc list targets -v` reported UART entries in `Ready` state but no connected HarmonyOS device, so installation and screenshot verification could not be performed in this workspace session.

On a physical device, verify:

1. The background image or paper color reaches behind both transparent system bars.
2. The home date, weekday, action icon, diary input, and confirmation content no longer overlap the status bar.
3. Detail, scroll, settings, backup, privacy, and share-preview top controls clear the status bar.
4. Bottom content remains usable and the gesture/navigation region stays visually continuous with the background.
5. Loading, error, and first-run privacy consent states remain correctly positioned.

If the device needs a larger or smaller gap, change only `immersive_top_content_offset` in `OneWord_dev/entry/src/main/resources/base/element/float.json`. Suggested follow-up values are `28vp`, `36vp`, or `40vp` after visual inspection.
