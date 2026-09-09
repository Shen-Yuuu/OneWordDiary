# Backup Document URI Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the native subagent workflow requested by the user. Each worker uses gpt-5.6-terra / medium. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make backup export and import reliably read and write `DocumentViewPicker` URIs on HarmonyOS 6.0.1 / API 21 without changing the backup format or merge behavior.

**Architecture:** A `BackupFileGateway` owns all URI-to-file-descriptor operations and delegates low-level calls through an injectable port so partial I/O and failures are unit-testable. `BackupService` consumes this gateway while retaining encoding, validation, planning, and transactional import responsibilities.

**Tech Stack:** HarmonyOS 6.0.1 / API 21, ArkTS, ArkUI, CoreFileKit `picker` and `fileIo`, ArkTS `buffer`, Hvigor, Hypium.

**Spec:** `docs/plans/2026-09-09-backup-document-uri-repair-design.md`

## Global Constraints

- Treat picker results as document URIs and pass them unchanged to `fileIo.openSync`.
- Never call `readTextSync(uri)` or path-based `statSync(uri)` for a picker URI.
- Open imports with `READ_ONLY` and exports with `WRITE_ONLY | TRUNC`.
- Read and write in loops and reject a zero-progress write before reporting success.
- Close every opened descriptor on success and failure.
- Preserve `BackupErrorCode.FILE_TOO_LARGE` instead of remapping it to a generic I/O error.
- Do not add storage permissions or persist picker URIs.
- Do not change backup format version 1, the 5 MiB / 10000-record limits, database schema, conflict rules, reminder behavior, privacy text, dependencies, signing, or application version.

---

### Task 1: Testable document-URI file gateway

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/service/BackupFileGateway.ets`
- Create: `OneWord_dev/entry/src/test/BackupFileGateway.test.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `BackupFileGateway.readUtf8(uri: string, maxBytes: number): string`
- Produces: `BackupFileGateway.writeUtf8(uri: string, text: string, maxBytes: number): void`
- Produces: `BackupFilePort` with `open`, `statSize`, `read`, `write`, and `close` descriptor operations.
- Produces: `DocumentUriBackupFileGateway` and the default CoreFileKit-backed port.

- [ ] **Step 1: Add failing gateway tests**

Create a fake `BackupFilePort` that can cap bytes returned or accepted per call and record open modes and close calls. Register the suite in `List.test.ets`. Assert:

```typescript
expect(gateway.readUtf8('file://docs/import.oneword', 64)).assertEqual('静雨');
expect(port.readCallCount > 1).assertTrue();
expect(port.closed).assertTrue();

gateway.writeUtf8('file://docs/export.oneword', '静雨', 64);
expect(port.writeCallCount > 1).assertTrue();
expect(port.writtenText()).assertEqual('静雨');
expect(port.closed).assertTrue();
```

Also assert that a reported size or streamed content over the limit throws `FILE_TOO_LARGE`, open/read failures throw `READ_FAILED`, open/write/zero-progress failures throw `WRITE_FAILED`, and descriptors close after mid-stream failures.

- [ ] **Step 2: Run the gateway suite and confirm it fails because the gateway is absent**

Run:

```powershell
$env:DEVECO_SDK_HOME = 'D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

- [ ] **Step 3: Implement the gateway**

Use this public shape:

```typescript
export interface BackupFileGateway {
  readUtf8(uri: string, maxBytes: number): string;
  writeUtf8(uri: string, text: string, maxBytes: number): void;
}

export interface BackupFilePort {
  open(uri: string, mode: number): number;
  statSize(fd: number): number;
  read(fd: number, target: ArrayBuffer): number;
  write(fd: number, source: ArrayBuffer): number;
  close(fd: number): void;
}
```

The production port wraps `fileIo.openSync`, `fileIo.statSync(fd)`, `fileIo.readSync`, `fileIo.writeSync`, and `fileIo.closeSync(fd)`. The gateway must:

- precheck `statSize(fd)` before large allocation;
- read bounded chunks until EOF and reject total bytes above `maxBytes`;
- assemble only the bytes actually read and decode them with `buffer` as UTF-8;
- encode export text with `buffer.from(text, 'utf8')` and reject it above `maxBytes`;
- pass only the remaining bytes on each write iteration;
- retain a typed `FILE_TOO_LARGE` error while mapping other failures to `READ_FAILED` or `WRITE_FAILED`;
- attempt exactly one close for every successful open.

- [ ] **Step 4: Run the gateway suite and `git diff --check`**

Expected: all gateway tests pass and the new production code compiles for API 21.

---

### Task 2: Integrate the gateway with backup service

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/service/BackupService.ets`
- Modify: `OneWord_dev/entry/src/main/ets/service/AppServiceContainer.ets`
- Modify: `OneWord_dev/entry/src/test/Backup.test.ets`

