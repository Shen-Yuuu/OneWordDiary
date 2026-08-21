import { BackupError, BackupErrorCode } from '../model/BackupError';
import { BackupImportPlan, BackupImportResult, BackupUiState } from '../model/BackupModel';
import { BackupService } from '../service/BackupService';

@Observed
export class BackupViewModel {
  uiState: BackupUiState = BackupUiState.READY;
  importPlan: BackupImportPlan | null = null;
  errorMessage: string = '';
  resultMessage: string = '';

  private readonly backupService: BackupService;

  constructor(backupService: BackupService) {
    this.backupService = backupService;
  }

  get isBusy(): boolean {
    return this.uiState === BackupUiState.EXPORTING ||
      this.uiState === BackupUiState.PREPARING_IMPORT ||
      this.uiState === BackupUiState.IMPORTING;
  }

  get importSummary(): string {
    if (this.importPlan === null) {
      return '';
    }
    const styleText = this.importPlan.restoreStyle ? '并恢复备份风格' : '并保留本机风格';
    return `将导入 ${this.importPlan.importedCount} 天，跳过 ${this.importPlan.skippedCount} 天冲突记录，${styleText}。`;
  }

  async exportToUri(uri: string): Promise<boolean> {
    if (this.isBusy) {
      return false;
    }
    this.uiState = BackupUiState.EXPORTING;
    this.clearMessages();
    try {
      const recordCount = await this.backupService.exportToUri(uri);
      this.resultMessage = `已导出 ${recordCount} 天记录`;
      this.uiState = BackupUiState.RESULT;
      return true;
    } catch (error) {
      this.showError(error, '备份暂时无法导出');
      return false;
    }
  }

  async prepareImport(uri: string): Promise<boolean> {
    if (this.isBusy) {
      return false;
    }
    this.uiState = BackupUiState.PREPARING_IMPORT;
    this.importPlan = null;
    this.clearMessages();
    try {
      this.importPlan = await this.backupService.prepareImportFromUri(uri);
      this.uiState = BackupUiState.IMPORT_REVIEW;
      return true;
    } catch (error) {
      this.showError(error, '备份文件无法导入');
      return false;
    }
  }

  async confirmImport(): Promise<boolean> {
    if (this.isBusy || this.importPlan === null) {
      return false;
    }
    this.uiState = BackupUiState.IMPORTING;
    this.clearMessages();
    try {
      const result = await this.backupService.applyImport(this.importPlan);
      this.resultMessage = this.formatImportResult(result, this.importPlan.restoreStyle);
      this.importPlan = null;
      this.uiState = BackupUiState.RESULT;
      return true;
    } catch (error) {
      this.showError(error, '导入未完成，本机记录保持不变');
      return false;
    }
  }

  cancelImportReview(): void {
    if (this.uiState === BackupUiState.IMPORT_REVIEW) {
      this.importPlan = null;
      this.uiState = BackupUiState.READY;
    }
  }

  resetFeedback(): void {
    if (!this.isBusy) {
      this.clearMessages();
      this.uiState = BackupUiState.READY;
    }
  }

  private formatImportResult(result: BackupImportResult, expectedStyleRestore: boolean): string {
    let message = `已导入 ${result.importedCount} 天，跳过 ${result.skippedCount} 天`;
    if (expectedStyleRestore && !result.styleRestored) {
      message += '；记录已恢复，风格需手动选择';
    }
    return message;
  }

  private showError(error: Object, fallback: string): void {
    if (error instanceof BackupError) {
      this.errorMessage = this.messageForCode(error.code);
    } else {
      this.errorMessage = fallback;
    }
    this.uiState = BackupUiState.ERROR;
  }

  private messageForCode(code: BackupErrorCode): string {
    if (code === BackupErrorCode.FILE_TOO_LARGE) {
      return '文件超过 5 MiB，未读取任何记录';
    }
    if (code === BackupErrorCode.UNSUPPORTED_VERSION) {
      return '备份版本暂不支持，请使用匹配版本的应用';
    }
    if (code === BackupErrorCode.TOO_MANY_RECORDS) {
      return '备份记录超过 10000 条，未改变本机数据';
    }
    if (code === BackupErrorCode.INVALID_JSON || code === BackupErrorCode.INVALID_FORMAT ||
      code === BackupErrorCode.INVALID_RECORD || code === BackupErrorCode.DUPLICATE_DATE) {
      return '备份文件已损坏或内容不符合规则';
    }
    if (code === BackupErrorCode.READ_FAILED) {
      return '无法读取所选文件，请重新选择';
    }
    if (code === BackupErrorCode.WRITE_FAILED) {
      return '无法写入所选位置，请重新选择';
    }
    return '导入未完成，本机记录保持不变';
  }

  private clearMessages(): void {
    this.errorMessage = '';
    this.resultMessage = '';
  }
}

