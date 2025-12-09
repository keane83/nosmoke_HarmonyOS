import { router } from '@kit.ArkUI';

interface Achievement {
  id: string;
  name: string;
  description: string;
  unlocked: boolean;
  icon: string;
}

@Entry
@Component
struct Achievements {
  @State achievements: Achievement[] = [
    {
      id: '1',
      name: '坚持一小时',
      description: '不吸烟满 1 小时',
      unlocked: false,
      icon: '⏰'
    },
    {
      id: '2',
      name: '坚持一天',
      description: '不吸烟满 1 天',
      unlocked: false,
      icon: '📅'
    },
    {
      id: '3',
      name: '虚拟吸烟者',
      description: '完成 10 次虚拟吸烟',
      unlocked: false,
      icon: '💨'
    },
    {
      id: '4',
      name: '控制大师',
      description: '成功控制烟瘾 3 次',
      unlocked: false,
      icon: '🎯'
    },
    {
      id: '5',
      name: '省钱达人',
      description: '累计节省 500 元',
      unlocked: false,
      icon: '💰'
    },
    {
      id: '6',
      name: '一周坚持',
      description: '连续 7 天没抽真实烟',
      unlocked: false,
      icon: '🏆'
    },
    {
      id: '7',
      name: '记录习惯',
      description: '连续 3 天记录诱因',
      unlocked: false,
      icon: '📝'
    }
  ];

  aboutToAppear() {
    this.loadAchievements();
    this.checkAchievements();
  }

  loadAchievements() {
    // TODO: 从本地存储加载成就状态
  }

  checkAchievements() {
    // TODO: 检查并更新成就状态
    // 这里先使用模拟数据
    this.achievements[0].unlocked = true;
    this.achievements[2].unlocked = true;
  }

  build() {
    Column() {
      Text('成就系统')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 30 })

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
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(15)
      .rowsGap(15)
      .width('90%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}

