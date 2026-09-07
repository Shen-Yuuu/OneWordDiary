# Diary Background Image Implementation Plan

> For agentic workers: use the native subagent workflow explicitly requested by the user. Each worker uses gpt-5.6-sol / medium. Lead owns integration and acceptance; file ownership below prevents overlapping edits.

**Goal:** Optional, independently persisted daily background images across home, historical detail and single-day PNG sharing without regressions.
**Architecture:** Immutable sandbox image assets, nullable per-record IDs, transaction-safe RDB migration, reactive draft ownership, reusable background rendering, self-contained backward-compatible backup.
**Tech Stack:** HarmonyOS API 21, ArkTS/ArkUI, CoreFileKit photo picker/fileIo, ImageKit, ArkData RDB, Hypium.
**Spec:** docs/plans/2026-09-06-diary-background-design.md

## Global Constraints
- Offline only. No new network/storage permissions or dependencies.
- Existing editing/revision/time, note/privacy, seven-day sharing and styles remain intact.
- Missing/null backgroundImageId means default paper color.
- No dynamic-image playback or dynamic export this release; communicate rejection clearly.
- No user data clearing or release/version/signature changes during verification.

## Task 1: Image assets and backup (worker media)
Files: create model/BackgroundImage.ets and service/BackgroundImageService.ets; modify service/BackupCodec.ets, BackupService.ets, AppResetService.ets, AppServiceContainer.ets, model/BackupModel.ets, privacy/backup copy where necessary and dedicated image/backup tests.
Interfaces: BackgroundImageStore and getBackgroundImageService exactly as spec. DailyRecord.backgroundImageId optional nullable supplied by Task 2.
- [x] Read relevant source and local API references, define store interface first and notify workers.
- [x] Implement bounded static-image validation/normalization and immutable private storage. resolveUri rejects malformed IDs and returns empty string for missing asset; remove deletes only validated owned files.
- [x] Extend backup with bounded image payloads, schema compatibility and all-or-nothing import. Keep original text validation and conflict behavior.
- [x] Inject into app container and reset pending cleanup; startup orphan cleanup if safe.
- [x] Review native byte/path validation; test old/new backup roundtrip and failed import cleanup; report native-device coverage limitations.

## Task 2: Domain and draft lifecycle (worker domain)
Files: model/DailyRecord.ets, constants/DatabaseConstants.ets, repository/DiaryDatabase.ets, DiaryRepository.ets, RdbDiaryRepository.ets, service/DiaryService.ets, DiaryTextRules.ets, viewmodel/TodayViewModel.ets and dedicated tests.
Interfaces: optional nullable backgroundImageId throughout normalization/cloning/revisions; TodayViewModel optional BackgroundImageStore injection and UI methods in spec.
- [x] Add nullable column migration and propagate ID through all domain copies without changing old text/time rules.
- [x] Maintain draft asset ownership, cancellation cleanup, retry safety and preserved historical files; verify async imports against date/draft generation.
- [x] Preserve original background on revision initialization; explicit remove sets null. Blank entry behavior follows chosen optional-background behavior without altering note semantics.
- [x] Add tests for two-date isolation, cancellation/removal, failure retry, revision constraints and cross-day picker completion.

## Task 3: UI and share propagation (worker presentation)
Files: pages/Index.ets, DetailPage.ets, SharePreviewPage.ets, components/diary/TodayEditor.ets, new components/common/DiaryBackground.ets, components/share/ShareSingleCard.ets, viewmodel/DetailViewModel.ets, ShareViewModel.ets, model/ShareCardData.ets and share models as needed, service/ShareImageService.ets if readiness needed, dedicated presentation tests.
Interfaces: consume TodayViewModel and BackgroundImageService from spec; propagate backgroundImageId from records to detail and single-day share, no image changes for seven-day data.
- [x] Add optional picker entry with preview/change/remove and localized loading/error states, inject media store into TodayViewModel.
- [x] Layer image using cover fit plus readable scrim; ensure existing opaque content containers do not hide it. Preserve no-image branch exactly.
- [x] Add detail and single-card background, ensure export waits for image readiness and state changes do not reuse prior images.
- [x] Test data propagation; review missing-image fallback and report pending device-visible acceptance.

## Task 4: Lead integration and acceptance
- [x] Inspect diffs for requirement coverage, ownership races, file validation, backup transaction safety and style preservation.
- [x] Run configured local unit tests and Debug assembleHap; delegate fixes to owners and rerun affected checks.
- [x] Detect connected test devices read-only, run authorized non-destructive visual/share checks if practical.
- [x] Save evidence and remaining device checks in docs/testing/2026-09-06-diary-background-acceptance.md and provide built HAP path.

## Completion evidence (2026-09-07)
- Automated suite: 65 tests, 65 passed, 0 failures/errors.
- Device discovery completed: no Connected device; visual/gallery/native-image checks remain pending in the acceptance report.
- Native image validation is reviewed and compiled; fake-backed backup tests do not exercise the platform decoder.
