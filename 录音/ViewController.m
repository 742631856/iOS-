//
//  ViewController.m
//  录音
//
//  Created by fanshengli on 15/8/6.
//  Copyright (c) 2015年 mao. All rights reserved.
//
//  录音的主要界面

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RecorderButton.h"
#import "amrFileCodec.h"
#import "AFN/AFNetworking/AFNetworking.h"
#import <AudioToolbox/AudioToolbox.h>

#define kRecordAudioFile @"myRecord.caf"


@interface ViewController () <UIGestureRecognizerDelegate, AVAudioRecorderDelegate, RecorderButtonDelegate, AVAudioPlayerDelegate>
{
    NSString *uuid;
    NSURL *wavURL;
    NSString *amrFile;
}
@property (weak, nonatomic) IBOutlet RecorderButton *btn;

@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//音频播放器，用于播放录音文件

@end

@implementation ViewController

- (IBAction)playId:(id)sender {
    AudioServicesPlayAlertSound(1311);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _btn.delegate = self;
    [self test1];
    [self setAudioSession];
}

//http上传音频文件
- (IBAction)sendFile:(id)sender
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *params = @{
         @"action_type":@"dev_w_voice",
         @"DeviceId":@"10222222222222",
         @"FLoginName":@"13538145702"
    };
    
    NSString *file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    file = [file stringByAppendingPathComponent:@"123.amr"];
    NSData *data = [NSData dataWithContentsOfFile:file];    //文件数据
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    //1、这个要放在 添加请求参数之前
    [requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    //2、添加参数，  （1、2、）的顺序不能颠倒
    NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:@"POST"
            URLString:@"http://gps.mao.com/OpenApi/AppHandler.ashx"
            parameters:params
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                //name 是表单中的字段名
        [formData appendPartWithFileData:data name:@"File1" fileName:@"123.amr" mimeType:@"audio/AMR"];//name 是表单中的字段名
    } error:nil];
    
    //初始化操作
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [[NSString alloc] initWithData:(NSData *)responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"成功, %@", response);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"失败, \n%@", error);
    }];
    //添加到队列中
    [manager.operationQueue addOperation:operation];
}

- (IBAction)play:(id)sender
{
    [self.audioPlayer play];
}

- (void)touchBegan
{
    [self.audioRecorder record];
}
- (void)touchEnded
{
    [_audioRecorder stop];
}
- (void)touchCancelled
{
    [_audioRecorder stop];
}

- (void)test1
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"0F0612122404.amr" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSData *wav = DecodeAMRToWAVE(data);
    
    NSString *file = @"/Users/fanshengli/Desktop/tes.wav";
    BOOL scucced = [[NSFileManager defaultManager] createFileAtPath:file contents:wav attributes:nil];
    if (scucced) {
        NSLog(@"111");
    }
}

- (void)newUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStrRef= CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    uuid = [NSString stringWithString:(__bridge NSString *)uuidStrRef];
    CFRelease(uuidStrRef);
}


/**
 *  设置音频会话
 */
- (void)setAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    //从话筒(外音，扬声器)处播放，而不是从听筒处播放，听筒播放的声音非常小
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    //从话筒(外音，扬声器)处播放，这个方法被上面的代替了 在ios6以后
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
//                             sizeof (audioRouteOverride),
//                             &audioRouteOverride);  //设置后播放声音会变大
}

/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
- (NSURL *)getRecordSavePathURL
{
    [self newUUID];
    
    NSString * wavFile = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];//缓存路径
    wavFile = [wavFile stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf", uuid]];
    wavURL = [NSURL fileURLWithPath:wavFile];
    
    return wavURL;
}

/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
- (NSDictionary *)getAudioSetting
{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    //设置录音格式, kAudioFormatAMR会在创建AVAudioRecorder报错，IOS不支持
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(NO) forKey:AVLinearPCMIsFloatKey];//这个设置非常重要, 不然转换的是杂音, 或者是声音很小
    [dicM setObject:@(NO) forKey:AVLinearPCMIsNonInterleaved];
    [dicM setObject:@(NO) forKey:AVLinearPCMIsBigEndianKey];
    //....其他设置等
    return dicM;
}

/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
- (AVAudioRecorder *)audioRecorder
{
    //创建录音文件保存路径
    [self getRecordSavePathURL];
    //创建录音格式设置
    NSDictionary *setting = [self getAudioSetting];
    //创建录音机
    NSError *error = nil;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:wavURL settings:setting error:&error];
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;//如果要监控声波则必须设置为YES
    if (error) {
        NSLog(@"创建录音机对象时发生错误：%@",error.localizedDescription);
        return nil;
    }
    
    return _audioRecorder;
}

/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (!flag) {
        return;
    }
    
    NSData *wav = [NSData dataWithContentsOfURL:recorder.url];
    
    amrFile = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    amrFile = [amrFile stringByAppendingPathComponent:@"123.amr"];
    
    NSLog(@"录音完成!, %lu, \n%@\n%@", (unsigned long)wav.length, recorder.url.relativePath, amrFile);
    
    //        int scucced =  EncodeWAVEFileToAMRFile([recorder.url.relativePath cStringUsingEncoding:NSASCIIStringEncoding], [file cStringUsingEncoding:NSASCIIStringEncoding], 1, 16);
    
    NSData *data = [NSData dataWithContentsOfURL:recorder.url];
    NSData *amr = EncodeWAVEToAMR(data, 1, 16);//录音转换成amr格式
    if ([[NSFileManager defaultManager] fileExistsAtPath:amrFile] &&
        [[NSFileManager defaultManager] removeItemAtPath:amrFile error:nil]) {
        NSLog(@"删除成功了");
    };
    BOOL scucced = [[NSFileManager defaultManager] createFileAtPath:amrFile contents:amr attributes:nil];
    
    if (scucced) {
        NSLog(@"转换完成");
    }
}

/**
 *  创建播放器
 *
 *  @return 播放器
 */
- (AVAudioPlayer *)audioPlayer
{
//        [self wavPlayer];
    [self amrPlayer];
    _audioPlayer.numberOfLoops = 0;
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    _audioPlayer.volume = 1.0;
    
    return _audioPlayer;
}

- (void)wavPlayer
{
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:wavURL error:nil];
    if (error) {
        NSLog(@"创建播放器过程中发生错误：%@", error.localizedDescription);
        return;
    }
}

- (void)amrPlayer
{
    NSString *file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    file = [file stringByAppendingPathComponent:@"123.amr"];
    NSData *data = [NSData dataWithContentsOfFile:file];
    NSData *wav = DecodeAMRToWAVE(data);
    NSLog(@"wav : %lu, data : %lu, %@", (unsigned long)wav.length, (unsigned long)data.length, file);
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithData:wav error:nil];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"播放完成");
    _audioPlayer = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"解码出错");
}

@end
