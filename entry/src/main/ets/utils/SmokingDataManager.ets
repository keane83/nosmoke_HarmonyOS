import { preferences } from '@kit.ArkData';
import { AppContext } from './AppContext';

const PREF_KEY = 'smoking_data';
const DATA_KEY = 'smoking_history_json';

// 每日数据记录
export interface DailyRecord {
  date: string; // YYYY-MM-DD
  puffs: number; // 当天口数
  cigarettes: number; // 当天烟数
}

// 历史数据结构（使用日期为key的映射）
interface SmokingHistory {
  records: Record<string, DailyRecord>; // { "2025-12-26": { date, puffs, cigarettes }, ... }
}

export interface SmokingTodayData {
  puffs: number;
  cigarettes: number;
}

export class SmokingDataManager {
  private static dataStore: preferences.Preferences | null = null;

  // 初始化数据存储
  static async init(): Promise<void> {
    const context = AppContext.getContext();
    if (!context) {
      console.error('Context未设置，无法初始化数据存储');
      return;
    }
    try {
      SmokingDataManager.dataStore = await preferences.getPreferences(context, PREF_KEY);
    } catch (error) {
      console.error('初始化数据存储失败: ' + JSON.stringify(error));
    }
  }

  // 获取日期字符串 YYYY-MM-DD
  private static getDateString(date: Date = new Date()): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 加载历史数据
  static async loadHistory(): Promise<SmokingHistory> {
    if (!SmokingDataManager.dataStore) {
      await SmokingDataManager.init();
    }

    try {
      const dataStr = await SmokingDataManager.dataStore?.get(DATA_KEY, '{"records":{}}') as string;
      const history: SmokingHistory = JSON.parse(dataStr || '{"records":{}}');
      
      // 确保数据结构完整
      if (!history.records) {
        history.records = {};
      }
      
      return history;
    } catch (error) {
      console.error('加载历史数据失败: ' + JSON.stringify(error));
      return { records: {} };
    }
  }

  // 保存历史数据
  static async saveHistory(history: SmokingHistory): Promise<void> {
    if (!SmokingDataManager.dataStore) {
      await SmokingDataManager.init();
    }

    try {
      await SmokingDataManager.dataStore?.put(DATA_KEY, JSON.stringify(history));
      await SmokingDataManager.dataStore?.flush();
    } catch (error) {
      console.error('保存历史数据失败: ' + JSON.stringify(error));
    }
  }

  // 获取指定日期的记录
  private static getDateRecord(history: SmokingHistory, dateStr: string): DailyRecord {
    if (!history.records[dateStr]) {
      history.records[dateStr] = {
        date: dateStr,
        puffs: 0,
        cigarettes: 0
      };
    }
    return history.records[dateStr];
  }

  // 记录一次吸烟（增加1口）
  static async recordPuff(): Promise<void> {
    const todayDate = SmokingDataManager.getDateString();
    const history = await SmokingDataManager.loadHistory();
    const todayRecord = SmokingDataManager.getDateRecord(history, todayDate);
    
    todayRecord.puffs += 1;
    
    await SmokingDataManager.saveHistory(history);
    console.info(`记录吸烟: 今日口数=${todayRecord.puffs}, 今日烟数=${todayRecord.cigarettes}`);
  }

  // 记录完整吸完一根
  static async recordCigarette(): Promise<void> {
    const todayDate = SmokingDataManager.getDateString();
    const history = await SmokingDataManager.loadHistory();
    const todayRecord = SmokingDataManager.getDateRecord(history, todayDate);
    
    todayRecord.cigarettes += 1;
    
    await SmokingDataManager.saveHistory(history);
    console.info(`记录整根: 今日烟数=${todayRecord.cigarettes}, 今日口数=${todayRecord.puffs}`);
  }

  // 获取今日数据
  static async getTodayData(): Promise<SmokingTodayData> {
    const todayDate = SmokingDataManager.getDateString();
    const history = await SmokingDataManager.loadHistory();
    const todayRecord = SmokingDataManager.getDateRecord(history, todayDate);
    
    return {
      puffs: todayRecord.puffs,
      cigarettes: todayRecord.cigarettes
    };
  }

  // 获取本周数据（周一到周日的烟数数组）
  static async getWeekData(): Promise<number[]> {
    const history = await SmokingDataManager.loadHistory();
    const weekData: number[] = [0, 0, 0, 0, 0, 0, 0]; // 周一到周日
    
    // 获取本周一的日期
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0=周日, 1=周一, ..., 6=周六
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek; // 计算到周一的偏移
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + mondayOffset + i);
      const dateStr = SmokingDataManager.getDateString(date);
      
      if (history.records[dateStr]) {
        weekData[i] = history.records[dateStr].cigarettes;
      }
    }
    
    return weekData;
  }
  
  // 获取本周总烟数
  static async getWeekTotal(): Promise<number> {
    const weekData = await SmokingDataManager.getWeekData();
    return weekData.reduce((sum, count) => sum + count, 0);
  }
  
  // 获取累计总烟数
  static async getTotalCigarettes(): Promise<number> {
    const history = await SmokingDataManager.loadHistory();
    let total = 0;
    
    const dateKeys = Object.keys(history.records);
    for (let i = 0; i < dateKeys.length; i++) {
      const dateKey = dateKeys[i];
      total += history.records[dateKey].cigarettes;
    }
    
    return total;
  }

  // 获取所有历史记录（按日期倒序）
  static async getAllRecords(): Promise<DailyRecord[]> {
    const history = await SmokingDataManager.loadHistory();
    const records: DailyRecord[] = [];
    
    const dateKeys = Object.keys(history.records);
    for (let i = 0; i < dateKeys.length; i++) {
      const dateKey = dateKeys[i];
      const record = history.records[dateKey];
      // 只返回有数据的记录
      if (record.cigarettes > 0 || record.puffs > 0) {
        records.push(record);
      }
    }
    
    // 按日期倒序排序
    records.sort((a, b) => b.date.localeCompare(a.date));
    
    return records;
  }
}
