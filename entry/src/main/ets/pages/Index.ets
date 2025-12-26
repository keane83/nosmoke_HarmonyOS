import sensor from '@ohos.sensor';
import { router } from '@kit.ArkUI';
import audio from '@ohos.multimedia.audio';
import { SmokingDataManager } from '../utils/SmokingDataManager';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { MicrophoneManager } from '../sensor/SensorManager';




interface Vector3 {
  x: number;
  y: number;
  z: number;
}

interface CigaretteMetrics {
  containerHeight: number;
  tailHeight: number;
  headHeight: number;
  containerTop: number;
}

interface ActionItem {
  label: string;
  action: () => void;
}

@Entry
@Component
struct Index {
  @State viewWidth: number = 0;
  @State viewHeight: number = 0;
  @State tiltAngle: number = 0;
  @State isUpright: boolean = false;
  @State smokeAngleRange: [number, number] = [265, 275];
  @State disturbanceX: number = 0;
  @State cigaretteLength: number = 1.0; // 香烟长度比例，1.0为完整，0.0为完全吸完
  @State smokePositionY: number = 0; // 烟雾发射位置Y坐标（烟头位置）
  @State smokePositionX: number = 0; // 烟雾发射位置X坐标（烟头水平居中）
  @State actionProgress: number = 0; // 小按钮展开进度 0-1
  @State bigSpin: number = 0; // 大按钮旋转角度
  @State miniSpin: number = 0; // 小按钮旋转角度
  @State isAnimatingActions: boolean = false;
  @State isSmokeFinished: boolean = false; // 是否已经吸完（用于暂停粒子）
  @State smokeOpacity: number = 1.0; // 烟雾透明度，吸烟时降低来模拟烟被吸入
  private actionAngles: number[] = [0, 18, 36, 54, 72, 90]; // 六个按钮，间隔18度
  private actionDistance: number = 200;
  
  private gyroListener?: (data: Vector3) => void;
  private accumulatedTilt: number = 0;
  private lastUpdateTime: number = 0;
  private audioCapturer?: audio.AudioCapturer;
  private isCapturing: boolean = false;
  private lastSmokeTime: number = 0;
  private autoSmokeTimer?: number; // 5s 自动灼烧定时器
  private finishThreshold: number = 0.08; // 认为接近烟蒂的阈值（8%）
  private smokeRecoveryTimer?: number; // 吸烟后烟雾恢复的定时器


  private microphoneManager: MicrophoneManager = MicrophoneManager.getInstance();
  private checkTimer: number = -1;
  private isSmorking: boolean = false;

  // 计算香烟尺寸信息
  private getCigaretteMetrics(): CigaretteMetrics {
    const containerHeight = this.viewHeight * 0.6;
    const tailHeight = containerHeight * 0.2; // 烟蒂固定高度
    const headHeight = containerHeight - tailHeight; // 烟身高度
    const containerTop = (this.viewHeight - containerHeight) / 2;
    return { containerHeight, tailHeight, headHeight, containerTop };
  }

  // 更新烟雾发射点，确保位于香烟顶部中心
  private updateSmokePosition(): void {
    if (this.viewWidth <= 0 || this.viewHeight <= 0) {
      return;
    }
    const metrics = this.getCigaretteMetrics();
    // 随着吸烟，头部向下移动，发射点跟随
    this.smokePositionY = metrics.containerTop + (metrics.headHeight * (1 - this.cigaretteLength));
    this.smokePositionX = this.viewWidth / 2;
    if (this.disturbanceX === 0) {
      this.disturbanceX = this.viewWidth / 2;
    }
  }

  aboutToAppear() {
    // this.initMicrophone();
    //this.initGyroscope();
    this.startAutoBurn();
    this.startGame()
  }

