import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { AppLogger } from '../utils/AppLogger';

export default class BackupExtension extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    AppLogger.info('backup.on_backup complete');
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    AppLogger.info('backup.on_restore complete name=' + bundleVersion.name +
      ' code=' + bundleVersion.code);
  }
}
