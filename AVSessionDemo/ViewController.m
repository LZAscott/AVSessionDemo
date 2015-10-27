//
//  ViewController.m
//  AVSessionDemo
//
//  Created by Scott_Mr on 15/10/26.
//  Copyright © 2015年 Scott_Mr. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    double _lowPassResults;
}

@property (nonatomic, strong) NSDictionary *recordSettingDic;
@property (nonatomic, strong) NSArray *volumImages;
@property (nonatomic, copy) NSString *recordPath;
/// 录音器
@property (nonatomic, strong) AVAudioRecorder *recorder;
/// 播放器
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *timer;

@end

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *voiceImgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    //AVAudioSessionCategoryPlayAndRecord用于录音和播放
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    if (session == nil) {
        NSLog(@"Error creating session:%@",[sessionError description]);
    }else{
        [session setActive:YES error:nil];
    }
    
    // 沙盒路径
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.recordPath = [NSString stringWithFormat:@"%@/play.aac",docDir];
    
    // 录音设置
    self.recordSettingDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],AVFormatIDKey,[NSNumber numberWithInteger:1000],AVSampleRateKey,
                                            [NSNumber numberWithInteger:2],AVNumberOfChannelsKey,
                                            [NSNumber numberWithInteger:8],AVLinearPCMBitDepthKey,
                                            [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                            [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,nil];
    // 音量图片数组
    self.volumImages = [[NSArray alloc]initWithObjects:@"RecordingSignal001",
                            @"RecordingSignal002",@"RecordingSignal003",@"RecordingSignal004", @"RecordingSignal005",@"RecordingSignal006",@"RecordingSignal007",@"RecordingSignal008",   nil];
}

// 按下录音
- (IBAction)recordBtn:(UIButton *)sender {
    if ([self canRecord]) { // 如果能够录音
        NSError *error = nil;
        // 必须真机测试
        self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.recordPath] settings:self.recordSettingDic error:&error];
        if (self.recorder) {
            self.recorder.meteringEnabled = YES;
            [self.recorder prepareToRecord];
            [self.recorder record];
            
            // 开启定时器
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(recordLevel:) userInfo:nil repeats:YES];
        }else{
            int errorCode = CFSwapInt32HostToBig([error code]);
            NSLog(@"error:%@[%4.4s]",[error description],(char *)&errorCode);
        }
        
    }
}

// 松手
- (IBAction)recordBtnCancle:(UIButton *)sender {
    
    // 录音停止
    [self.recorder stop];
    
    self.recorder = nil;
    
    // 结束定时器
    [_timer invalidate];
    _timer = nil;
    
    // 图片重置
    self.voiceImgView.image = [UIImage imageNamed:[self.volumImages firstObject]];
}

// 播放按钮
- (IBAction)playBtn:(UIButton *)sender {
    NSError *playerError;
    
    // 清空上一次的播放器
    _player = nil;
    
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:_recordPath] error:&playerError];
    
    if (_player == nil) {
        NSLog(@"Error creating player:%@",[playerError description]);
    }else{
        [_player play];
    }
}


- (void)recordLevel:(NSTimer *)time
{
    //call to refresh meter values刷新平均和峰值功率,此计数是以对数刻度计量的,-160表示完全安静，0表示最大输入值
    [_recorder updateMeters];
    
    const double alpha = 0.05;
    double peakPowerForChannel = pow(10, (0.05 * [_recorder peakPowerForChannel:0]));
    _lowPassResults = alpha * peakPowerForChannel + (1.0 - alpha) * _lowPassResults;
    
    NSLog(@"Average input:%f Peak input:%f Low Pass result:%f",[_recorder averagePowerForChannel:0],[_recorder peakPowerForChannel:0],_lowPassResults);
    
    if (_lowPassResults >= 0.8) {
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:7]];
    }else if(_lowPassResults >= 0.7){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:6]];
    }else if(_lowPassResults >= 0.6){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:5]];
    }else if(_lowPassResults >= 0.5){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:4]];
    }else if(_lowPassResults >= 0.4){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:3]];
    }else if(_lowPassResults >= 0.3){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:2]];
    }else if(_lowPassResults >= 0.2){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:1]];
    }else if(_lowPassResults >= 0.1){
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:0]];
    }else{
        _voiceImgView.image = [UIImage imageNamed:[_volumImages objectAtIndex:0]];
    }
}

// 是否能录音
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted){
            if (granted == YES) {
                bCanRecord = YES;
            }else{
                bCanRecord = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"app需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancel_action = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:NULL];
                    [alert addAction:cancel_action];
                    [self presentViewController:alert animated:YES completion:NULL];
                });
            }
        }];
    }
    return bCanRecord;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
