import { preferences } from '@kit.ArkData';
import { AppContext } from './AppContext';

const PREF_KEY = 'diary_data';
const DATA_KEY = 'diary_entries_json';

export interface DiaryEntry {
  id: string;
  content: string;
  timestamp: number;
}

export class DiaryDataManager {
  private static dataStore: preferences.Preferences | null = null;

  // 初始化数据存储
  static async init(): Promise<void> {
    const context = AppContext.getContext();
    if (!context) {
      console.error('Context未设置，无法初始化日记数据存储');
      return;
    }
    try {
      DiaryDataManager.dataStore = await preferences.getPreferences(context, PREF_KEY);
    } catch (error) {
      console.error('初始化日记数据存储失败: ' + JSON.stringify(error));
    }
  }

  // 加载所有日记
  static async loadEntries(): Promise<DiaryEntry[]> {
    if (!DiaryDataManager.dataStore) {
      await DiaryDataManager.init();
    }

    try {
      const dataStr = await DiaryDataManager.dataStore?.get(DATA_KEY, '[]') as string;
      const entries: DiaryEntry[] = JSON.parse(dataStr || '[]');
      // 按时间倒序排列（最新的在前）
      return entries.sort((a, b) => b.timestamp - a.timestamp);
    } catch (error) {
      console.error('加载日记失败: ' + JSON.stringify(error));
      return [];
    }
  }

  // 保存所有日记
  static async saveEntries(entries: DiaryEntry[]): Promise<void> {
    if (!DiaryDataManager.dataStore) {
      await DiaryDataManager.init();
    }

    try {
      await DiaryDataManager.dataStore?.put(DATA_KEY, JSON.stringify(entries));
      await DiaryDataManager.dataStore?.flush();
    } catch (error) {
      console.error('保存日记失败: ' + JSON.stringify(error));
    }
  }

  // 添加一条日记
  static async addEntry(content: string): Promise<void> {
    const entries = await DiaryDataManager.loadEntries();
    const newEntry: DiaryEntry = {
      id: Date.now().toString(),
      content: content.trim(),
      timestamp: Date.now()
    };
    entries.unshift(newEntry); // 添加到开头
    await DiaryDataManager.saveEntries(entries);
  }

  // 删除一条日记
  static async deleteEntry(id: string): Promise<void> {
    const entries = await DiaryDataManager.loadEntries();
    const filtered = entries.filter(e => e.id !== id);
    await DiaryDataManager.saveEntries(filtered);
  }
}

