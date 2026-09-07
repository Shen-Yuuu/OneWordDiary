import { RecordType } from './DailyRecord';

/**
 * 分享卡片的数据模型（可观察）
 */
@Observed
export class ShareCardData {
  localDate: string = '';
  recordType: RecordType = RecordType.WORD;
  content: string = '';
  noteText: string = '';  // 直接存储计算好的备注文本
  fontId: string = 'system_serif_dev';
  paperId: string = 'warm_paper_dev';
  backgroundImageId: string | null = null;

  constructor(
    localDate: string,
    recordType: RecordType,
    content: string,
    noteText: string,
    fontId: string,
    paperId: string,
    backgroundImageId: string | null = null
  ) {
    this.localDate = localDate;
    this.recordType = recordType;
    this.content = content;
    this.noteText = noteText;
    this.fontId = fontId;
    this.paperId = paperId;
    this.backgroundImageId = backgroundImageId;
  }

  updateNoteText(noteText: string): void {
    this.noteText = noteText;
  }
}
