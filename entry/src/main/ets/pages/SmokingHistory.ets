import { router } from '@kit.ArkUI';
import { SmokingDataManager, DailyRecord } from '../utils/SmokingDataManager';

@Entry
@Component
struct SmokingHistory {
  @State historyRecords: DailyRecord[] = [];

  aboutToAppear() {
    this.loadHistory();
  }

  async loadHistory() {
    try {
      const records = await SmokingDataManager.getAllRecords();
      this.historyRecords = records;
      console.info(`加载历史记录: ${records.length}条`);
    } catch (error) {
      console.error('加载历史记录失败: ' + JSON.stringify(error));
      this.historyRecords = [];
    }
  }

  // 格式化日期显示（例如：2025-12-26 周四）
  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      const dayOfWeek = weekDays[date.getDay()];
      return `${dateStr} ${dayOfWeek}`;
    } catch (error) {
      return dateStr;
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_back'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .onClick(() => {
          router.back();
        })

        Text('吸烟历史记录')
          .fontSize(20)
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
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 2 })

      // 历史记录列表
      if (this.historyRecords.length === 0) {
        // 空状态
        Column() {
          Text('暂无吸烟记录')
            .fontSize(16)
            .fontColor('#999')
            .margin({ top: 100 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
      } else {
        List({ space: 12 }) {
          ForEach(this.historyRecords, (record: DailyRecord) => {
            ListItem() {
              Row() {
                // 左侧日期信息
                Column() {
                  Text(this.formatDate(record.date))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333')
                    .margin({ bottom: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 右侧统计数据
                Row() {
                  Column() {
                    Text(record.cigarettes.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF6B6B')
                    Text('根')
                      .fontSize(12)
                      .fontColor('#666')
                  }
                  .margin({ right: 24 })

                  Column() {
                    Text(record.puffs.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#4A90E2')
                    Text('口')
                      .fontSize(12)
                      .fontColor('#666')
                  }
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 1 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .expandSafeArea()
  }
}

