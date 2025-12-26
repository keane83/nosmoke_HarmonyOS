
import { sensor } from '@kit.SensorServiceKit';
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';


export class MicrophoneManager {

  private static instance: MicrophoneManager;
  private listeners: Array<(volume: number) => void> = [];
  private isListening: boolean = false;
  private mockTimer: number = -1;
  private useRealMicrophone: boolean = false;
  private audioRecorder: media.AVRecorder | null = null;
  private recordFile: fileIo.File | null = null;
  private volumeCheckTimer: number = -1;
  private context: common.UIAbilityContext | null = null;
  private recordFilePath: string = '';

  private constructor() {
  }

  static getInstance(): MicrophoneManager {
    if (!MicrophoneManager.instance) {
      MicrophoneManager.instance = new MicrophoneManager();
    }
    return MicrophoneManager.instance;
  }

  /**
   * 初始化传感器
   */
  async init(context?: common.UIAbilityContext): Promise<boolean> {
    if (context) {
      this.context = context;
    }
    return true;
  }

  /**
   * 开始监听麦克风
   * @param callback 回调函数
   */
  async startListening(callback: (volume: number) => void): Promise<void> {
    console.info('aaa-- MicrophoneManager', 'startListening被调用');
    this.listeners.push(callback);

    if (this.isListening) {
      console.info('aaa-- MicrophoneManager', '已经在监听中，直接返回');
      return;
    }

    this.isListening = true;
    console.info('aaa-- MicrophoneManager', '开始初始化真实麦克风');

    // 先尝试使用真实麦克风
    try {
      await this.initRealMicrophone();
      console.info('aaa-- MicrophoneManager', '真实麦克风初始化成功');
    } catch (err) {
      console.error('aaa-- MicrophoneManager', '真实麦克风初始化失败，使用模拟数据:', err);
      this.useRealMicrophone = false;
      this.startMockSensor();
    }
  }

