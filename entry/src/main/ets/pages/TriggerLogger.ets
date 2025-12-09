import { router } from '@kit.ArkUI';

interface TriggerRecord {
  id: string;
  trigger: string;
  timestamp: number;
}

@Entry
@Component
struct TriggerLogger {
  @State triggerRecords: TriggerRecord[] = [];
  @State showDialog: boolean = false;
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
    // 自动弹出对话框
    this.showDialog = true;
  }

  loadRecords() {
    // TODO: 从本地存储加载记录
    // 这里先使用模拟数据
    this.triggerRecords = [];
    this.updateStats();
  }

  saveRecord(trigger: string) {
    const record: TriggerRecord = {
      id: Date.now().toString(),
      trigger: trigger,
      timestamp: Date.now()
    };
    this.triggerRecords.push(record);
    // TODO: 保存到本地存储
    this.showDialog = false;
    this.updateStats();
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
    Stack() {
      Column() {
        Text('吸烟诱因记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ top: 20, bottom: 30 })

        // 统计图表
        Column() {
          Text('诱因统计')
            .fontSize(20)
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
        .margin({ bottom: 30 })

        // 记录列表
        if (this.triggerRecords.length > 0) {
          List() {
            ForEach(this.triggerRecords, (record: TriggerRecord) => {
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

        Button('添加记录')
          .width('80%')
          .margin({ top: 20, bottom: 20 })
          .onClick(() => {
            this.showDialog = true;
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding(20)

      // 选择诱因对话框
      if (this.showDialog) {
        Column() {
          Text('你为什么想吸烟？')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ bottom: 30 })

          ForEach(this.triggerOptions, (trigger: string) => {
            Button(trigger)
              .width('80%')
              .margin({ bottom: 10 })
              .onClick(() => {
                this.saveRecord(trigger);
              })
          })

          Button('取消')
            .width('80%')
            .margin({ top: 20 })
            .type(ButtonType.Normal)
            .onClick(() => {
              this.showDialog = false;
            })
        }
        .width('80%')
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .shadow({ radius: 8, color: '#00000020', offsetX: 0, offsetY: 4 })
        .justifyContent(FlexAlign.Center)
        .alignSelf(ItemAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}

