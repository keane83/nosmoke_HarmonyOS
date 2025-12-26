import { router } from '@kit.ArkUI';
import { DiaryDataManager, DiaryEntry } from '../utils/DiaryDataManager';

interface GroupedEntry {
  date: string; // 日期字符串，如 "12-09"
  entries: DiaryEntry[];
}

@Entry
@Component
struct Diary {
  @State entries: DiaryEntry[] = [];
  @State inputText: string = '';
  @State showInput: boolean = false;

  aboutToAppear() {
    this.loadEntries();
  }

  async loadEntries() {
    try {
      this.entries = await DiaryDataManager.loadEntries();
    } catch (error) {
      console.error('加载日记失败: ' + JSON.stringify(error));
      this.entries = [];
    }
  }

  async addEntry() {
    const text = this.inputText.trim();
    if (!text) {
      return;
    }

    try {
      await DiaryDataManager.addEntry(text);
      this.inputText = '';
      this.showInput = false;
      await this.loadEntries();
    } catch (error) {
      console.error('添加日记失败: ' + JSON.stringify(error));
    }
  }

  // 按日期分组
  getGroupedEntries(): GroupedEntry[] {
    const grouped = new Map<string, DiaryEntry[]>();
    
    this.entries.forEach(entry => {
      const date = new Date(entry.timestamp);
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const dateKey = `${month}-${day}`;
      
      if (!grouped.has(dateKey)) {
        grouped.set(dateKey, []);
      }
      grouped.get(dateKey)?.push(entry);
    });
    
    const result: GroupedEntry[] = [];
    const entriesArray = Array.from(grouped.entries());
    for (let i = 0; i < entriesArray.length; i++) {
      const item = entriesArray[i];
      const dateKey = item[0];
      const groupEntries = item[1];
      const group: GroupedEntry = {
        date: dateKey,
        entries: groupEntries
      };
      result.push(group);
    }
    return result;
  }

  // 格式化时间（HH:mm）
  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  build() {
    Column() {
      // 黄色头部
      Column() {
        // 顶部导航栏
        Row() {
          // 返回按钮
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
          
          Blank()
          
          // 添加日记按钮
          Text('添加日记')
            .fontSize(16)
            .fontColor('#333')
            .onClick(() => {
              this.showInput = true;
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        
        // 标题
        Text('戒烟日记')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ top: 10, bottom: 20 })
      }
      .width('100%')
      .expandSafeArea()
      .backgroundColor('#FFD700')
      .padding({ top: 20 })

      // 内容区域
      if (this.showInput) {
        // 输入区域
        Column() {
          Text('快来添加日记吧...')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')
            .margin({ bottom: 10 })
          
          TextInput({ placeholder: '写下此刻的想法...', text: this.inputText })
            .width('100%')
            .height(100)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .padding(12)
            .onChange((value: string) => {
              this.inputText = value;
            })
            .margin({ bottom: 10 })
          
          Row() {
            Button('取消')
              .type(ButtonType.Normal)
              .backgroundColor('#F5F5F5')
              .fontColor('#333')
              .onClick(() => {
                this.showInput = false;
                this.inputText = '';
              })
            
            Button('保存')
              .backgroundColor('#4A90E2')
              .fontColor('#FFFFFF')
              .onClick(() => this.addEntry())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F5F5F5')
      } else {
        Text('快来添加日记吧...')
          .fontSize(14)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 16, top: 10, bottom: 10 })
      }

      // 日记时间线列表
      if (this.entries.length > 0) {
        List() {
          ForEach(this.getGroupedEntries(), (group: GroupedEntry) => {
            ListItem() {
              Row() {
                // 右侧：日记条目
                Column() {
                  ForEach(group.entries, (entry: DiaryEntry) => {
                    Column() {
                      Row() {

                        Text(group.date)
                          .fontSize(12)
                          .fontColor('#999')

                        Text(this.formatTime(entry.timestamp))
                          .fontSize(12)
                          .fontColor('#999')

                        Blank()
                      }
                      .width('100%')
                      .margin({ bottom: 4 })
                      
                      Text(entry.content)
                        .fontSize(16)
                        .fontColor('#333')
                        .width('100%')
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#FFFFFF')
                    .borderRadius(8)
                    .margin({ bottom: 8 })
                    .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 1 })
                  })
                }
                .layoutWeight(1)
                .padding({left:16 ,right: 16 })
              }
              .width('100%')
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          Text('还没有日记，点击"添加日记"开始记录吧～')
            .fontSize(14)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .expandSafeArea()
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
