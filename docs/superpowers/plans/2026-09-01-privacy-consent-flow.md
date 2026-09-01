# Privacy Consent Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Require consent to the current AGC-hosted privacy policy before the diary is usable and provide an always-available policy entry from Settings.

**Architecture:** Keep the official agreement URL and a local agreement version in a small privacy-policy model. Persist only the accepted version in the existing Preferences-backed SettingsRepository. Index owns a PrivacyConsentViewModel and renders a blocking consent component until that version is accepted; the existing PrivacyPage becomes a short offline summary with a callback that opens the official URL through an implicit system Want.

**Tech Stack:** HarmonyOS API 21, ArkTS, ArkUI Navigation, Ability Kit, ArkData Preferences, Hypium.

**Spec:** `docs/plans/2026-09-01-privacy-consent-design.md`

## Global Constraints

- Official policy URL: `https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=2029714840460753280`.
- Do not add `ohos.permission.INTERNET` or an embedded Web component.
- Save only the accepted policy version; do not save reading telemetry or diary content.
- Preserve the user's existing uncommitted files and unrelated changes.

---

### Task 1: Persist the privacy-policy acceptance version

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/model/PrivacyPolicy.ets`
- Modify: `OneWord_dev/entry/src/main/ets/model/Settings.ets`
- Modify: `OneWord_dev/entry/src/main/ets/repository/SettingsRepository.ets`
- Test: `OneWord_dev/entry/src/test/SettingsRepository.test.ets`

**Interfaces:**
- Produces `PRIVACY_POLICY_VERSION: string`, `PRIVACY_POLICY_URL: string`.
- Extends `AppSettings` with `privacyPolicyAcceptedVersion: string`.
- Extends `SettingsRepository` with `savePrivacyPolicyAcceptedVersion(version: string): Promise<void>`.

- [ ] **Step 1: Write failing repository tests**

Add tests that a newly created repository returns an empty accepted version and that saving `2026-09-01` persists across a reload.

- [ ] **Step 2: Run the focused test**

Run: `hvigorw test --mode module -p module=entry@default -p product=default --no-daemon`

Expected: the new tests fail because the model field and repository method do not exist.

- [ ] **Step 3: Add the constants and repository storage**

Create `PrivacyPolicy.ets` with:

```ts
export const PRIVACY_POLICY_VERSION: string = '2026-09-01';
export const PRIVACY_POLICY_URL: string =
  'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=2029714840460753280';
```

Add `KEY_PRIVACY_POLICY_ACCEPTED_VERSION`, load it with `''` as default, persist it with `put` and `flush`, and include it in `AppSettings`.

- [ ] **Step 4: Run the focused test again**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add OneWord_dev/entry/src/main/ets/model/PrivacyPolicy.ets OneWord_dev/entry/src/main/ets/model/Settings.ets OneWord_dev/entry/src/main/ets/repository/SettingsRepository.ets OneWord_dev/entry/src/test/SettingsRepository.test.ets
git commit -m "feat: persist privacy policy consent"
```

