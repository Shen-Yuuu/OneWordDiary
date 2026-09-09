# Backup Document URI Repair Acceptance

## Result

Backup import and export now treat `DocumentViewPicker` results as document URIs. The production path opens the URI, performs bounded descriptor-based I/O, and closes the descriptor without parsing or persisting the URI.

## Root Cause and Repair

- The former import path called `statSync(uri)` and `readTextSync(uri)`. On API 21, `readTextSync` accepts an application sandbox path rather than a picker document URI.
- Import now calls `openSync(uri, READ_ONLY)`, checks size through `statSync(fd)`, reads bounded chunks through `readSync(fd, ...)`, and decodes only the bytes actually read as UTF-8.
- Export now calls `openSync(uri, WRITE_ONLY | TRUNC)`, converts the complete document to UTF-8 bytes, and loops until every byte has been written.
- Partial reads and writes, zero-progress writes, streamed growth beyond the limit, close failures, empty files, exact limits, and UTF-8 multibyte text have dedicated tests.
- A primary `FILE_TOO_LARGE`, read, or write error is retained even if descriptor closing also fails. A close-only failure is reported as the corresponding I/O failure.
- `BackupService` receives a `BackupFileGateway`; codec format, validation, import planning, transaction, conflict, and style restoration code remain unchanged.
- `BackupPage` supplies the `UIAbilityContext` required by the API 21 picker constructor and passes returned URIs unchanged.
- No persistent file access or general storage permission was added.

## Automated Verification

- ArkTS unit-test compilation completed successfully with all 58 registered test cases, including 7 file-gateway cases and 3 new service/state cases.
- The local Hypium runner did not execute the compiled tests. RichPreviewer failed while reserving its 1.5 GiB Ark runtime memory pool with Windows error 1455 (`Failed to request a continuous segment ...`). Re-running with both new backup suites temporarily removed produced the same environment failure, so this is not a test-loop failure. The existing `test_result.txt` is stale and was not counted as evidence.
- Signed Debug HAP build completed successfully.
- Artifact: `OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`
- Size: 5,155,833 bytes.
- Built: 2026-09-09 16:29:27 +08:00.
- SHA-256: `0400BBB3509C7F136730B8FEB498C2781395FC1742B44FBB4414F225E805960F`.

## Static Integrity

- `BackupService` contains no direct picker-URI `readTextSync`, `statSync`, or file-I/O implementation.
- The production gateway opens the URI and calls `statSync` with the returned file descriptor.
- Backup format remains version 1 with the existing 5 MiB and 10000-record limits.
- No application/module profile, permission, dependency, signing, database, or application-version file changed.
- `git diff --check` passed and the changed text contains no U+FFFD replacement characters.

## Device Verification

`hdc list targets -v` reported UART entries in `Ready` state but no connected HarmonyOS device. Install and true document-provider validation remain pending.

On a physical API 21 device, verify:

1. First export to a newly chosen location creates a non-empty `.oneword` file.
2. Exporting over an existing selected file replaces its old content completely.
3. Selecting the newly exported file shows a valid import summary.
4. Cancelling either picker leaves the page without an error or data change.
5. A corrupt or empty file reports invalid content and does not change local records.
6. A file over 5 MiB is rejected before JSON parsing or database work.
7. Confirming import adds only missing dates; existing local dates remain unchanged.
8. Cancelling the confirmation leaves the database and current style unchanged.
