import { router } from '@kit.ArkUI';
import { SmokingDataManager } from '../utils/SmokingDataManager';
import { preferences } from '@kit.ArkData';
import { AppContext } from '../utils/AppContext';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct MoneyCalculator {
  @State packPriceText: string = '20'; // 一包价格文本输入
  @State packSizeText: string = '20'; // 一包根数文本输入
  @State todayCigarettes: number = 0; // 今天吸的虚拟烟根数
  @State weekCigarettes: number = 0; // 本周吸的虚拟烟根数
  @State totalCigarettes: number = 0; // 累计吸的虚拟烟根数
  
  private dataStore: preferences.Preferences | null = null;
  
  // 获取数值
  get packPrice(): number {
    return parseFloat(this.packPriceText) || 20;
  }
  
  get packSize(): number {
    return parseInt(this.packSizeText) || 20;
  }

  async aboutToAppear() {
    console.info('MoneyCalculator aboutToAppear 开始');
    await this.loadSettings();
    await this.loadCigaretteData();
    console.info('MoneyCalculator 初始化完成');
  }

  async loadSettings() {
    try {
      const context = AppContext.getContext();
      if (!context) {
        console.error('Context未设置，无法加载价格设置');
        promptAction.showToast({
          message: 'Context未初始化',
          duration: 2000
        });
        return;
      }
      
      // 初始化 dataStore
      this.dataStore = await preferences.getPreferences(context, 'price_settings');
      console.info('dataStore初始化成功');
      
      // 加载保存的设置
      const savedPrice = await this.dataStore.get('pack_price', 20) as number;
      const savedSize = await this.dataStore.get('pack_size', 20) as number;
      this.packPriceText = savedPrice.toString();
      this.packSizeText = savedSize.toString();
      
      console.info(`加载价格设置: 一包¥${savedPrice}, ${savedSize}根`);
    } catch (error) {
      console.error('加载价格设置失败: ' + JSON.stringify(error));
      // 即使加载失败，也使用默认值
      this.packPriceText = '20';
      this.packSizeText = '20';
    }
  }
  
  // 保存设置并重新计算
  async saveAndRefresh() {
    if (!this.dataStore) {
      console.error('dataStore未初始化，无法保存');
      promptAction.showToast({
        message: '保存失败: 数据存储未初始化',
        duration: 2000
      });
      return;
    }
    
    try {

      let packPrice = parseFloat(this.packPriceText)

      let packSize = parseFloat(this.packSizeText) || 20;

      // 保存价格和根数设置
      await this.dataStore.put('pack_price', packPrice);
      await this.dataStore.put('pack_size', packSize);
      await this.dataStore.flush();
      
      console.info(`价格设置已保存: 一包¥${packPrice}, ${packSize}根`);
      
      // 重新加载虚拟烟数据并计算
      await this.loadCigaretteData();
      
      promptAction.showToast({
        message: '保存成功，已重新计算',
        duration: 1500
      });
    } catch (error) {
      console.error('保存价格设置失败: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    }
  }

  async loadCigaretteData() {
    try {
      const todayData = await SmokingDataManager.getTodayData();
      this.todayCigarettes = todayData.cigarettes;
      
      this.weekCigarettes = await SmokingDataManager.getWeekTotal();
      this.totalCigarettes = await SmokingDataManager.getTotalCigarettes();
      
      console.info(`加载数据: 今天=${this.todayCigarettes}, 本周=${this.weekCigarettes}, 累计=${this.totalCigarettes}`);
    } catch (error) {
      console.error('加载虚拟烟数据失败: ' + JSON.stringify(error));
    }
  }

  // 计算每根烟的价格
  getPricePerCigarette(): number {
    let price = parseFloat(this.packPriceText) || 20
    let size = parseInt(this.packSizeText) || 20;
    if (size === 0) return 0;
    return price / size;
  }

  // 计算今天节省金额
  getTodaySaved(): number {
    return this.todayCigarettes * this.getPricePerCigarette();
  }

  // 计算本周节省金额
  getWeekSaved(): number {
    return this.weekCigarettes * this.getPricePerCigarette();
  }

  // 计算累计节省金额
  getTotalSaved(): number {
    return this.totalCigarettes * this.getPricePerCigarette();
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

        Text('戒烟金钱计算器')
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

      // 香烟价格设置
      Column() {
        Text('香烟价格设置')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        Row() {
          Text('一包价格:')
            .fontSize(16)
            .fontColor('#333')
            .width('40%')
          TextInput({ placeholder: '20', text: this.packPriceText })
            .width('60%')
            .type(InputType.Number)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.packPriceText = value;
            })
        }
        .width('100%')
        .margin({ bottom: 15 })

        Row() {
          Text('一包根数:')
            .fontSize(16)
            .fontColor('#333')
            .width('40%')
          TextInput({ placeholder: '20', text: this.packSizeText })
            .width('60%')
            .type(InputType.Number)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.packSizeText = value;
            })
        }
        .width('100%')
        .margin({ bottom: 15 })

        Row() {
          Text('每根价格:')
            .fontSize(16)
            .fontColor('#666')
            .width('40%')
          Text('¥' + this.getPricePerCigarette().toFixed(2))
            .fontSize(16)
            .fontColor('#4CAF50')
            .width('60%')
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 刷新按钮
        Button('刷新并保存')
          .width('100%')
          .height(45)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.saveAndRefresh();
          })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
      .margin({ bottom: 30 })

      // 计算结果
      Column() {
        Text('节省金额（基于虚拟烟）')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 20 })

        Row() {
          Column() {
            Text('今天')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 5 })
            Text('¥' + this.getTodaySaved().toFixed(2))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text(`${this.todayCigarettes}根`)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 5 })
          }
          .width('33%')

          Column() {
            Text('本周')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 5 })
            Text('¥' + this.getWeekSaved().toFixed(2))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text(`${this.weekCigarettes}根`)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 5 })
          }
          .width('33%')

          Column() {
            Text('累计')
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 5 })
            Text('¥' + this.getTotalSaved().toFixed(2))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text(`${this.totalCigarettes}根`)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 5 })
          }
          .width('33%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .shadow({ radius: 4, color: '#E0E0E0', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
    .backgroundColor('#F5F5F5')
  }
}