**Interfaces:**
- Consumes: `BackupFileGateway` and `DocumentUriBackupFileGateway` from Task 1.
- Produces: `BackupService` constructor with a required final `fileGateway: BackupFileGateway` argument.

- [ ] **Step 1: Add failing service tests with an in-memory gateway**

Extend the fixture with a gateway that stores text by URI. Verify:

```typescript
const exported = await service.exportToUri('file://docs/export.oneword');
const plan = await service.prepareImportFromUri('file://docs/export.oneword');
expect(exported).assertEqual(1);
expect(plan.importedCount).assertEqual(1);
```

Use separate repositories for export and import so the imported record is missing locally. Also assert that gateway `READ_FAILED`, `WRITE_FAILED`, and `FILE_TOO_LARGE` codes reach the view-model boundary unchanged and that no database write occurs during `prepareImportFromUri`.

- [ ] **Step 2: Replace direct `fileIo` use in `BackupService`**

Remove `fileIo` and `buffer` imports from `BackupService`. Store the injected gateway and implement:

```typescript
this.fileGateway.writeUtf8(uri, text, BackupCodec.MAX_FILE_BYTES);
const text = this.fileGateway.readUtf8(uri, BackupCodec.MAX_FILE_BYTES);
```

Keep record loading, codec calls, import planning, conflict handling, style restoration, and transaction behavior unchanged. Preserve existing typed `BackupError` values; map unexpected gateway exceptions to the existing read/write codes.

- [ ] **Step 3: Assemble the production dependency**

Pass `new DocumentUriBackupFileGateway()` as the final argument when `AppServiceContainer` creates `BackupService`. Update every test construction site to supply an explicit fake/in-memory gateway.

- [ ] **Step 4: Run all Hypium tests and `git diff --check`**

Expected: the existing backup codec and transaction tests still pass together with the new URI round-trip and error tests.

---

### Task 3: Picker boundary and user-facing states

**Files:**
- Modify only if required by verified findings: `OneWord_dev/entry/src/main/ets/pages/BackupPage.ets`
- Modify: `OneWord_dev/entry/src/test/Backup.test.ets` or a focused view-model test file

**Interfaces:**
- Consumes: unchanged `BackupViewModel.exportToUri` and `prepareImport` methods.

- [ ] **Step 1: Verify picker construction and options against API 21**

Confirm the page uses the current `UIAbilityContext`, passes the URI unchanged, selects at most one item, and retains the valid suffix forms:

```typescript
options.fileSuffixFilters = ['一字日记备份|.oneword'];
options.fileSuffixChoices = ['一字日记备份|.oneword'];
```

Do not add `FILE_ACCESS_PERSIST`; the operation completes while the picker grant is active.

- [ ] **Step 2: Add or retain state tests**

Verify picker cancellation remains a normal return, read and write failures produce the existing distinct Chinese messages, and a successful export/import clears stale error text. Keep URI values out of visible messages and logs.

- [ ] **Step 3: Run focused tests and build**

Expected: no UI regression and no new permission or profile change. If the existing page already satisfies the verified API contract, leave it unchanged and record that result during acceptance.

---

### Task 4: Integration review and acceptance

**Files:**
- Create: `docs/testing/2026-09-09-backup-document-uri-repair-acceptance.md`
- Modify: this plan's checkboxes.

- [ ] **Step 1: Run the complete test suite and inspect the result summary**

Record total, pass, fail, error, and ignored counts from `test_result.txt`, not only the Hvigor exit code.

- [ ] **Step 2: Build the signed Debug HAP**

Run `assembleHap` with module `entry@default`, product `default`, and build mode `debug`. Record artifact path, size, timestamp, and SHA-256.

- [ ] **Step 3: Audit the final diff**

Confirm there is no `readTextSync(uri)`, no `statSync(uri)`, no URI persistence, no new permission, no format/database/version/dependency/signing change, no U+FFFD character, and `git diff --check` passes.

- [ ] **Step 4: Record device status and manual acceptance checklist**

If no device is connected, state that fact. The checklist must cover first export, overwrite export, non-empty UTF-8 file, import of the exported file, cancellation, corrupt input, size limit, conflict preservation, and no local mutation before final confirmation.