  /**
   * 初始化真实麦克风
   * 参考hongloumeng项目，使用media.AVRecorder来获取麦克风音量
   */
  private async initRealMicrophone(): Promise<void> {
    console.info('aaa-- MicrophoneManager', 'initRealMicrophone被调用，使用AVRecorder方式');

    if (!this.context) {
      console.warn('aaa-- MicrophoneManager', 'context未设置，无法使用真实麦克风');
      throw new Error('Context not available');
    }

    try {
      // 创建临时录音文件路径
      const filesDir = this.context.filesDir;
      const recordDir = `${filesDir}/microphone_temp`;

      // 确保目录存在
      try {
        fileIo.mkdirSync(recordDir);
      } catch (mkError) {
        // 目录可能已存在
      }

      const fileName = `temp_recording_${Date.now()}.m4a`;
      this.recordFilePath = `${recordDir}/${fileName}`;
      console.info(`aaa-- MicrophoneManager 录音文件路径=${this.recordFilePath}`);

      // 创建文件句柄
      const file = fileIo.openSync(this.recordFilePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      this.recordFile = file;
      console.info(`aaa-- MicrophoneManager 文件已打开, fd=${file.fd}`);

      // 创建AVRecorder实例
      const avRecorder = await media.createAVRecorder();
      this.audioRecorder = avRecorder;
      console.info('aaa-- MicrophoneManager AVRecorder实例创建成功');

      // 配置录音参数
      const config: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        url: `fd://${file.fd}`,
        profile: {
          audioBitrate: 100000,
          audioChannels: 1,
          audioSampleRate: 44100,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4A
        }
      };

      console.info(`aaa-- MicrophoneManager 准备配置AVRecorder, url=fd://${file.fd}`);

      // prepare AVRecorder
      await this.audioRecorder.prepare(config);
      console.info('aaa-- MicrophoneManager AVRecorder准备完成');

      // 开始录音
      await this.audioRecorder.start();
      console.info('aaa-- MicrophoneManager 录音已/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon\n' +
        '> hvigor UP-TO-DATE :entry:default@PreBuild...  \n' +
        '> hvigor Finished :entry:default@CreateModuleInfo... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@GenerateMetadata...  \n' +
        '> hvigor Finished :entry:default@ConfigureCmake... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@MergeProfile...  \n' +
        '> hvigor UP-TO-DATE :entry:default@CreateBuildProfile...  \n' +
        '> hvigor Finished :entry:default@PreCheckSyscap... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@GeneratePkgContextInfo...  \n' +
        '> hvigor Finished :entry:default@ProcessIntegratedHsp... after 1 ms \n' +
        '> hvigor Finished :entry:default@BuildNativeWithCmake... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@MakePackInfo...  \n' +
        '> hvigor Finished :entry:default@SyscapTransform... after 2 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@ProcessProfile...  \n' +
        '> hvigor UP-TO-DATE :entry:default@ProcessRouterMap...  \n' +
        '> hvigor UP-TO-DATE :entry:default@ProcessShareConfig...  \n' +
        '> hvigor Finished :entry:default@ProcessStartupConfig... after 1 ms \n' +
        '> hvigor Finished :entry:default@BuildNativeWithNinja... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@ProcessResource...  \n' +
        '> hvigor UP-TO-DATE :entry:default@GenerateLoaderJson...  \n' +
        '> hvigor UP-TO-DATE :entry:default@ProcessLibs...  \n' +
        '> hvigor UP-TO-DATE :entry:default@CompileResource...  \n' +
        '> hvigor UP-TO-DATE :entry:default@DoNativeStrip...  \n' +
        '> hvigor Finished :entry:default@BuildJS... after 1 ms \n' +
        '> hvigor UP-TO-DATE :entry:default@CacheNativeLibs...  \n' +
        '> hvigor ERROR: Failed :entry:default@CompileArkTS... \n' +
        '> hvigor WARN: \n' +
        '1 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:14:12\n' +
        ' \'pushUrl\' has been deprecated.\n' +
        '\n' +
        '2 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:31:12\n' +
        ' \'pushUrl\' has been deprecated.\n' +
        '\n' +
        '3 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:44:12\n' +
        ' \'pushUrl\' has been deprecated.\n' +
        '\n' +
        '4 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:57:12\n' +
        ' \'pushUrl\' has been deprecated.\n' +
        '\n' +
        '5 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:70:12\n' +
        ' \'replaceUrl\' has been deprecated.\n' +
        '\n' +
        '6 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/utils/Router.ets:83:12\n' +
        ' \'back\' has been deprecated.\n' +
        '\n' +
        '7 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/GameDetail.ets:22:27\n' +
        ' \'getParams\' has been deprecated.\n' +
        '\n' +
        '8 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/GameDetail.ets:784:14\n' +
        ' \'pushUrl\' has been deprecated.\n' +
        '\n' +
        '9 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:82:23\n' +
        ' \'getContext\' has been deprecated.\n' +
        '\n' +
        '10 WARN: ArkTS:WARN File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:155:21\n' +
        ' \'getContext\' has been deprecated.\n' +
        '\n' +
        '> hvigor ERROR: ArkTS Compiler Error\n' +
        '1 ERROR: 10505001 ArkTS Compiler Error\n' +
        'Error Message: Property \'buildBlowSuccessDialog\' does not exist on type \'BlowCandlesGame\'. At File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:541:14\n' +
        '\n' +
        '\n' +
        '2 ERROR: 10505001 ArkTS Compiler Error\n' +
        'Error Message: Property \'buildCompleteDialog\' does not exist on type \'BlowCandlesGame\'. At File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:545:14\n' +
        '\n' +
        '\n' +
        '3 ERROR: 10905204 ArkTS Compiler Error\n' +
        'Error Message: \'this.buildBlowSuccessDialog()\' does not meet UI component syntax. At File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:541:9\n' +
        '\n' +
        '\n' +
        '4 ERROR: 10905204 ArkTS Compiler Error\n' +
        'Error Message: \'this.buildCompleteDialog()\' does not meet UI component syntax. At File: /Users/lanmin/Documents/PersonalItem/MySenseDiscover/SenseDiscover/SenseDiscover/entry/src/main/ets/pages/games/BlowCandlesGame.ets:545:9\n' +
        '\n' +
        '\n' +
        'COMPILE RESULT:FAIL {ERROR:5 WARN:10}\n' +
        '\n' +
        '* Try:\n' +
        '> Run with --stacktrace option to get the stack trace.\n' +
        '> Run with --debug option to get more log output.\n' +
        '\n' +
        '> hvigor ERROR: BUILD FAILED in 1 s 413 ms \n' +
        '\n' +
        'Process finished with exit code -1\n开始，使用真实麦克风');
      console.info('bbb-- MicrophoneManager 使用getAudioCapturerMaxAmplitude()获取真实音量');
      this.useRealMicrophone = true;

      // 定期获取音量（使用getAudioCapturerMaxAmplitude()获取真实振幅）
      let volumeHistory: number[] = []; // 音量历史记录，用于平滑处理
      const HISTORY_SIZE = 5; // 保留最近5次音量值
      const MAX_AMPLITUDE = 32767; // 16位音频的最大振幅值（-32768到32767）

      this.volumeCheckTimer = setInterval(async () => {
        if (this.audioRecorder && this.isListening) {
          try {
            // 使用getAudioCapturerMaxAmplitude()获取当前最大振幅值
            // 注意：该方法可能返回Promise或直接返回数字
            let maxAmplitude: number = 0;
            try {
              const amplitudeResult = this.audioRecorder.getAudioCapturerMaxAmplitude();
              // 检查是否是Promise
              if (amplitudeResult instanceof Promise) {
                maxAmplitude = await amplitudeResult;
              } else {
                maxAmplitude = amplitudeResult as number;
              }
            } catch (ampError) {
              console.warn('bbb-- MicrophoneManager', 'getAudioCapturerMaxAmplitude()调用失败:', ampError);
              throw new Error(`获取音频振幅失败: ${ampError}`);
            }

            // 确保maxAmplitude是有效的数字
            if (typeof maxAmplitude !== 'number' || isNaN(maxAmplitude)) {
              maxAmplitude = 0;
            }

            // 将振幅值归一化到0-1范围
            // 振幅值范围通常是0到32767（16位音频）
            const normalizedVolume = Math.min(maxAmplitude / MAX_AMPLITUDE, 1.0);

            // 添加到历史记录
            volumeHistory.push(normalizedVolume);
            if (volumeHistory.length > HISTORY_SIZE) {
              volumeHistory.shift();
            }

            // 使用平均值来平滑音量，减少噪声
            const avgVolume = volumeHistory.reduce((a, b) => a + b, 0) / volumeHistory.length;

            // 调整阈值：平均值超过0.1就认为是有效音量
            const finalVolume = avgVolume > 0.1 ? avgVolume : 0;

            // 输出音量调试信息
            console.info(`bbb-- MicrophoneManager 音量信息: maxAmplitude=${maxAmplitude}, normalizedVolume=${normalizedVolume.toFixed(3)}, avgVolume=${avgVolume.toFixed(3)}, finalVolume=${finalVolume.toFixed(3)}`);

            this.listeners.forEach(listener => {
              listener(finalVolume);
            });
          } catch (err) {
            console.error('aaa-- MicrophoneManager', '获取音量失败:', err);
            // 如果getAudioCapturerMaxAmplitude()不可用，回退到文件大小方法
            console.warn('bbb-- MicrophoneManager', 'getAudioCapturerMaxAmplitude()不可用，尝试使用文件大小方法');
            try {
              const stat = fileIo.statSync(this.recordFilePath);
              const currentFileSize = stat.size;
              // 简单的文件大小变化估算（作为备用方案）
              const fallbackVolume = Math.min(currentFileSize / 100000.0, 1.0);
              this.listeners.forEach(listener => {
                listener(fallbackVolume);
              });
            } catch (fallbackErr) {
              console.error('aaa-- MicrophoneManager', '备用方法也失败:', fallbackErr);
            }
          }
        }
      }, 100);

      console.info('aaa-- MicrophoneManager', '真实麦克风初始化成功');
    } catch (err) {
      console.error('aaa-- MicrophoneManager', '真实麦克风初始化失败:', err);
      // 清理资源
      if (this.audioRecorder) {
        try {
          await this.audioRecorder.release();
        } catch (releaseError) {
          // ignore
        }
        this.audioRecorder = null;
      }
      if (this.recordFile) {
        try {
          fileIo.closeSync(this.recordFile);
        } catch (closeError) {
          // ignore
        }
        this.recordFile = null;
      }
      throw new Error('麦克风初始化失败');
    }
  }

