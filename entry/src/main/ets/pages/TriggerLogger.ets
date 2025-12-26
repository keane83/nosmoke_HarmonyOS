import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { TriggerDataManager, TriggerRecord } from '../utils/TriggerDataManager';

@Entry
@Component
struct TriggerLogger {
  @State triggerRecords: TriggerRecord[] = [];
  @State showRecords: boolean = false; // 是否显示记录列表（false=选择诱因，true=查看记录）
  @State selectedTrigger: string = '';
  @State triggerStats: Array<[string, number]> = []; // 统计结果

  private triggerOptions: string[] = [
    '压力',
    '无聊',
    '饭后',
    '社交习惯',
    '情绪低落',
    '惯性'
  ];

  aboutToAppear() {
    this.loadRecords();
  }

  async loadRecords() {
    try {
      this.triggerRecords = await TriggerDataManager.getAllRecords();
      this.updateStats();
    } catch (error) {
      console.error('加载诱因记录失败: ' + JSON.stringify(error));
      this.triggerRecords = [];
      this.updateStats();
    }
  }

  async saveRecord(trigger: string) {
    try {
      await TriggerDataManager.addRecord(trigger);
      
      // 显示 toast 提示
      promptAction.showToast({
        message: '记录诱因成功',
        duration: 3000
      });
      
      // 重新加载数据
      await this.loadRecords();
      
      // 延迟返回，让用户看到 toast
      setTimeout(() => {
        router.back();
      }, 500);
    } catch (error) {
      console.error('保存诱因记录失败: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '记录失败，请重试',
        duration: 2000
      });
    }
  }

  // 更新统计数据
  updateStats() {
    const stats = new Map<string, number>();
    this.triggerOptions.forEach(trigger => {
      stats.set(trigger, 0);
    });
    this.triggerRecords.forEach(record => {
      const count = stats.get(record.trigger) || 0;
      stats.set(record.trigger, count + 1);
    });
    this.triggerStats = Array.from(stats.entries());
  }

  build() {
    Column() {

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

        Text('诱因')
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
      .backgroundColor("#F5F5F5")
      .expandSafeArea()

      if (!this.showRecords) {
        // 选择诱因界面
        Column() {
          Text('你为什么想吸烟？')
            .fontSize(18)
            .fontColor('#666')
            .margin({ top: 30, bottom: 40 })

          ForEach(this.triggerOptions, (trigger: string) => {
            Button(trigger)
              .width('70%')
              .height(50)
              .fontSize(16)
              .margin({ bottom: 15 })
              .onClick(() => {
                this.saveRecord(trigger);
              })
          })

          Button('查看诱因记录')
            .width('70%')
            .height(50)
            .fontSize(16)
            .margin({ top: 30 })
            .backgroundColor('#E0E0E0')
            .fontColor('#333')
            .onClick(() => {
              this.showRecords = true;
            })
        }
        .width('100%')
        // .height('100%')
        .expandSafeArea()
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
      } else {
        // 查看记录界面
        Column() {
          Row() {
            
            Blank().width(80)

            Blank()

            Text('诱因记录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            
            Blank()
            
            Button('选诱因')
              .fontSize(16)
              .type(ButtonType.Normal)
              .onClick(() => {
                this.showRecords = false;
              })
              .borderRadius(10)
              .width(80)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 10 })

          // 统计图表
          Column() {
            Text('诱因统计')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333')
              .margin({ bottom: 20 })

            ForEach(this.triggerStats, (item: [string, number]) => {
              Row() {
                Text(item[0])
                  .fontSize(16)
                  .fontColor('#333')
                  .width('30%')
                
                Progress({ value: item[1], total: Math.max(1, Math.max(...this.triggerStats.map(i => i[1]))) })
                  .width('50%')
                  .color('#4A90E2')
                
                Text(item[1].toString())
                  .fontSize(16)
                  .fontColor('#333')
                  .width('20%')
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .margin({ bottom: 15 })
            })
          }
          .width('90%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
          .margin({ top: 20, bottom: 20 })

          // 记录列表
          Text('记录列表')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 10 })

          if (this.triggerRecords.length > 0) {
            List() {
              ForEach(this.triggerRecords.slice().reverse(), (record: TriggerRecord) => {
                ListItem() {
                  Row() {
                    Text(record.trigger)
                      .fontSize(16)
                      .fontColor('#333')
                    Blank()
                    Text(new Date(record.timestamp).toLocaleString())
                      .fontSize(12)
                      .fontColor('#666')
                  }
                  .width('100%')
                  .padding(15)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(5)
                  .margin({ bottom: 5 })
                }
              })
            }
            .width('90%')
            .layoutWeight(1)
          } else {
            Text('暂无记录')
              .fontSize(16)
              .fontColor('#666')
              .layoutWeight(1)
          }
        }
        .width('100%')
        // .height('100%')
        // .expandSafeArea()
        .backgroundColor('#F5F5F5')
      }
    }
    .expandSafeArea()
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

