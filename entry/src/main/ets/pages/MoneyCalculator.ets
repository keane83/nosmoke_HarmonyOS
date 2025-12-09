import { router } from '@kit.ArkUI';

@Entry
@Component
struct MoneyCalculator {
  @State dailyCigarettes: number = 20; // 平均每天抽多少根
  @State packPrice: number = 25; // 一包多少元
  @State packSize: number = 20; // 一包多少根
  @State quitDays: number = 0; // 戒烟天数

  aboutToAppear() {
    this.loadSettings();
    this.calculateQuitDays();
  }

  loadSettings() {
    // TODO: 从本地存储加载设置
  }

  calculateQuitDays() {
    // TODO: 从本地存储计算戒烟天数
    // 这里先使用模拟数据
    this.quitDays = 5;
  }

  // 计算今天节省金额
  getTodaySaved(): number {
    const cigarettesPerDay = this.dailyCigarettes;
    const pricePerCigarette = this.packPrice / this.packSize;
    return cigarettesPerDay * pricePerCigarette;
  }

  // 计算本周节省金额
  getWeekSaved(): number {
    return this.getTodaySaved() * 7;
  }

  // 计算累计节省金额
  getTotalSaved(): number {
    return this.getTodaySaved() * this.quitDays;
  }

  build() {
    Column() {
      Text('戒烟金钱计算器')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 30 })

      // 输入设置
      Column() {
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        Row() {
          Text('每天根数:')
            .fontSize(16)
            .fontColor('#333')
            .width('40%')
          TextInput({ placeholder: '20', text: this.dailyCigarettes.toString() })
            .width('60%')
            .type(InputType.Number)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.dailyCigarettes = parseInt(value) || 0;
            })
        }
        .width('100%')
        .margin({ bottom: 15 })

        Row() {
          Text('一包价格:')
            .fontSize(16)
            .fontColor('#333')
            .width('40%')
          TextInput({ placeholder: '25', text: this.packPrice.toString() })
            .width('60%')
            .type(InputType.Number)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.packPrice = parseFloat(value) || 0;
            })
        }
        .width('100%')
        .margin({ bottom: 15 })

        Row() {
          Text('一包根数:')
            .fontSize(16)
            .fontColor('#333')
            .width('40%')
          TextInput({ placeholder: '20', text: this.packSize.toString() })
            .width('60%')
            .type(InputType.Number)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.packSize = parseInt(value) || 0;
            })
        }
        .width('100%')
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
      .margin({ bottom: 30 })

      // 计算结果
      Column() {
        Text('节省金额')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        Row() {
          Column() {
            Text('今天')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 10 })
            Text('¥' + this.getTodaySaved().toFixed(2))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
          }
          .width('33%')

          Column() {
            Text('本周')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 10 })
            Text('¥' + this.getWeekSaved().toFixed(2))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
          }
          .width('33%')

          Column() {
            Text('累计')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 10 })
            Text('¥' + this.getTotalSaved().toFixed(2))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
          }
          .width('33%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)

        Text(`已戒烟 ${this.quitDays} 天`)
          .fontSize(16)
          .fontColor('#666')
          .margin({ top: 20 })
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