  /**
   * 启动模拟传感器
   */
  private startMockSensor(): void {
    console.info('aaa-- MicrophoneManager', 'startMockSensor被调用，使用模拟麦克风');
    // 模拟音频音量数据
    let volume = 0.1;

    this.mockTimer = setInterval(() => {
      // 模拟吹气效果
      if (Math.random() > 0.8) {
        volume = Math.random() * 0.8 + 0.2; // 0.2-1.0
      } else {
        volume = Math.max(0.1, volume * 0.9);
      }

      this.listeners.forEach(listener => {
        listener(volume);
      });
    }, 100);
  }

  /**
   * 停止监听
   */
  async stopListening(): Promise<void> {
    console.info('aaa-- MicrophoneManager', 'stopListening被调用');
    this.isListening = false;

    if (this.useRealMicrophone && this.audioRecorder) {
      try {
        console.info('aaa-- MicrophoneManager', '停止真实麦克风');
        await this.audioRecorder.stop();
        await this.audioRecorder.release();
        this.audioRecorder = null;
        console.info('aaa-- MicrophoneManager', '停止真实麦克风成功');
      } catch (err) {
        console.error('aaa-- MicrophoneManager', '停止真实麦克风失败:', err);
      }

      if (this.recordFile) {
        try {
          fileIo.closeSync(this.recordFile);
          this.recordFile = null;
        } catch (closeError) {
          // ignore
        }
      }

      // 清理录音文件
      if (this.recordFilePath) {
        try {
          fileIo.unlinkSync(this.recordFilePath);
          console.info(`aaa-- MicrophoneManager 已删除临时录音文件: ${this.recordFilePath}`);
        } catch (unlinkError) {
          // ignore
        }
        this.recordFilePath = '';
      }

      if (this.volumeCheckTimer !== -1) {
        clearInterval(this.volumeCheckTimer);
        this.volumeCheckTimer = -1;
      }
    } else {
      if (this.mockTimer !== -1) {
        clearInterval(this.mockTimer);
        this.mockTimer = -1;
      }
      console.info('aaa-- MicrophoneManager', '停止模拟麦克风');
    }

    this.listeners = [];
  }

  /**
   * 检测是否有气流（吹气）
   */
  detectBlow(volume: number, threshold: number = 0.5): boolean {
    return volume > threshold;
  }

  /**
   * 是否使用真实麦克风
   */
  isUsingRealMicrophone(): boolean {
    const result = this.useRealMicrophone;
    console.info(`aaa-- MicrophoneManager isUsingRealMicrophone返回: ${result}`);
    return result;
  }
}