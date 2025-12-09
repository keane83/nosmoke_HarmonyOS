import { preferences } from '@kit.ArkData';
import { AppContext } from './AppContext';

const PREF_KEY = 'smoking_data';
const DATA_KEY = 'smoking_data_json';
const PUFFS_PER_CIGARETTE = 3; // 3口 = 1根烟

interface SmokingData {
  todayPuffs: number; // 今日口数
  todayCigarettes: number; // 今日烟数
  todayDate: string; // 今日日期 YYYY-MM-DD
  weekData: number[]; // 本周每天的数据 [周一, 周二, ..., 周日]
  weekStartDate: string; // 本周开始日期
}

interface SmokingTodayData {
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

  // 获取今日日期字符串
  private static getTodayDateString(): string {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 获取本周开始日期（周一）
  private static getWeekStartDate(): string {
    const today = new Date();
    const day = today.getDay();
    const diff = today.getDate() - day + (day === 0 ? -6 : 1); // 调整为周一
    const monday = new Date(today.setDate(diff));
    const year = monday.getFullYear();
    const month = String(monday.getMonth() + 1).padStart(2, '0');
    const dayStr = String(monday.getDate()).padStart(2, '0');
    return `${year}-${month}-${dayStr}`;
  }

  // 获取今天是本周第几天（0=周一, 6=周日）
  private static getDayOfWeek(): number {
    const today = new Date();
    const day = today.getDay();
    return day === 0 ? 6 : day - 1; // 转换为 0=周一, 6=周日
  }

  // 加载数据
  static async loadData(): Promise<SmokingData> {
    if (!SmokingDataManager.dataStore) {
      await SmokingDataManager.init();
    }

    const todayDate = SmokingDataManager.getTodayDateString();
    const weekStartDate = SmokingDataManager.getWeekStartDate();

    try {
      const dataStr = await SmokingDataManager.dataStore?.get(DATA_KEY, '{}') as string;
      let data: SmokingData = JSON.parse(dataStr || '{}');

      // 如果是新的一天，重置今日数据
      if (data.todayDate !== todayDate) {
        data.todayPuffs = 0;
        data.todayCigarettes = 0;
        data.todayDate = todayDate;
      }

      // 如果是新的一周，重置本周数据
      if (data.weekStartDate !== weekStartDate) {
        data.weekData = [0, 0, 0, 0, 0, 0, 0];
        data.weekStartDate = weekStartDate;
      }

      // 确保数据结构完整
      if (!data.weekData || data.weekData.length !== 7) {
        data.weekData = [0, 0, 0, 0, 0, 0, 0];
      }

      return data;
    } catch (error) {
      console.error('加载数据失败: ' + JSON.stringify(error));
      return {
        todayPuffs: 0,
        todayCigarettes: 0,
        todayDate: todayDate,
        weekData: [0, 0, 0, 0, 0, 0, 0],
        weekStartDate: weekStartDate
      };
    }
  }

  // 保存数据
  static async saveData(data: SmokingData): Promise<void> {
    if (!SmokingDataManager.dataStore) {
      await SmokingDataManager.init();
    }

    try {
      await SmokingDataManager.dataStore?.put(DATA_KEY, JSON.stringify(data));
      await SmokingDataManager.dataStore?.flush();
    } catch (error) {
      console.error('保存数据失败: ' + JSON.stringify(error));
    }
  }

  // 记录一次吸烟（增加1口）
  static async recordPuff(): Promise<void> {
    const data = await SmokingDataManager.loadData();
    
    // 增加口数
    data.todayPuffs += 1;
    
    // 每3口 = 1根烟
    data.todayCigarettes = Math.floor(data.todayPuffs / PUFFS_PER_CIGARETTE);
    
    // 更新本周数据（按口数统计）
    const dayOfWeek = SmokingDataManager.getDayOfWeek();
    data.weekData[dayOfWeek] = data.todayPuffs;
    
    await SmokingDataManager.saveData(data);
    console.info(`记录吸烟: 今日口数=${data.todayPuffs}, 今日烟数=${data.todayCigarettes}`);
  }

  // 获取今日数据
  static async getTodayData(): Promise<SmokingTodayData> {
    const data = await SmokingDataManager.loadData();
    return {
      puffs: data.todayPuffs,
      cigarettes: data.todayCigarettes
    };
  }

  // 获取本周数据
  static async getWeekData(): Promise<number[]> {
    const data = await SmokingDataManager.loadData();
    return data.weekData;
  }
}

