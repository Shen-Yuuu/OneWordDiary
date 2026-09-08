import diaryBackgroundDomainTest from './DiaryBackgroundDomain.test';
import todayBackgroundLifecycleTest from './TodayBackgroundLifecycle.test';
import baselineTest from './Baseline.test';
import backupTest from './Backup.test';
import backupBackgroundTest from './BackupBackground.test';
import diaryConcurrencyTest from './DiaryConcurrency.test';
import diaryServiceTest from './DiaryService.test';
import diaryTextRulesTest from './DiaryTextRules.test';
import diaryTimePolicyTest from './DiaryTimePolicy.test';
import invisibleTextTest from './InvisibleText.test';
import localTimeResolverTest from './LocalTimeResolver.test';
import scrollDetailTest from './ScrollDetail.test';
import settingsViewModelTest from './SettingsViewModel.test';
import shareViewModelTest from './ShareViewModel.test';
import timeBoundaryTest from './TimeBoundary.test';
import themeCatalogTest from './ThemeCatalog.test';
import todayViewModelTest from './TodayViewModel.test';

export default function testsuite(): void {
  baselineTest();
  diaryBackgroundDomainTest();
  todayBackgroundLifecycleTest();
  backupTest();
  backupBackgroundTest();
  diaryTextRulesTest();
  diaryTimePolicyTest();
  invisibleTextTest();
  localTimeResolverTest();
  timeBoundaryTest();
  themeCatalogTest();
  scrollDetailTest();
  settingsViewModelTest();
  shareViewModelTest();
  diaryConcurrencyTest();
  diaryServiceTest();
  todayViewModelTest();
}
