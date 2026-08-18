export abstract class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];

  abstract totalCount(): number;

  abstract getData(index: number): T;

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  protected notifyDataReload(): void {
    for (const listener of this.listeners) {
      listener.onDataReloaded();
    }
  }

  protected notifyDataAdd(index: number): void {
    for (const listener of this.listeners) {
      listener.onDataAdd(index);
    }
  }
}