### Task 2: Add a blocking first-use consent component

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/viewmodel/PrivacyConsentViewModel.ets`
- Create: `OneWord_dev/entry/src/main/ets/components/privacy/PrivacyConsentGate.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets`
- Test: `OneWord_dev/entry/src/test/PrivacyConsentViewModel.test.ets`

**Interfaces:**
- `PrivacyConsentViewModel.load(): Promise<void>` compares the stored version to `PRIVACY_POLICY_VERSION`.
- `PrivacyConsentViewModel.accept(): Promise<boolean>` persists the current version.
- `PrivacyConsentGate` receives `isSaving`, `errorMessage`, `onOpenPolicy`, `onAccept`, and `onDecline` callbacks.

- [ ] **Step 1: Write failing ViewModel tests**

Cover three cases: empty stored version requires consent; the current version permits access; a failing `savePrivacyPolicyAcceptedVersion` keeps the gate visible and exposes a retry message.

- [ ] **Step 2: Implement the observed ViewModel**

Use the existing `@Observed` pattern. `load()` sets a loading state, then compares the stored version. `accept()` writes only `PRIVACY_POLICY_VERSION`; it returns false and sets `errorMessage` if persistence fails.

- [ ] **Step 3: Implement the consent gate**

Show the title “在开始前，先确认一件事”, a concise local summary, the button “查看完整隐私政策”, the primary button “同意并继续”, and the secondary button “不同意并退出”. Disable both action buttons while saving.

- [ ] **Step 4: Gate Index rendering**

Create the ViewModel from `AppServiceContainer.getSettingsRepository()`. Load it in `aboutToAppear`; while it is loading show the existing loading panel. If consent is required, render `PrivacyConsentGate` instead of the diary UI. On accept, reveal the existing Index content. On decline, call `terminateSelf()` on the host `UIAbilityContext` and show a toast if termination fails.

- [ ] **Step 5: Run tests and build**

Run the focused Hypium test, then:

```bash
hvigorw assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: tests pass and the HAP compiles.

- [ ] **Step 6: Commit**

```bash
git add OneWord_dev/entry/src/main/ets/viewmodel/PrivacyConsentViewModel.ets OneWord_dev/entry/src/main/ets/components/privacy/PrivacyConsentGate.ets OneWord_dev/entry/src/main/ets/pages/Index.ets OneWord_dev/entry/src/test/PrivacyConsentViewModel.test.ets
git commit -m "feat: require privacy consent on first use"
```

### Task 3: Open the official policy from consent and Settings

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`

**Interfaces:**
- Index exposes a private `openOfficialPrivacyPolicy(): void` builder callback.
- `PrivacyPage` accepts `onOpenOfficialPolicy: () => void`.

- [ ] **Step 1: Add a single URL-opening helper in Index**

Get the host context as `common.UIAbilityContext` and call `startAbility` with an implicit Want:

```ts
{
  action: 'ohos.want.action.viewData',
  uri: PRIVACY_POLICY_URL,
  entities: ['entity.system.browsable']
}
```

Catch failures and show “暂时无法打开隐私政策，请稍后重试”. Do not add an Internet permission.

- [ ] **Step 2: Wire both entry points**

Pass the helper to `PrivacyConsentGate` and `PrivacyPage`. Rename the Settings row from “隐私说明” to “隐私政策”. In PrivacyPage retain the short local data-handling summary and add a visible “查看完整隐私政策” button that calls the callback.

- [ ] **Step 3: Build and manually validate**

Build the debug HAP. On a fresh app-data state verify: gate appears; the link invokes a browser; decline exits; accept opens the diary; relaunch stays open; Settings opens the same official URL.

- [ ] **Step 4: Commit**

```bash
git add OneWord_dev/entry/src/main/ets/pages/Index.ets OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets
git commit -m "feat: add official privacy policy entry"
```

### Task 4: Verify policy-version upgrade behavior

**Files:**
- Test: `OneWord_dev/entry/src/test/PrivacyConsentViewModel.test.ets`

- [ ] **Step 1: Add the version mismatch test**

Persist `2026-08-01`, run `load()`, and assert that the consent gate is required when the compiled constant is `2026-09-01`.

- [ ] **Step 2: Run all relevant tests and static checks**

Run:

```bash
git diff --check
rg -n "PRIVACY_POLICY_URL|PRIVACY_POLICY_VERSION|privacyPolicyAcceptedVersion" OneWord_dev/entry/src/main/ets
hvigorw test --mode module -p module=entry@default -p product=default --no-daemon
hvigorw assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

- [ ] **Step 3: Commit**

```bash
git add OneWord_dev/entry/src/test/PrivacyConsentViewModel.test.ets
git commit -m "test: cover privacy policy version upgrades"
```
