import { router } from '@kit.ArkUI';

@Entry
@Component
struct CigaretteSelection {
  @State selectedIndex: number = 0;

  build() {
    Column() {
      Text('选择香烟')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 30 })

      List() {
        // 显示10种烟，暂时都用smoke.png
        ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], (index: number) => {
          ListItem() {
            Row() {
              Image($r('app.media.smoke'))
                .width(200)
                .height(60)
                .objectFit(ImageFit.Contain)
                .border({
                  width: this.selectedIndex === index ? 3 : 1,
                  color: this.selectedIndex === index ? '#4A90E2' : '#E0E0E0',
                  radius: 5
                })
              
              Text(`香烟 ${index + 1}`)
                .fontSize(18)
                .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedIndex === index ? '#4A90E2' : '#333')
                .margin({ left: 20 })
              
              Blank()
              
              if (this.selectedIndex === index) {
                Text('✓')
                  .fontSize(24)
                  .fontColor('#4A90E2')
                  .margin({ right: 10 })
              }
            }
            .width('100%')
            .height(80)
            .padding({ left: 15, right: 15 })
            .backgroundColor(this.selectedIndex === index ? '#E3F2FD' : '#FFFFFF')
            .borderRadius(10)
            .margin({ bottom: 10 })
            .shadow({ radius: 2, color: '#E0E0E0', offsetX: 0, offsetY: 1 })
            .onClick(() => {
              this.selectedIndex = index;
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })

      Button('确定')
        .width('80%')
        .margin({ top: 20, bottom: 30 })
        .onClick(() => {
          // 保存选中的香烟
          // TODO: 保存到本地存储
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

