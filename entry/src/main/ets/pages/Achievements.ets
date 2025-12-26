import { router } from '@kit.ArkUI';
import { SmokingDataManager } from '../utils/SmokingDataManager';
import { TriggerDataManager } from '../utils/TriggerDataManager';
import { preferences } from '@kit.ArkData';
import { AppContext } from '../utils/AppContext';

interface Achievement {
  id: string;
  name: string;
  description: string;
  unlocked: boolean;
  icon: string;
  progress?: number; // 进度（可选，用于显示进度）
  target?: number; // 目标值（可选）
}

interface PriceSettings {
  price: number;
  size: number;
}

@Entry
@Component
struct Achievements {
  @State achievements: Achievement[] = [
    {
      id: '1',
      name: '虚拟吸烟者',
      description: '完成 10 次虚拟吸烟',
      unlocked: false,
      icon: '💨',
      progress: 0,
      target: 10
    },
    {
      id: '2',
      name: '省钱达人',
      description: '累计节省 500 元',
      unlocked: false,
      icon: '💰',
      progress: 0,
      target: 500
    },
    {
      id: '3',
      name: '一周坚持',
      description: '连续 7 天都有虚拟烟记录',
      unlocked: false,
      icon: '🏆'
    },
    {
      id: '4',
      name: '记录习惯',
      description: '连续 3 天记录诱因',
      unlocked: false,
      icon: '📝'
    }
  ];

  private priceStore: preferences.Preferences | null = null;

  async aboutToAppear() {
    await this.checkAchievements();
  }

  // 初始化价格设置存储
  async initPriceStore() {
    if (!this.priceStore) {
      const context = AppContext.getContext();
      if (!context) {
        console.error('Context未设置');
        return;
      }
      this.priceStore = await preferences.getPreferences(context, 'price_settings');
    }
  }

  // 获取价格设置
  async getPriceSettings(): Promise<PriceSettings> {
    await this.initPriceStore();
    const defaultSettings: PriceSettings = { price: 20, size: 20 };
    
    if (!this.priceStore) {
      return defaultSettings;
    }
    
    try {
      const price = await this.priceStore.get('pack_price', 20) as number;
      const size = await this.priceStore.get('pack_size', 20) as number;
      const settings: PriceSettings = { price, size };
      return settings;
    } catch (error) {
      console.error('获取价格设置失败: ' + JSON.stringify(error));
      return defaultSettings;
    }
  }

  // 计算节省金额
  async calculateTotalSaved(): Promise<number> {
    try {
      const totalCigarettes = await SmokingDataManager.getTotalCigarettes();
      const priceSettings = await this.getPriceSettings();
      const pricePerCigarette = priceSettings.size > 0 ? priceSettings.price / priceSettings.size : 0;
      return totalCigarettes * pricePerCigarette;
    } catch (error) {
      console.error('计算节省金额失败: ' + JSON.stringify(error));
      return 0;
    }
  }

  // 检查一周坚持（连续7天都有虚拟烟记录）
  async checkWeekStreak(): Promise<boolean> {
    try {
      const weekData = await SmokingDataManager.getWeekData();
      // 检查本周7天是否都有记录（烟数 > 0）
      for (let i = 0; i < 7; i++) {
        if (weekData[i] <= 0) {
          return false;
        }
      }
      return true;
    } catch (error) {
      console.error('检查一周坚持失败: ' + JSON.stringify(error));
      return false;
    }
  }

  // 格式化日期为 YYYY-MM-DD
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 检查记录习惯（连续3天记录诱因）
  async checkTriggerStreak(): Promise<boolean> {
    try {
      const records = await TriggerDataManager.getAllRecords();
      if (records.length < 3) {
        return false;
      }

      // 按日期分组记录
      const recordsByDate = new Map<string, number>();
      records.forEach(record => {
        const date = new Date(record.timestamp);
        const dateStr = this.formatDate(date);
        recordsByDate.set(dateStr, (recordsByDate.get(dateStr) || 0) + 1);
      });

      // 检查最近3天是否连续
      const today = new Date();
      for (let i = 0; i < 3; i++) {
        const checkDate = new Date(today);
        checkDate.setDate(today.getDate() - i);
        const dateStr = this.formatDate(checkDate);
        
        if (!recordsByDate.has(dateStr)) {
          return false;
        }
      }

      return true;
    } catch (error) {
      console.error('检查记录习惯失败: ' + JSON.stringify(error));
      return false;
    }
  }

