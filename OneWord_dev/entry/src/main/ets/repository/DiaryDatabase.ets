import { relationalStore } from '@kit.ArkData';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { DiaryError, DiaryErrorCode } from '../model/DiaryError';

export class DiaryDatabase {
  private static readonly CONFIG: relationalStore.StoreConfig = {
    name: DatabaseConstants.DATABASE_NAME,
    securityLevel: relationalStore.SecurityLevel.S3,
    encrypt: false,
    allowRebuild: false
  };

  static async open(context: Context): Promise<relationalStore.RdbStore> {
    const store = await relationalStore.getRdbStore(context, DiaryDatabase.CONFIG);
    await DiaryDatabase.migrate(store);
    return store;
  }

  private static async migrate(store: relationalStore.RdbStore): Promise<void> {
    if (store.version > DatabaseConstants.DATABASE_VERSION) {
      throw new DiaryError(DiaryErrorCode.STORAGE_FAILED, '数据库版本高于当前应用支持的版本');
    }
    if (store.version === DatabaseConstants.DATABASE_VERSION) {
      return;
    }

    let transactionStarted: boolean = false;
    try {
      store.beginTransaction();
      transactionStarted = true;
      if (store.version < 1) {
        await store.executeSql(DatabaseConstants.CREATE_DAILY_RECORD_TABLE);
        await store.executeSql(DatabaseConstants.CREATE_SUBMITTED_AT_INDEX);
      }
      store.version = DatabaseConstants.DATABASE_VERSION;
      store.commit();
      transactionStarted = false;
    } catch (error) {
      if (transactionStarted) {
        store.rollBack();
      }
      throw new DiaryError(DiaryErrorCode.STORAGE_FAILED, '初始化日记数据库失败');
    }
  }
}
