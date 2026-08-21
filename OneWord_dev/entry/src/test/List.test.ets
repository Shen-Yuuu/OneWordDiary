import baselineTest from './Baseline.test';
import backupTest from './Backup.test';
import diaryConcurrencyTest from './DiaryConcurrency.test';
import diaryServiceTest from './DiaryService.test';
import diaryTextRulesTest from './DiaryTextRules.test';
import diaryTimePolicyTest from './DiaryTimePolicy.test';
import invisibleTextTest from './InvisibleText.test';
import localTimeResolverTest from './LocalTimeResolver.test';
import scrollDetailTest from './ScrollDetail.test';
import settingsViewModelTest from './SettingsViewModel.test';
import timeBoundaryTest from './TimeBoundary.test';
import todayViewModelTest from './TodayViewModel.test';

export default function testsuite(): void {
  baselineTest();
  backupTest();
  diaryTextRulesTest();
  diaryTimePolicyTest();
  invisibleTextTest();
  localTimeResolverTest();
  timeBoundaryTest();
  scrollDetailTest();
  settingsViewModelTest();
  diaryConcurrencyTest();
  diaryServiceTest();
  todayViewModelTest();
}
