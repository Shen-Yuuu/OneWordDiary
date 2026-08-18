import { ScrollDisplayItem } from '../model/ScrollDisplayItem';
import { BasicDataSource } from '../utils/BasicDataSource';

export class ScrollDataSource extends BasicDataSource<ScrollDisplayItem> {
  private items: ScrollDisplayItem[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): ScrollDisplayItem {
    return this.items[index];
  }

  replaceAll(items: ScrollDisplayItem[]): void {
    this.items = items.slice();
    this.notifyDataReload();
  }

  append(items: ScrollDisplayItem[]): void {
    const firstNewIndex = this.items.length;
    this.items = this.items.concat(items);
    for (let index = 0; index < items.length; index++) {
      this.notifyDataAdd(firstNewIndex + index);
    }
  }

  lastItem(): ScrollDisplayItem | null {
    return this.items.length === 0 ? null : this.items[this.items.length - 1];
  }

  snapshot(): ScrollDisplayItem[] {
    return this.items.slice();
  }
}
