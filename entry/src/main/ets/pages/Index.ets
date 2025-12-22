import sensor from '@ohos.sensor';
import { router } from '@kit.ArkUI';
import audio from '@ohos.multimedia.audio';
import { SmokingDataManager } from '../utils/SmokingDataManager';

interface Vector3 {
  x: number;
  y: number;
  z: number;
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
  @State actionProgress: number = 0; // 小按钮展开进度 0-1
  @State bigSpin: number = 0; // 大按钮旋转角度
  @State miniSpin: number = 0; // 小按钮旋转角度
  @State isAnimatingActions: boolean = false;
  private actionAngles: number[] = [0, 18, 36, 54, 72, 90];
  private actionDistance: number = 200;
  
  private gyroListener?: (data: Vector3) => void;
  private accumulatedTilt: number = 0;
  private lastUpdateTime: number = 0;
  private audioCapturer?: audio.AudioCapturer;
  private isCapturing: boolean = false;
  private lastSmokeTime: number = 0;

  aboutToAppear() {
    this.initMicrophone();
    this.initGyroscope();
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
      console.error('初始化麦克风失败: ' + err.message);
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
          console.error('读取音频失败: ' + err.message);
          setTimeout(checkAudio, 100);
        }
      };

      checkAudio();
    } catch (error) {
      const err = error as Error;
      console.error('获取缓冲区大小失败: ' + err.message);
    }
  }

  // 模拟吸烟：快速缩短香烟
  async simulateSmoking() {
    // 每次吸烟缩短5%
    this.cigaretteLength = Math.max(0, this.cigaretteLength - 0.05);
    
    // 记录吸烟数据到持久化存储
    try {
      await SmokingDataManager.recordPuff();
      const todayData = await SmokingDataManager.getTodayData();
      console.info(`检测到吸烟，当前香烟长度: ${(this.cigaretteLength * 100).toFixed(0)}%, 今日口数: ${todayData.puffs}, 今日烟数: ${todayData.cigarettes}`);
    } catch (error) {
      console.error('记录吸烟数据失败: ' + JSON.stringify(error));
    }
    
    // 如果香烟吸完了，重置
    if (this.cigaretteLength <= 0) {
      setTimeout(() => {
        this.cigaretteLength = 1.0;
      }, 2000);
    }
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

  // 跳转到戒烟日记
  navigateToDiary() {
    router.pushUrl({
      url: 'pages/Diary'
    });
  }

  // 底部浮动菜单配置
  private getActionItems(): ActionItem[] {
    const items: ActionItem[] = [
      { label: '选烟', action: (): void => { this.navigateToCigaretteSelection(); } } as ActionItem,
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
    Stack() {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .expandSafeArea()
        .backgroundColor('#F5F5F5')

      // 粒子烟雾效果层（浅灰色背景，烟雾颜色调整为深灰色）
      Particle({
        particles: [
          {
            emitter: {
              particle: {
                type: ParticleType.POINT,
                config: {
                  radius: 1
                },
                count: -1,
                lifetime: 12000,
                lifetimeRange: 5000
              },
              emitRate: 50,
              position: [this.viewWidth / 2, this.smokePositionY], // 从烟头位置发射
              shape: ParticleEmitterShape.CIRCLE,
              size: [40, 40]
            },
            color: {
              range: ['#666666', '#888888'] // 深灰色烟雾，在浅色背景上可见
            },
            opacity: {
              range: [0.3, 0.5],
              updater: {
                type: ParticleUpdater.CURVE,
                config: [
                  {
                    from: 0.4,
                    to: 0.5,
                    startMillis: 0,
                    endMillis: 4000,
                    curve: Curve.EaseOut
                  },
                  {
                    from: 0.5,
                    to: 0.3,
                    startMillis: 4000,
                    endMillis: 8000,
                    curve: Curve.Linear
                  },
                  {
                    from: 0.3,
                    to: 0.1,
                    startMillis: 8000,
                    endMillis: 12000,
                    curve: Curve.EaseIn
                  },
                  {
                    from: 0.1,
                    to: 0.0,
                    startMillis: 12000,
                    endMillis: 16000,
                    curve: Curve.EaseIn
                  }
                ]
              }
            },
            scale: {
              range: [0.6, 1.0],
              updater: {
                type: ParticleUpdater.CURVE,
                config: [
                  {
                    from: 0.6,
                    to: 2.0,
                    startMillis: 0,
                    endMillis: 5000,
                    curve: Curve.EaseOut
                  },
                  {
                    from: 2.0,
                    to: 2.8,
                    startMillis: 5000,
                    endMillis: 8000,
                    curve: Curve.EaseOut
                  },
                  {
                    from: 2.8,
                    to: 2.0,
                    startMillis: 8000,
                    endMillis: 12000,
                    curve: Curve.EaseIn
                  }
                ]
              }
            },
            acceleration: {
              speed: {
                range: [0.2, 1.0],
                updater: {
                  type: ParticleUpdater.RANDOM,
                  config: [0.1, 1.5]
                }
              },
              angle: {
                range: this.smokeAngleRange
              }
            },
            spin: {
              range: [-1.5, 1.5],
              updater: {
                type: ParticleUpdater.RANDOM,
                config: [-2.0, 2.0]
              }
            },
            velocity: {
              speed: [80, 150],
              angle: this.smokeAngleRange
            }
          }
        ]
      })
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5') // 粒子效果层也使用浅灰色背景
        .disturbanceFields([{
          strength: 50,
          shape: DisturbanceFieldShape.CIRCLE,
          size: { width: this.viewWidth, height: this.viewHeight },
          position: { 
            x: this.viewWidth > 0 ? this.disturbanceX : this.viewWidth / 2, 
            y: this.viewHeight / 2 
          }
        }])
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.viewWidth = newValue.width as number;
          this.viewHeight = newValue.height as number;
          // 计算烟头位置：假设烟图片在屏幕中央，烟头在顶部
          // 根据香烟长度调整烟头位置
          const cigaretteImageHeight = this.viewHeight * 0.6; // 假设烟图片高度为屏幕的60%
          const cigaretteTop = (this.viewHeight - cigaretteImageHeight) / 2;
          this.smokePositionY = cigaretteTop + (cigaretteImageHeight * (1 - this.cigaretteLength));
          
          if (this.disturbanceX === 0 && this.viewWidth > 0) {
            this.disturbanceX = this.viewWidth / 2;
          }
        })
        .expandSafeArea()

      // 主要内容层
      Column() {
        // 烟图片容器
        Stack() {
          // 完整的烟图片（作为背景）
          Image($r('app.media.smoke'))
            .width(80)
            .height(this.viewHeight * 0.6)
            .objectFit(ImageFit.Contain)
            .opacity(0.3) // 半透明显示完整烟
          
          // 根据长度显示的烟图片
          Image($r('app.media.smoke'))
            .width(80)
            .height(this.viewHeight * 0.6 * this.cigaretteLength)
            .objectFit(ImageFit.Contain)
            .align(Alignment.Top)
        }
        .width(80)
        .height(this.viewHeight * 0.6)
        .margin({ top: (this.viewHeight - this.viewHeight * 0.6) / 2 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .expandSafeArea()

      // 浮动的圆形菜单
      this.renderFloatingMenu();
    }
    .expandSafeArea()
    .width('100%')
    .height('100%')
  }
}
