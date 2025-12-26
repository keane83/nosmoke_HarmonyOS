import { router } from '@kit.ArkUI';

@Entry
@Component
struct HowToUse {
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

        Text('使用说明')
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
      .margin({ bottom: 40 })

      // 图片和说明
      Column() {
        // 图片（使用startIcon，如果没有appicon）
        Image($r('app.media.howtouse'))
          .width('80%')
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 30 })

        // 说明文字
        Text('嘴贴近麦克风发出吸气声')
          .fontSize(20)
          .fontColor('#333')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 20 })

        Text('(尽量在安静环境下使用)')
          .fontSize(15)
          .fontColor('#333')
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
    .backgroundColor('#F5F5F5')
  }
}

