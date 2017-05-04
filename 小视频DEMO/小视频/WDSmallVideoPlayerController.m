//
//  DSSmallVideoViewController.h
//  框架
//
//  Created by 朱辉 on 16/3/29.
//  Copyright © 2016年 朱辉. All rights reserved.

#import "WDSmallVideoPlayerController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFNetworking.h"
#import "ZipArchive.h"
#define KSCREEN_HEIGHT   ([[UIScreen mainScreen] bounds].size.height)  //屏幕高度
#define KSCREEN_WIDTH    ([[UIScreen mainScreen] bounds].size.width)   //屏幕宽度
@interface WDSmallVideoPlayerController(){

    AVPlayer      *_player;
    AVPlayerItem  *_playItem;
    
    AVPlayerLayer *_playerLayer;
    AVPlayerLayer *_fullPlayer;
    
    //是否正在播放
    BOOL _isPlaying;
}
@property (weak, nonatomic)  UIButton *saveBtn;

@end

@implementation WDSmallVideoPlayerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //初始化AV播放器
    [self initAVPalayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = CGRectMake(20, 20, 120, 40);
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor greenColor];
    [saveBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(compressVideo:) forControlEvents:UIControlEventTouchUpInside];
    saveBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.view.userInteractionEnabled = YES;
    [self.view addSubview:saveBtn];
    self.saveBtn = saveBtn;

    
    //时间差
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.saveBtn.enabled = YES;
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_player) {
        
        [_player pause];
        [_playerLayer removeFromSuperlayer];
        _player = nil;
        _playerLayer= nil;
        _playItem = nil;

    }
    
}

- (void)initAVPalayer
{
    _playItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    _player = [AVPlayer playerWithPlayerItem:_playItem];
    
    _playerLayer =[AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(KSCREEN_WIDTH - 120 , 20, 100, 100);
    _playerLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//视频填充模式
    [self.view.layer addSublayer:_playerLayer];
    
    
    [_player play];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!_isPlaying) {
        _playerLayer.frame = [UIScreen mainScreen].bounds;
    }else{
        _playerLayer.frame = CGRectMake(KSCREEN_WIDTH - 120 , 20, 100, 100);
    }
    _isPlaying = !_isPlaying;
}

-(void)playbackFinished:(NSNotification *)notification
{
    [_player seekToTime:CMTimeMake(0, 1)];
    [_player play];
}

#pragma mark 保存压缩
- (NSURL *)compressedURL
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-DD--HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    return [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",dateTime]]];
}

- (CGFloat)fileSize:(NSURL *)path
{
    return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}

// 压缩视频
- (void)compressVideo:(id)sender
{
    NSLog(@"开始压缩,压缩前大小 %f MB",[self fileSize:self.videoUrl]);
    
    self.saveBtn.enabled = NO;
    
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPreset640x480]) {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
        exportSession.outputURL = [self compressedURL];
        //优化网络
        exportSession.shouldOptimizeForNetworkUse = true;
        //转换后的格式
        exportSession.outputFileType = AVFileTypeMPEG4;
        //异步导出
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            // 如果导出的状态为完成
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                
                NSLog(@"压缩完毕,压缩后大小 %f MB",[self fileSize:[self compressedURL]]);
                [self saveVideoToALAssetsLibrary:[self compressedURL]];
                
                
                [self saveVideoToLocalTMPWithURL:[self compressedURL]];
            }else{
                
                NSLog(@"当前压缩进度:%f",exportSession.progress);
                NSString *lab = [NSString stringWithFormat:@"%f",exportSession.progress];
                
                    [[[UIAlertView alloc] initWithTitle:@"当前压缩进度" message:lab delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                
            }

            self.saveBtn.enabled = YES;
        }];
    }
}

//保存到沙河
-(void)saveVideoToLocalTMPWithURL:(NSURL *)videoUrl
{
    NSString *path = NSTemporaryDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[path stringByAppendingPathComponent:@"videoFolder"]]) {
        
        [fm removeItemAtPath:path error:nil];
    }
    
    //文件夹
    NSString *newFolder = [path stringByAppendingPathComponent:@"videoFolder"];
    [fm createDirectoryAtPath:newFolder withIntermediateDirectories:YES attributes:nil error:nil];
    //文件名
    NSString *newVideoPath = [newFolder stringByAppendingPathComponent:@"video.mp4"];
    NSData *data = [NSData dataWithContentsOfURL:videoUrl];
    [fm createFileAtPath:newVideoPath contents:data attributes:nil];
    
    BOOL isSucees= [fm fileExistsAtPath:newVideoPath];
    
    if (isSucees) {
        
        //1.1 创建压缩文件夹 .zip
        ZipArchive *za = [[ZipArchive alloc] init];
        NSString * realPath = [path stringByAppendingPathComponent:@"videoZipFolder.zip"];
        [za CreateZipFile2:realPath];
        
        
        //1.2 向压缩文件中添加文件
        NSString *videoZioPath = [path stringByAppendingPathComponent:@"videoFolder"];
        [za addFileToZip:videoZioPath newname:@"smallVideo"];
        
        BOOL success = [za CloseZipFile2];
    
        if (success) {
            
            NSString *fullPath = [path stringByAppendingPathComponent:@"videoZipFolder.zip"];
            
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:fullPath];
            NSLog(@"小视频保存成功");

            
            [self postDataFromHttpWithData:imageData];
        }else{
        
            NSLog(@"压缩小视频时出错");
        }
        

 
    }else{
    
        NSLog(@"视频写入失败");
    }

}

//保存视频到相册
- (void)saveVideoToALAssetsLibrary:(NSURL *)outputFileURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        NSLog(@"保存视频失败:%@",error);
                                    } else {
                                        NSLog(@"保存视频到相册成功");
                                    }
                                }];
}


-(void)postDataFromHttpWithData:(NSData *)videoData
{
    // 包装请求参数
    NSDictionary *postDic = @{@"name":@"哈哈"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer.timeoutInterval = 200;
    
    // 发送请求 urlstr是地址
    [manager POST:[NSString stringWithFormat:@"http://192.168.0.188/gfqapi/api/Article/PostNews"] parameters:postDic constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // 上传文件设置
        [formData appendPartWithFileData:videoData name:@"video" fileName:@"littleMovie.mp4" mimeType:@"mp4"];
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // 成功
        NSLog(@"Success: %@", responseObject);
        if ([[responseObject objectForKey:@"success"] boolValue]) {
            
            
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", error.userInfo[@"NSLocalizedDescription"]);
    }];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