  // 初始化麦克风
  async initMicrophone() {
    try {
      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      const audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };

      this.audioCapturer = await audio.createAudioCapturer({
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      });

      if (this.audioCapturer) {
        await this.audioCapturer.start();
        this.isCapturing = true;
        this.startAudioMonitoring();
      }
    } catch (error) {
      const err = error as Error;
      console.error('LIUJIAN 初始化麦克风失败: ' + err.message);
    }
  }

  // 监控音频输入
  async startAudioMonitoring() {
    if (!this.audioCapturer || !this.isCapturing) return;

    try {
      const bufferSize = await this.audioCapturer.getBufferSize();

      const checkAudio = async () => {
        if (!this.isCapturing || !this.audioCapturer) return;

        try {
          // read方法：第一个参数是size（number），第二个参数是是否阻塞，返回Promise<ArrayBuffer>
          const audioBuffer = await this.audioCapturer.read(bufferSize, true);
          if (audioBuffer && audioBuffer.byteLength > 0) {
            // 计算音频音量
            const view = new Int16Array(audioBuffer);
            let sum = 0;
            for (let i = 0; i < view.length; i++) {
              sum += Math.abs(view[i]);
            }
            const average = view.length > 0 ? sum / view.length : 0;
            const volume = average / 32768; // 归一化到0-1

            console.error('LIUJIAN 音量: ' + volume);

            // 检测到声音（模拟吸烟），音量阈值可以调整
            if (volume > 0.15) {
              const now = Date.now();
              // 防止频繁触发，至少间隔500ms
              if (now - this.lastSmokeTime > 500) {
                this.lastSmokeTime = now;
                this.simulateSmoking();
              }
            }
          }
          // 继续监控
          setTimeout(checkAudio, 100);
        } catch (error) {
          const err = error as Error;
          console.error('LIUJIAN 读取音频失败: ' + err.message);
          setTimeout(checkAudio, 100);
        }
      };

      checkAudio();
    } catch (error) {
      const err = error as Error;
      console.error('LIUJIAN 获取缓冲区大小失败: ' + err.message);
    }
  }

  // 统一缩短逻辑，支持自动/手动
  private shrinkCigarette(step: number, duration: number = 350) {
    if (this.isSmokeFinished || step <= 0) {
      return;
    }
    const targetLength = Math.max(0, this.cigaretteLength - step);
    animateTo({
      duration,
      curve: Curve.EaseOut
    }, () => {
      this.cigaretteLength = targetLength;
      this.updateSmokePosition();
      if (this.cigaretteLength <= this.finishThreshold) {
        this.handleCigaretteFinished();
      }
    });
  }

  // 模拟吸烟：带动画地缩短香烟（手动/声音触发）
  async simulateSmoking() {
    // 如果已吸完，不响应（需手动重置）
    if (this.isSmokeFinished) {
      return;
    }

    // 记录吸烟数据到持久化存储
    try {
      await SmokingDataManager.recordPuff();
      const todayData = await SmokingDataManager.getTodayData();
      console.info(`检测到吸烟，当前香烟长度: ${(this.cigaretteLength * 100).toFixed(0)}%, 今日口数: ${todayData.puffs}, 今日烟数: ${todayData.cigarettes}`);
    } catch (error) {
      console.error('记录吸烟数据失败: ' + JSON.stringify(error));
    }

    // 吸烟时降低烟雾透明度，模拟烟被吸入（不改变emitRate，避免粒子系统重置）
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.smokeOpacity = 0.15; // 降低到15%透明度
    });
    
    // 清除之前的恢复定时器（如果存在）
    if (this.smokeRecoveryTimer !== undefined) {
      clearTimeout(this.smokeRecoveryTimer);
    }
    
    // 3秒后恢复正常烟雾透明度
    this.smokeRecoveryTimer = setTimeout(() => {
      animateTo({ duration: 800, curve: Curve.EaseIn }, () => {
        this.smokeOpacity = 1.0; // 恢复到100%
        this.isSmorking = false
      });
      this.smokeRecoveryTimer = undefined;
    }, 1000);

    this.shrinkCigarette(0.05, 400);
  }

  // 自动燃烧：每5秒轻微缩短一次
  private startAutoBurn() {
    this.stopAutoBurn();
    this.autoSmokeTimer = setInterval(() => {
      this.autoBurnTick();
    }, 100); // 0.1s 一次，保持更平滑的自然燃烧
  }

  private stopAutoBurn() {
    if (this.autoSmokeTimer !== undefined) {
      clearInterval(this.autoSmokeTimer);
      this.autoSmokeTimer = undefined;
    }
  }

  private autoBurnTick() {
    // 原先 5s 缩 0.015，相当于每秒 0.003；换算到 0.1s 缩约 0.0003
    this.shrinkCigarette(0.0003, 120);
  }

  // 吸完后的处理：暂停粒子并提示
  private async handleCigaretteFinished() {
    if (this.isSmokeFinished) {
      return;
    }
    this.isSmokeFinished = true;
    this.stopAutoBurn();
    // 记录一根完整烟
    try {
      await SmokingDataManager.recordCigarette();
      console.info('已记录整根虚拟烟');
    } catch (error) {
      const err = error as Error;
      console.error('记录整根烟失败: ' + JSON.stringify(err));
    }
    AlertDialog.show({
      title: '提示',
      message: '烟吸完了',
      primaryButton: {
        value: '知道了',
        action: () => {
          // 用户需手动点击"重置"按钮开始下一根
        }
      }
    });
  }

  // 初始化陀螺仪
  initGyroscope() {
    this.gyroListener = (data: Vector3) => {
      const now = Date.now();
      const deltaTime = this.lastUpdateTime > 0 ? (now - this.lastUpdateTime) / 1000 : 0.016;
      this.lastUpdateTime = now;
      
      const yAngularVelocity = Math.abs(data.y);
      const zAngularVelocity = Math.abs(data.z);
      const uprightThreshold = 0.3;
      this.isUpright = yAngularVelocity < uprightThreshold && zAngularVelocity < uprightThreshold;
      
      if (this.isUpright) {
        const xAngularVelocity = data.x;
        this.accumulatedTilt += xAngularVelocity * deltaTime;
        const maxTilt = 30;
        const damping = 0.95;
        this.accumulatedTilt *= damping;
        this.accumulatedTilt = Math.max(-maxTilt, Math.min(maxTilt, this.accumulatedTilt));
        
        const tilt = this.accumulatedTilt * (180 / Math.PI);
        this.tiltAngle = tilt;
        
        const baseAngle = 270;
        const angleOffset = -tilt;
        const range = 5;
        this.smokeAngleRange = [baseAngle + angleOffset - range, baseAngle + angleOffset + range];
        
        if (this.viewWidth > 0) {
          const maxOffset = this.viewWidth * 0.3;
          this.disturbanceX = (this.viewWidth / 2) + (tilt / 30) * maxOffset;
        }
      } else {
        if (Math.abs(this.tiltAngle) > 0.1) {
          this.tiltAngle = 0;
          this.accumulatedTilt = 0;
          this.smokeAngleRange = [265, 275];
          this.disturbanceX = this.viewWidth / 2;
        }
      }
    };

    try {
      sensor.on(sensor.SensorType.SENSOR_TYPE_ID_GYROSCOPE, this.gyroListener);
    } catch (error) {
      console.error('订阅陀螺仪失败: ' + JSON.stringify(error));
    }
  }

  aboutToDisappear() {
    // 取消传感器订阅
    try {
      if (this.gyroListener) {
        sensor.off(sensor.SensorType.SENSOR_TYPE_ID_GYROSCOPE, this.gyroListener);
      }
    } catch (error) {
      console.error('取消订阅陀螺仪失败: ' + JSON.stringify(error));
    }

    // 停止麦克风
    if (this.audioCapturer) {
      this.isCapturing = false;
      try {
        this.audioCapturer.stop();
        this.audioCapturer.release();
      } catch (error) {
        console.error('停止麦克风失败: ' + JSON.stringify(error));
      }
    }

    // 清除定时器
    this.stopAutoBurn();
    if (this.smokeRecoveryTimer !== undefined) {
      clearTimeout(this.smokeRecoveryTimer);
      this.smokeRecoveryTimer = undefined;
    }
  }

  // 跳转到选烟界面
  navigateToCigaretteSelection() {
    router.pushUrl({
      url: 'pages/CigaretteSelection'
    });
  }

  // 跳转到统计页面
  navigateToStatistics() {
    router.pushUrl({
      url: 'pages/Statistics'
    });
  }

  // 跳转到诱因记录页面
  navigateToTriggerLogger() {
    router.pushUrl({
      url: 'pages/TriggerLogger'
    });
  }

  // 跳转到金钱计算器
  navigateToMoneyCalculator() {
    router.pushUrl({
      url: 'pages/MoneyCalculator'
    });
  }

  // 跳转到成就页面
  navigateToAchievements() {
    router.pushUrl({
      url: 'pages/Achievements'
    });
  }

  // 重置香烟状态
  resetCigarette() {
    this.isSmorking = false
    this.isSmokeFinished = false;
    this.cigaretteLength = 1.0;
    this.smokeOpacity = 1.0; // 恢复正常烟雾透明度
    
    // 清除烟雾恢复定时器
    if (this.smokeRecoveryTimer !== undefined) {
      clearTimeout(this.smokeRecoveryTimer);
      this.smokeRecoveryTimer = undefined;
    }
    
    this.updateSmokePosition();
    this.startAutoBurn();
  }

  // 跳转到戒烟日记
  navigateToDiary() {
    router.pushUrl({
      url: 'pages/Diary'
    });
  }

  // 底部浮动菜单配置
  private getActionItems(): ActionItem[] {
    const items: ActionItem[] = [
      { label: '重置', action: (): void => { this.resetCigarette(); } } as ActionItem,
      { label: '统计', action: (): void => { this.navigateToStatistics(); } } as ActionItem,
      { label: '诱因', action: (): void => { this.navigateToTriggerLogger(); } } as ActionItem,
      { label: '计算器', action: (): void => { this.navigateToMoneyCalculator(); } } as ActionItem,
      { label: '成就', action: (): void => { this.navigateToAchievements(); } } as ActionItem,
      { label: '日记', action: (): void => { this.navigateToDiary(); } } as ActionItem,
    ];
    return items;
  }

  // 切换浮动菜单展开/收起
  toggleActionMenu(): void {
    const target = this.actionProgress > 0 ? 0 : 1;
    this.isAnimatingActions = true;
    animateTo({
      duration: 600,
      curve: Curve.EaseOut
    }, () => {
      this.actionProgress = target;
      // 旋转动画与移动同步
      this.bigSpin += 360;
      this.miniSpin += 720; // 小按钮转两圈
    });
    // 动画结束后复位状态，便于再次触发
    setTimeout(() => {
      this.isAnimatingActions = false;
    }, 620);
  }

  // 渲染单个小按钮
  @Builder
  renderMiniButton(angleDeg: number, label: string, onClick: () => void): void {
    Button() {
      Text(label)
        .fontSize(12)
        .fontColor('#333')
    }
      .width(48)
      .height(48)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 4
      })
      .rotate({
        angle: this.miniSpin,
        centerX: '50%',
        centerY: '50%'
      })
      .translate({
        x: -this.actionDistance * this.actionProgress * Math.cos(angleDeg * Math.PI / 180),
        y: -this.actionDistance * this.actionProgress * Math.sin(angleDeg * Math.PI / 180)
      })
      .opacity(this.actionProgress)
      .margin({ bottom: 12 })
      .onClick(() => onClick())
  }

  // 渲染浮动菜单
  @Builder
  renderFloatingMenu(): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 小按钮
      ForEach(this.actionAngles, (angle: number, index?: number): void => {
        this.renderMiniButton(
          angle,
          this.getActionItems()[index ?? 0].label,
          this.getActionItems()[index ?? 0].action
        );
      });

      // 大按钮
      Button() {
        Image($r('sys.media.ohos_ic_public_add'))
          .width(28)
          .height(28)
          .fillColor('#FFFFFF')
      }
        .width(72)
        .height(72)
        .backgroundColor('#4CAF50')
        .borderRadius(36)
        .shadow({
          radius: 16,
          color: 'rgba(0, 0, 0, 0.2)',
          offsetX: 0,
          offsetY: 6
        })
        .rotate({
          angle: this.bigSpin,
          centerX: '50%',
          centerY: '50%'
        })
        .onClick(() => this.toggleActionMenu())
    }
      .width('100%')
      .height('100%')
      .padding({ right: 24, bottom: 32 })
      .expandSafeArea()
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .expandSafeArea()
        .backgroundColor('#F5F5F5')

      // 粒子烟雾效果层：发射器固定原点，外层 Stack 平移到烟头，避免重置
      Stack(){
          Particle({
            particles: [
              {
                emitter: {
                  particle: {
                    type: ParticleType.POINT,
                    config: { radius: 1 },
                    count: -1,
                    lifetime: 120000,
                    lifetimeRange: 50000
                  },
                  emitRate: this.isSmokeFinished ? 0 : 100, // 吸完后暂停粒子
                  position: [this.smokePositionX - 30 , 2000], // 固定发射点，避免因位置变化重置
                  shape: ParticleEmitterShape.CIRCLE,
                  size: [60, 60]
                },
                color: { range: ['#666666', '#888888'] },
                opacity: {
                  range: [0.3, 0.5],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      { from: 0.4, to: 0.5, startMillis: 0, endMillis: 4000, curve: Curve.EaseOut },
                      { from: 0.5, to: 0.3, startMillis: 4000, endMillis: 8000, curve: Curve.Linear },
                      { from: 0.3, to: 0.1, startMillis: 8000, endMillis: 12000, curve: Curve.EaseIn },
                      { from: 0.1, to: 0.0, startMillis: 12000, endMillis: 16000, curve: Curve.EaseIn }
                    ]
                  }
                },
                scale: {
                  range: [0.6, 1.0],
                  updater: {
                    type: ParticleUpdater.CURVE,
                    config: [
                      { from: 0.6, to: 2.0, startMillis: 0, endMillis: 5000, curve: Curve.EaseOut },
                      { from: 2.0, to: 2.8, startMillis: 5000, endMillis: 8000, curve: Curve.EaseOut },
                      { from: 2.8, to: 2.0, startMillis: 8000, endMillis: 12000, curve: Curve.EaseIn }
                    ]
                  }
                },
                acceleration: {
                  speed: { range: [0.2, 1.0], updater: { type: ParticleUpdater.RANDOM, config: [0.1, 1.5] } },
                  angle: { range: this.smokeAngleRange }
                },
                spin: { range: [-1.5, 1.5], updater: { type: ParticleUpdater.RANDOM, config: [-2.0, 2.0] } },
                velocity: { speed: [80, 150], angle: this.smokeAngleRange }
              }
            ]
          })
            .width("100%")
            .height(2000)
            .backgroundColor('#F5F5F5')
            .align(Alignment.TopStart)
            .clip(false)
            .expandSafeArea()
        }
      .width('100%')
      .height('100%')
      .align(Alignment.TopStart)
      .clip(false)
      .translate({ x: 0, y: this.smokePositionY -2000 })
      .opacity(this.smokeOpacity) // 通过透明度控制烟雾可见度，避免改emitRate导致粒子系统重置

      // 主要内容层：三部分香烟的组合显示
      Column() {
        // 使用 Stack 来实现烟头和烟中间的重叠与裁剪
        Stack({ alignContent: Alignment.Top }) {
          // 烟中间（middle）- 图片向上偏移，容器从烟头位置开始显示
          Column() {
            Image($r('app.media.smoke_middle'))
              .width(60)
              .height(this.getCigaretteMetrics().headHeight) // 烟中间图片高度
              .objectFit(ImageFit.Fill)
              .translate({
                x: 0,
                // 向上偏移，使得容器顶部正好对应烟中间图片被烟头遮挡的位置
                y: -this.getCigaretteMetrics().headHeight * (1 - this.cigaretteLength)
              })
          }
          .width(60)
          // 容器高度：只显示烟头以下的部分
          .height(this.getCigaretteMetrics().headHeight * this.cigaretteLength)
          .clip(true) // 裁剪超出容器的部分（即烟中间上部）
          .translate({
            x: 0,
            // 容器位置跟随烟头下移
            y: this.getCigaretteMetrics().headHeight * (1 - this.cigaretteLength)
          })
          .zIndex(1)
          
          // 烟头（head）- 向下移动
          Image($r('app.media.smoke_head'))
            .width(60)
            .objectFit(ImageFit.Fill)
            .translate({
              x: 0,
              y: this.getCigaretteMetrics().headHeight * (1 - this.cigaretteLength) - 50
            })
            .zIndex(2) // 烟头在烟中间上面
        }
        .width(60)
        .height(this.getCigaretteMetrics().headHeight)
        
        // 烟蒂（tail）- 固定在底部
        Image($r('app.media.smoke_tail'))
          .width(60)
          .objectFit(ImageFit.Fill)
          .expandSafeArea()
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.End)
      .expandSafeArea()
      .clip(true)

      // 浮动的圆形菜单
      this.renderFloatingMenu();

      // 调试用：手动模拟吸烟按钮（不遮挡主要内容，左上角）
      Button('模拟吸一口')
        .width(110)
        .height(40)
        .fontSize(12)
        .backgroundColor('#EEEEEE')
        .fontColor('#333333')
        .borderRadius(8)
        .margin({ left: 12, top: 12 })
        .align(Alignment.TopStart)
        .onClick(() => this.simulateSmoking())
        .translate({ x: -150, y: 0})
    }
    .expandSafeArea()
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.viewWidth = newValue.width as number;
      this.viewHeight = newValue.height as number;
      this.updateSmokePosition();
    })
  }





  async requestMicrophonePermission(): Promise<boolean> {
    try {
      console.info('aaa-- BlowCandlesGame', '开始请求麦克风权限');
      // 获取context
      const context = getContext(this) as common.UIAbilityContext;
      if (!context) {
        console.warn('aaa-- BlowCandlesGame', '无法获取context');
        return false;
      }
      console.info('aaa-- BlowCandlesGame', '成功获取context');

      // 检查权限状态
      const atManager = abilityAccessCtrl.createAtManager();
      const permission: Permissions = 'ohos.permission.MICROPHONE';

      // 检查权限状态
      let grantStatus: abilityAccessCtrl.GrantStatus;
      try {
        grantStatus = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, permission);
        console.info(`aaa-- BlowCandlesGame 权限检查结果, grantStatus=${grantStatus}`);
      } catch (checkError) {
        console.warn('aaa-- BlowCandlesGame', '权限检查异常，尝试请求权限:', checkError);
        grantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
      }

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info('aaa-- BlowCandlesGame', '麦克风权限已授予，返回true');
        return true;
      }

      // 请求权限
      console.info('aaa-- BlowCandlesGame', '开始请求麦克风权限弹框');
      const requestResult = await atManager.requestPermissionsFromUser(context, [permission]);
      console.info('aaa-- BlowCandlesGame', '权限请求完成，结果:', JSON.stringify(requestResult));

      if (requestResult.authResults && requestResult.authResults.length > 0) {
        const resultStatus = requestResult.authResults[0];
        console.info(`aaa-- BlowCandlesGame 权限请求结果状态: ${resultStatus}`);
        if (resultStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          console.info('aaa-- BlowCandlesGame', '麦克风权限已授予，返回true');
          return true;
        } else {
          console.warn('aaa-- BlowCandlesGame', '麦克风权限被拒绝，返回false');
          return false;
        }
      }
      console.warn('aaa-- BlowCandlesGame', '权限请求结果异常，返回false');
      return false;
    } catch (err) {
      console.error('aaa-- BlowCandlesGame', '请求麦克风权限失败:', err);
      return false;
    }
  }




  /**
   * 开始挑战
   */
  async startGame() {

    console.info('aaa-- BlowCandlesGame', '开始游戏，准备请求权限');
    // 先请求麦克风权限
    const hasPermission = await this.requestMicrophonePermission();
    console.info(`aaa-- BlowCandlesGame 权限请求结果: hasPermission=${hasPermission}`);

    if (!hasPermission) {
      // 权限被拒绝，仍然可以继续游戏（使用模拟数据）
      console.warn('aaa-- BlowCandlesGame', '麦克风权限未授予，将使用模拟数据');
    }


    console.info('aaa-- BlowCandlesGame', '开始监听麦克风');
    // 初始化麦克风管理器（传入context）
    const context = getContext(this) as common.UIAbilityContext;
    if (context) {
      await this.microphoneManager.init(context);
      console.info('aaa-- BlowCandlesGame', '麦克风管理器已初始化');
    }

    // 开始监听麦克风
    await this.microphoneManager.startListening((volume: number) => {
        this.handleMicrophoneData(volume);
    });

    // 检查是否使用模拟数据
    const isUsingReal = this.microphoneManager.isUsingRealMicrophone();
    console.info(`aaa-- BlowCandlesGame 是否使用真实麦克风: ${isUsingReal}`);
    if (!isUsingReal) {
      console.info('aaa-- BlowCandlesGame', '显示模拟数据警告弹框');
      // this.showMockWarning = true;
    } else {
      console.info('aaa-- BlowCandlesGame', '使用真实麦克风，不显示模拟数据警告');
      console.info('bbb-- BlowCandlesGame', '注意：当前使用文件大小变化估算音量，可能不够准确反映实际音量大小');
      console.info('bbb-- BlowCandlesGame', '如果检测到的音量与实际声音大小无关，这是正常的，因为文件大小变化主要反映数据写入速度');
    }

    // 定期检查吹气
    // this.blowTimer = setInterval(() => {
    //   if (this.isPlaying) {
    //     this.checkBlow();
    //   }
    // }, 200);


    this.checkTimer = setInterval(() => {
        this.checkFUNC();
    }, 200);
  }


  async checkFUNC() {

  }

  /**
   * 处理麦克风数据
   */
  handleMicrophoneData(volume: number) {
    // 直接使用原始音量，不进行基线校准
    //this.volume = volume;
    console.info(`LIUJIAN bbb-- BlowCandlesGame 收到音量: ${volume.toFixed(3)}`);

    if (this.isSmorking) {
      return
    }

    if (volume > 0.1) {
      this.isSmorking = true
      this.simulateSmoking()
    }
  }


  /**
   * 停止挑战
   */
  async stopGame() {
    await this.microphoneManager.stopListening();

    if (this.checkTimer !== -1) {
      clearInterval(this.checkTimer);
      this.checkTimer = -1;
    }
  }
}