  // 检查并更新成就状态
  async checkAchievements() {
    try {
      // 1. 虚拟吸烟者：累计虚拟烟数 >= 10
      const totalCigarettes = await SmokingDataManager.getTotalCigarettes();
      const achievement1 = this.achievements.find(a => a.id === '1');
      if (achievement1) {
        achievement1.progress = totalCigarettes;
        achievement1.unlocked = totalCigarettes >= 10;
      }

      // 2. 省钱达人：累计节省 >= 500元
      const totalSaved = await this.calculateTotalSaved();
      const achievement2 = this.achievements.find(a => a.id === '2');
      if (achievement2) {
        achievement2.progress = totalSaved;
        achievement2.unlocked = totalSaved >= 500;
      }

      // 3. 一周坚持：连续7天都有虚拟烟记录
      const weekStreak = await this.checkWeekStreak();
      const achievement3 = this.achievements.find(a => a.id === '3');
      if (achievement3) {
        achievement3.unlocked = weekStreak;
      }

      // 4. 记录习惯：连续3天记录诱因
      const triggerStreak = await this.checkTriggerStreak();
      const achievement4 = this.achievements.find(a => a.id === '4');
      if (achievement4) {
        achievement4.unlocked = triggerStreak;
      }

      // 更新状态以触发UI刷新
      this.achievements = [...this.achievements];
      
      console.info(`成就检查完成: 虚拟吸烟者=${achievement1?.unlocked}, 省钱达人=${achievement2?.unlocked}, 一周坚持=${achievement3?.unlocked}, 记录习惯=${achievement4?.unlocked}`);
    } catch (error) {
      console.error('检查成就失败: ' + JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // 顶部标题栏，带关闭按钮
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_back'))
            .width(20)
            .height(20)
            .fillColor('#333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .onClick(() => {
          router.back();
        })

        Text('成就系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位，保持标题居中
        Column()
          .width(40)
          .height(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20 })
      .margin({ bottom: 30 })

      // 成就统计
      Row() {
        Text(`已解锁: ${this.achievements.filter(a => a.unlocked).length} / ${this.achievements.length}`)
          .fontSize(18)
          .fontColor('#333')
      }
      .width('90%')
      .margin({ bottom: 20 })

      // 成就列表
      Grid() {
        ForEach(this.achievements, (achievement: Achievement) => {
          GridItem() {
            Column() {
              Text(achievement.icon)
                .fontSize(40)
                .opacity(achievement.unlocked ? 1 : 0.3)
              
              Text(achievement.name)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(achievement.unlocked ? '#333' : '#999')
                .margin({ top: 10 })
              
              Text(achievement.description)
                .fontSize(12)
                .fontColor('#666')
                .margin({ top: 5 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              
              // 显示进度（如果有）
              if (achievement.progress !== undefined && achievement.target !== undefined) {
                Text(`${achievement.progress}/${achievement.target}`)
                  .fontSize(11)
                  .fontColor(achievement.unlocked ? '#4CAF50' : '#999')
                  .margin({ top: 5 })
              }
            }
            .width('100%')
            .height('100%')
            .padding(15)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(achievement.unlocked ? '#FFF9C4' : '#FFFFFF')
            .borderRadius(10)
            .border({
              width: achievement.unlocked ? 2 : 1,
              color: achievement.unlocked ? '#FFD700' : '#E0E0E0',
              radius: 10
            })
            .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 1 })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(15)
      .rowsGap(15)
      .width('90%')
      .layoutWeight(1)
    }
    .expandSafeArea()
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}
