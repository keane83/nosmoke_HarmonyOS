import { router } from '@kit.ArkUI';
import { SmokingDataManager } from '../utils/SmokingDataManager';

@Entry
@Component
struct Statistics {
  @State todayCigarettes: number = 0; // 今日吸了多少虚拟烟
  @State todayPuffs: number = 0; // 今日吸了几口
  @State weekData: number[] = [0, 0, 0, 0, 0, 0, 0]; // 本周数据

  aboutToAppear() {
    this.loadStatistics();
  }

  async loadStatistics() {
    try {
      // 从本地存储加载统计数据
      const todayData = await SmokingDataManager.getTodayData();
      this.todayCigarettes = todayData.cigarettes;
      this.todayPuffs = todayData.puffs;
      
      const weekData = await SmokingDataManager.getWeekData();
      this.weekData = weekData;
    } catch (error) {
      console.error('加载统计数据失败: ' + JSON.stringify(error));
      // 使用默认值
      this.todayCigarettes = 0;
      this.todayPuffs = 0;
      this.weekData = [0, 0, 0, 0, 0, 0, 0];
    }
  }

  build() {
    Column() {
      Text('吸虚拟烟统计')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 30 })

      // 今日统计
      Column() {
        Text('今日统计')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        Row() {
          Column() {
            Text(this.todayCigarettes.toString())
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Text('虚拟烟')
              .fontSize(14)
              .fontColor('#666')
          }
          .width('50%')

          Column() {
            Text(this.todayPuffs.toString())
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Text('口数')
              .fontSize(14)
              .fontColor('#666')
          }
          .width('50%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
      .margin({ bottom: 30 })

      // 本周趋势图
      Column() {
        Text('本周趋势')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        // 简单的折线图
        Row() {
          ForEach(this.weekData, (value: number, index: number) => {
            Column() {
              // 柱状图表示
              Column()
                .width(30)
                .height(value * 20)
                .backgroundColor('#4A90E2')
                .borderRadius(5)
                .margin({ bottom: 5 })

              Text(`周${index + 1}`)
                .fontSize(12)
                .fontColor('#666')
            }
            .height(150)
            .justifyContent(FlexAlign.End)
            .margin({ left: 5, right: 5 })
          })
        }
        .width('100%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Bottom)
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}

