import { preferences } from '@kit.ArkData';
import { AppContext } from './AppContext';

const PREF_KEY = 'trigger_data';
const DATA_KEY = 'trigger_records_json';

export interface TriggerRecord {
  id: string;
  trigger: string;
  timestamp: number;
}

interface TriggerData {
  records: TriggerRecord[];
}

export class TriggerDataManager {
  private static dataStore: preferences.Preferences | null = null;

  // 初始化数据存储
  static async init(): Promise<void> {
    const context = AppContext.getContext();
    if (!context) {
      console.error('Context未设置，无法初始化诱因数据存储');
      return;
    }
    try {
      TriggerDataManager.dataStore = await preferences.getPreferences(context, PREF_KEY);
    } catch (error) {
      console.error('初始化诱因数据存储失败: ' + JSON.stringify(error));
    }
  }

  // 加载数据
  static async loadData(): Promise<TriggerData> {
    if (!TriggerDataManager.dataStore) {
      await TriggerDataManager.init();
    }

    try {
      const dataStr = await TriggerDataManager.dataStore?.get(DATA_KEY, '{}') as string;
      let data: TriggerData = JSON.parse(dataStr || '{}');

      // 确保数据结构完整
      if (!data.records || !Array.isArray(data.records)) {
        data.records = [];
      }

      return data;
    } catch (error) {
      console.error('加载诱因数据失败: ' + JSON.stringify(error));
      return { records: [] };
    }
  }

  // 保存数据
  static async saveData(data: TriggerData): Promise<void> {
    if (!TriggerDataManager.dataStore) {
      await TriggerDataManager.init();
    }

    try {
      await TriggerDataManager.dataStore?.put(DATA_KEY, JSON.stringify(data));
      await TriggerDataManager.dataStore?.flush();
    } catch (error) {
      console.error('保存诱因数据失败: ' + JSON.stringify(error));
    }
  }

  // 添加一条诱因记录
  static async addRecord(trigger: string): Promise<void> {
    const data = await TriggerDataManager.loadData();
    
    const record: TriggerRecord = {
      id: Date.now().toString(),
      trigger: trigger,
      timestamp: Date.now()
    };
    
    data.records.push(record);
    await TriggerDataManager.saveData(data);
    console.info(`记录诱因: ${trigger}, 总记录数: ${data.records.length}`);
  }

  // 获取所有记录
  static async getAllRecords(): Promise<TriggerRecord[]> {
    const data = await TriggerDataManager.loadData();
    return data.records;
  }

  // 获取统计数据
  static async getStats(triggerOptions: string[]): Promise<Array<[string, number]>> {
    const data = await TriggerDataManager.loadData();
    const stats = new Map<string, number>();
    
    triggerOptions.forEach(trigger => {
      stats.set(trigger, 0);
    });
    
    data.records.forEach(record => {
      const count = stats.get(record.trigger) || 0;
      stats.set(record.trigger, count + 1);
    });
    
    return Array.from(stats.entries());
  }
}

