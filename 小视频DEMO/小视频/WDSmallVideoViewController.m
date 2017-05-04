//
//  DSSmallVideoViewController.m
//  框架
//
//  Created by 朱辉 on 16/3/29.
//  Copyright © 2016年 朱辉. All rights reserved.
//

#import "WDSmallVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+RMAdditions.h"
#import "WDSmallVideoPlayerController.h"


#define kDuration 10.0
#define kTrans SCREEN_WIDTH/kDuration/60.0
#define KSCREEN_HEIGHT   ([[UIScreen mainScreen] bounds].size.height)  //屏幕高度
#define KSCREEN_WIDTH    ([[UIScreen mainScreen] bounds].size.width)   //屏幕宽度
typedef NS_ENUM(NSInteger,VideoStatus){
    VideoStatusEnded = 0,
    VideoStatusStarted
};


@interface WDSmallVideoViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    AVCaptureSession *_captureSession;
    AVCaptureDevice  *_videoDevice;
    AVCaptureDevice  *_audioDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureDeviceInput *_audioInput;
    AVCaptureMovieFileOutput *_movieOutput;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    
}
@property (weak, nonatomic)  NSLayoutConstraint *progressWidth;

// 进度条
@property (weak, nonatomic)  UIView  *progressView;

// 取消
@property (weak, nonatomic)  UILabel *cancelTip;

// 拍摄
@property (weak, nonatomic)  UILabel *tapBtn;

// 视频view
@property (weak, nonatomic)  UIView  *videoView;

// 切换摄像头
@property (weak, nonatomic)  UIButton *changeBtn;

// 闪光灯
@property (weak, nonatomic)  UIButton *flashModelBtn;


@property (nonatomic,weak)   UIView *focusCircle;
@property (nonatomic,assign) VideoStatus status;
@property (nonatomic,assign) BOOL canSave;
@property (nonatomic,strong) CADisplayLink *link;

@end

@implementation WDSmallVideoViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_captureSession startRunning];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_captureSession stopRunning];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];


    self.view.backgroundColor = [UIColor blackColor];
    
    //绘制UI
    [self initUI];
    
    //获取授权
    [self getAuthorization];

}

#pragma mark  绘制UI =====
- (void)initUI
{
    
    UIView *videoView =[[UIView alloc] init];
    videoView.frame = CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT/2);
    videoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:videoView];
    self.videoView = videoView;
    
    UIView *progressView = [[UIView alloc] init];
    progressView.frame = CGRectMake(0, CGRectGetMaxY(self.videoView.frame)-4, KSCREEN_WIDTH, 4);
    progressView.center = CGPointMake(KSCREEN_WIDTH/2, CGRectGetMaxY(self.videoView.frame) - 2);
    progressView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
    
    
    UILabel *cancelTip = [[UILabel alloc] init];
    CGSize sizi= CGSizeMake(120, 20);
    cancelTip.size = sizi;
    cancelTip.center = CGPointMake(KSCREEN_WIDTH/2, CGRectGetMinY(progressView.frame) - 6 - 20);
    cancelTip.font = [UIFont systemFontOfSize:12];
    cancelTip.textColor = [UIColor redColor];
    cancelTip.textAlignment = NSTextAlignmentCenter;
    cancelTip.backgroundColor = [UIColor clearColor];
    [self.view addSubview:cancelTip];
    self.cancelTip = cancelTip;
    
    UILabel *tapBtn = [UILabel new];
    tapBtn.frame = CGRectMake(100, KSCREEN_HEIGHT/2, 100, 100);
    tapBtn.center = CGPointMake(KSCREEN_WIDTH/2, KSCREEN_HEIGHT/2 + 120);
    tapBtn.text = @"按住";
    tapBtn.textAlignment = NSTextAlignmentCenter;
    tapBtn.textColor = [UIColor greenColor];
    tapBtn.layer.cornerRadius = tapBtn.frame.size.width/2;
    tapBtn.layer.borderWidth = 2.0;
    tapBtn.layer.borderColor = [UIColor greenColor].CGColor;
    tapBtn.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tapBtn];
    self.tapBtn = tapBtn;
    
    
    UIButton *flashModelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    flashModelBtn.frame = CGRectMake(20, 40, 160, 20);
    flashModelBtn.backgroundColor = [UIColor clearColor];
    [flashModelBtn setTitle:@"闪光灯:OFF/ON" forState:UIControlStateNormal];
    [flashModelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flashModelBtn addTarget:self action:@selector(changeFlashlight:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashModelBtn];
    self.flashModelBtn = flashModelBtn;
    
    UIButton *changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    changeBtn.frame = CGRectMake(KSCREEN_WIDTH - 120, 40, 120, 20);
    changeBtn.backgroundColor = [UIColor clearColor];
    [changeBtn setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [changeBtn addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeBtn];
    self.changeBtn = changeBtn;
    
    
    [self.view bringSubviewToFront:self.cancelTip];
    [self.view bringSubviewToFront:self.progressView];
    [self.view bringSubviewToFront:self.changeBtn];
    [self.view bringSubviewToFront:self.flashModelBtn];
    
    self.videoView.layer.masksToBounds = YES;
    [self addGenstureRecognizer];
}

// 添加手势 1.点按时聚焦 2.调焦
-(void)addGenstureRecognizer{
    
    UITapGestureRecognizer *singleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.delaysTouchesBegan = YES;
    
    UITapGestureRecognizer *doubleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.delaysTouchesBegan = YES;

    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self.videoView addGestureRecognizer:singleTapGesture];
    [self.videoView addGestureRecognizer:doubleTapGesture];
}


#pragma mark
#pragma mark  获取设备授权
- (void)getAuthorization
{
    /*
     AVAuthorizationStatusNotDetermined = 0,// 未进行授权选择
     
     AVAuthorizationStatusRestricted,　　　　// 未授权，且用户无法更新，如家长控制情况下
     
     AVAuthorizationStatusDenied,　　　　　　 // 用户拒绝App使用
     
     AVAuthorizationStatusAuthorized,　　　　// 已授权，可使用
     */
    
    
    //此处检测摄像头授权是否打开
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusAuthorized: //已授权，可使用
        {
            NSLog(@"授权摄像头使用成功");
            [self setupAVCaptureInfo];
            break;
        }
        case AVAuthorizationStatusNotDetermined://未进行授权选择
        {
            //则请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if(granted){    //用户授权成功
                    
                    [self setupAVCaptureInfo];
                    return;
                    
                } else {       //用户拒绝授权
                    
                    [self pop];
                    [self showMsgWithTitle:@"出错了" andContent:@"用户拒绝授权摄像头的使用权,返回上一页.请打开\n设置-->隐私/通用/相机中允许广丰圈访问您的像机"];
                    return;
                }
            }];
            break;
        }
        default:                                    //用户拒绝授权/未授权
        {
            [self pop];
            [self showMsgWithTitle:@"出错了" andContent:@"拒绝授权,返回上一页.请检查下\n设置-->隐私/通用等权限设置"];
            break;
        }
    }
    
    
    
    //检测麦克风功能是否打开
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted)
        {
            [self showMsgWithTitle:@"麦克风功能未开启" andContent:@"请在iPhone的\"设置-隐私-麦克风\"中允许少儿时光访问你的麦克风"];
        }
        else
        {
            
        }
    }];

    
}

// 获取摄像头-->前/后

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}


#pragma mark
#pragma mark  配置病初始化设备 =====
- (void)setupAVCaptureInfo
{
    //添加会话
    [self loadSmallVideoSession];
    [_captureSession beginConfiguration];
    
    
    //添加视频设备,输入源对象,输出对象
    [self loadSmallVideoVideo];
    
    
    //添加音频设备,输入对象,输出对象
    [self loadSmallVideoAudio];
    
    
    //添加视频预览图层
    [self loadSmallVideoPreviewLayer];
    
    [_captureSession commitConfiguration];
    
    //开启会话-->注意,不等于开始录制
    [_captureSession startRunning];
    
}

// 添加会话  =====
- (void)loadSmallVideoSession
{
    _captureSession = [[AVCaptureSession alloc] init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;

    }
    
    //设置视频分辨率
    /*  通常支持如下格式
     (
     AVAssetExportPresetLowQuality,
     AVAssetExportPreset960x540,
     AVAssetExportPreset640x480,
     AVAssetExportPresetMediumQuality,
     AVAssetExportPreset1920x1080,
     AVAssetExportPreset1280x720,
     AVAssetExportPresetHighestQuality,
     AVAssetExportPresetAppleM4A
     )
     */
   
}
// 添加视频设备,输入源对象,输出对象  ===
- (void)loadSmallVideoVideo
{
    // 获取摄像头输入设备， 创建 AVCaptureDeviceInput 对象
    /* MediaType
     AVF_EXPORT NSString *const AVMediaTypeVideo                 NS_AVAILABLE(10_7, 4_0);       //视频
     AVF_EXPORT NSString *const AVMediaTypeAudio                 NS_AVAILABLE(10_7, 4_0);       //音频
     AVF_EXPORT NSString *const AVMediaTypeText                  NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeClosedCaption         NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeSubtitle              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeTimecode              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeMetadata              NS_AVAILABLE(10_8, 6_0);
     AVF_EXPORT NSString *const AVMediaTypeMuxed                 NS_AVAILABLE(10_7, 4_0);
     */
    
    /* AVCaptureDevicePosition
     typedef NS_ENUM(NSInteger, AVCaptureDevicePosition) {
     AVCaptureDevicePositionUnspecified         = 0,
     AVCaptureDevicePositionBack                = 1,            //后置摄像头
     AVCaptureDevicePositionFront               = 2             //前置摄像头
     } NS_AVAILABLE(10_7, 4_0) __TVOS_PROHIBITED;
     */
    
    //1.0 获取视频设备(视频模式,后摄像头)
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    
    
    //2.0 初始化输入源对象
    NSError *videoError;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&videoError];
    if (videoError) {
        NSLog(@"取得摄像头设备时出错 %@",videoError);
        return;
    }
    
    //2.1 将视频输入对象添加到会话 (AVCaptureSession) 中
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
    
    
    //3.0 初始化输出对象
    _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    
    //3.1 将视频输出对象添加到会话 (AVCaptureSession) 中
    if ([_captureSession canAddOutput:_movieOutput]) {
        
        [_captureSession addOutput:_movieOutput];
        AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
        
        //设置视频旋转方向
        /*
         typedef NS_ENUM(NSInteger, AVCaptureVideoOrientation) {
         AVCaptureVideoOrientationPortrait           = 1,
         AVCaptureVideoOrientationPortraitUpsideDown = 2,
         AVCaptureVideoOrientationLandscapeRight     = 3,
         AVCaptureVideoOrientationLandscapeLeft      = 4,
         } NS_AVAILABLE(10_7, 4_0) __TVOS_PROHIBITED;
         */
        //        if ([captureConnection isVideoOrientationSupported]) {
        //            [captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        //        }
        
        // 视频稳定设置  光学防抖
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    }

}

//  添加音频设备,输入对象,输出对象  ===
- (void)loadSmallVideoAudio
{
    NSError *audioError;
    //1.0 添加一个音频输入设备
    _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //2.0 初始化音频输入对象
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:_audioDevice error:&audioError];
    if (audioError) {
        NSLog(@"取得录音设备时出错%@",audioError);
        return;
    }
    //3.0 将音频输入对象添加到会话 (AVCaptureSession) 中
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
}

// 添加并初始化视频预览图层 ====
- (void)loadSmallVideoPreviewLayer
{
    
    [self.view layoutIfNeeded];
    
    // 通过会话 (AVCaptureSession) 创建预览层
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _captureVideoPreviewLayer.frame = self.view.layer.bounds;
    
    /* 填充模式
     Options are AVLayerVideoGravityResize, AVLayerVideoGravityResizeAspect and AVLayerVideoGravityResizeAspectFill. AVLayerVideoGravityResizeAspect is default.
     */
    //有时候需要拍摄完整屏幕大小的时候可以修改这个
    //    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // 如果预览图层和视频方向不一致,可以修改这个
    _captureVideoPreviewLayer.connection.videoOrientation = [_movieOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
    _captureVideoPreviewLayer.position = CGPointMake(self.view.width*0.5,self.videoView.height*0.5);
    
    // 显示在视图表面的图层
    CALayer *layer = self.videoView.layer;
    layer.masksToBounds = true;
    [self.view layoutIfNeeded];
    [layer addSublayer:_captureVideoPreviewLayer];
    
}

//下面这2个也可以获取前后摄像头,不过有一定的风险,假如手机又问题,找不到对应的 UniqueID 设备,则呵呵了
//- (AVCaptureDevice *)frontCamera
//{
//    return [AVCaptureDevice deviceWithUniqueID:@"com.apple.avfoundation.avcapturedevice.built-in_video:1"];
//}
//
//- (AVCaptureDevice *)backCamera
//{
//    return [AVCaptureDevice deviceWithUniqueID:@"com.apple.avfoundation.avcapturedevice.built-in_video:0"];
//}
#pragma mark
#pragma mark  触控相关

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self.view];
    BOOL condition = [self isInBtnRect:point];
    
    if (condition) {
        //按住开始录制
        [self isFitCondition:condition];
        [self startAnimation];
        self.changeBtn.hidden= YES;
        self.flashModelBtn.hidden = YES;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    BOOL condition = [self isInBtnRect:point];
    
    [self isFitCondition:condition];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    BOOL condition = [self isInBtnRect:point];
    /*
     结束时候咱们设定有两种情况依然算录制成功
     1.抬手时,录制时长 > 1/3总时长
     2.录制进度条完成时,就算手指超出按钮范围也算录制成功 -- 此时 end 方法不会调用,因为用户手指还在屏幕上,所以直接代码调用录制成功的方法,将控制器切换
     */
    
    if (condition) {
        if (self.progressView.frame.size.width < SCREEN_WIDTH * 0.67) {
            //录制完成
            [self recordComplete];
        }
    }
    
    [self stopAnimation];
    self.changeBtn.hidden = NO;
    self.flashModelBtn.hidden = NO;
}

- (BOOL)isInBtnRect:(CGPoint)point
{
    CGFloat x = point.x;
    CGFloat y = point.y;
    return  (x>self.tapBtn.left && x<=self.tapBtn.right) && (y>self.tapBtn.top && y<=self.tapBtn.bottom);
}
//检测
- (void)isFitCondition:(BOOL)condition
{
    if (condition) {
        self.cancelTip.text = @"上滑取消";
        self.cancelTip.backgroundColor = [UIColor orangeColor];
        self.cancelTip.textColor = [UIColor blackColor];
    }else{
        self.cancelTip.text = @"松手取消录制";
        self.cancelTip.backgroundColor = [UIColor redColor];
        self.cancelTip.textColor = [UIColor whiteColor];
    }
}

- (void)startAnimation
{
    if (self.status == VideoStatusEnded) {
        self.status = VideoStatusStarted;
        [UIView animateWithDuration:0.5 animations:^{
            self.cancelTip.alpha = 1.0;
            self.progressView.alpha = 1.0;
            self.tapBtn.alpha = 0.0;
            self.tapBtn.transform = CGAffineTransformMakeScale(2.0, 2.0);
        } completion:^(BOOL finished) {
            [self stopLink];
            [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }];
    }
}

- (void)stopAnimation{
    if (self.status == VideoStatusStarted) {
        self.status = VideoStatusEnded;
        
        [self stopLink];
        [self stopRecord];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.cancelTip.alpha = 0.0;
            self.progressView.alpha = 0.0;
            self.tapBtn.alpha = 1.0;
            self.tapBtn.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {

            CGRect rect = self.progressView.frame;
            rect.size.width = KSCREEN_WIDTH;
            self.progressView.frame = rect;
        }];
    }
}

- (CADisplayLink *)link
{
    if (!_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
        CGRect rect = self.progressView.frame;
        rect.size.width =SCREEN_WIDTH ;
        self.progressView.frame  =  rect;
        [self startRecord];
    }
    return _link;
}

- (void)stopLink
{
    _link.paused = YES;
    [_link invalidate];
    _link = nil;
}

- (void)refresh:(CADisplayLink *)link
{
//    if (self.progressWidth.constant <= 0) {
//        
//        self.progressWidth.constant = 0;
//        [self recordComplete];
//        [self stopAnimation];
//        return;
//    }
    
    CGRect rect = self.progressView.frame;
    
    if (self.progressView.frame.size.width <= 2.0) {
        
        rect.size.width = 0.0 ;
        self.progressView.frame = rect;
        [self recordComplete];
        [self stopAnimation];
        return;

    }
    
    NSLog(@"self.progressWidth.constant ==== %f",self.progressView.frame.size.width);

    rect.size.width -=kTrans;
    self.progressView.frame = rect;
    self.progressView.center = CGPointMake(KSCREEN_WIDTH/2, CGRectGetMaxY(self.videoView.frame)-2);
    //self.progressWidth.constant -=kTrans;
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-DD--HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    NSLog(@"%@",dateTime);
    
    
    
    
}
#pragma mark
#pragma mark 录制相关

- (NSURL *)outPutFileURL
{
    
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"outPut.mov"]];
    
}

- (void)startRecord
{
    [_movieOutput startRecordingToOutputFileURL:[self outPutFileURL] recordingDelegate:self];
}

- (void)stopRecord
{
    // 取消视频拍摄
    [_movieOutput stopRecording];
}

- (void)recordComplete
{
    self.canSave = YES;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"---- 开始录制 ----");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"---- 录制结束 ---%@-%@ ",outputFileURL,captureOutput.outputFileURL);
    
    if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0 ) {
        [self showMsgWithTitle:@"出错了" andContent:@"录制视频保存地址出错"];
        return;
    }
    
    
    if (self.canSave) {
        [self pushToPlay:outputFileURL];
        self.canSave = NO;
    }
}

- (void)pushToPlay:(NSURL *)url
{
    //PostVideoPlayerController *postVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"PostVideoPlayerController"];
    WDSmallVideoPlayerController *postVC = [[WDSmallVideoPlayerController alloc] init];
    
    postVC.videoUrl = url;
    [self.navigationController pushViewController:postVC animated:YES];
}

#pragma mark
#pragma mark 拍摄交互
//切换闪光灯    闪光模式开启后,并无明显感觉,所以还需要开启手电筒
- (void)changeFlashlight:(UIButton *)sender {
    
    BOOL con1 = [_videoDevice hasTorch];    //支持手电筒模式
    BOOL con2 = [_videoDevice hasFlash];    //支持闪光模式
    
    if (con1 && con2)
    {
        [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
            if (_videoDevice.flashMode == AVCaptureFlashModeOn)         //闪光灯开
            {
                [_videoDevice setFlashMode:AVCaptureFlashModeOff];
                [_videoDevice setTorchMode:AVCaptureTorchModeOff];
            }else if (_videoDevice.flashMode == AVCaptureFlashModeOff)  //闪光灯关
            {
                [_videoDevice setFlashMode:AVCaptureFlashModeOn];
                [_videoDevice setTorchMode:AVCaptureTorchModeOn];
            }
            //            else{                                                      //闪光灯自动
            //                [_videoDevice setFlashMode:AVCaptureFlashModeAuto];
            //                [_videoDevice setTorchMode:AVCaptureTorchModeAuto];
            //            }
            NSLog(@"现在的闪光模式是AVCaptureFlashModeOn么?是你就扣1, %zd",_videoDevice.flashMode == AVCaptureFlashModeOn);
        }];
        sender.selected=!sender.isSelected;
    }else{
        NSLog(@"不能切换闪光模式");
    }
}

//切换前后镜头
- (void)changeCamera{
    
    switch (_videoDevice.position) {
        case AVCaptureDevicePositionBack:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
            break;
        case AVCaptureDevicePositionFront:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            break;
        default:
            return;
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&error];
        
        if (newVideoInput != nil) {
            //必选先 remove 才能询问 canAdd
            [_captureSession removeInput:_videoInput];
            if ([_captureSession canAddInput:newVideoInput]) {
                [_captureSession addInput:newVideoInput];
                _videoInput = newVideoInput;
            }else{
                [_captureSession addInput:_videoInput];
            }
            
        } else if (error) {
            NSLog(@"切换前/后摄像头失败, error = %@", error);
        }
    }];
    
}



-(void)singleTap:(UITapGestureRecognizer *)tapGesture{
    
    NSLog(@"单击");
    
    CGPoint point= [tapGesture locationInView:self.videoView];
    //将UI坐标转化为摄像头坐标,摄像头聚焦点范围0~1
    CGPoint cameraPoint= [_captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorAnimationWithPoint:point];
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        
        /*
         @constant AVCaptureFocusModeLocked 锁定在当前焦距
         Indicates that the focus should be locked at the lens' current position.
         
         @constant AVCaptureFocusModeAutoFocus 自动对焦一次,然后切换到焦距锁定
         Indicates that the device should autofocus once and then change the focus mode to AVCaptureFocusModeLocked.
         
         @constant AVCaptureFocusModeContinuousAutoFocus 当需要时.自动调整焦距
         Indicates that the device should automatically focus when needed.
         */
        //聚焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            NSLog(@"聚焦模式修改为%zd",AVCaptureFocusModeContinuousAutoFocus);
        }else{
            NSLog(@"聚焦模式修改失败");
        }
        
        //聚焦点的位置
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        
        /*
         @constant AVCaptureExposureModeLocked  曝光锁定在当前值
         Indicates that the exposure should be locked at its current value.
         
         @constant AVCaptureExposureModeAutoExpose 曝光自动调整一次然后锁定
         Indicates that the device should automatically adjust exposure once and then change the exposure mode to AVCaptureExposureModeLocked.
         
         @constant AVCaptureExposureModeContinuousAutoExposure 曝光自动调整
         Indicates that the device should automatically adjust exposure when needed.
         
         @constant AVCaptureExposureModeCustom 曝光只根据设定的值来
         Indicates that the device should only adjust exposure according to user provided ISO, exposureDuration values.
         
         */
        //曝光模式
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        
        //曝光点的位置
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
        }
        
        
    }];
}

//设置焦距 双击
-(void)doubleTap:(UITapGestureRecognizer *)tapGesture{
    
    NSLog(@"双击");
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if (captureDevice.videoZoomFactor == 1.0) {
            CGFloat current = 1.5;
            if (current < captureDevice.activeFormat.videoMaxZoomFactor) {
                [captureDevice rampToVideoZoomFactor:current withRate:10];
            }
        }else{
            [captureDevice rampToVideoZoomFactor:1.0 withRate:10];
        }
    }];
}

//光圈动画
-(void)setFocusCursorAnimationWithPoint:(CGPoint)point{
    self.focusCircle.center = point;
    self.focusCircle.transform = CGAffineTransformIdentity;
    self.focusCircle.alpha = 1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCircle.transform=CGAffineTransformMakeScale(0.5, 0.5);
        self.focusCircle.alpha = 0.0;
    }];
}

//光圈
- (UIView *)focusCircle{
    if (!_focusCircle) {
        UIView *focusCircle = [[UIView alloc] init];
        focusCircle.frame = CGRectMake(0, 0, 100, 100);
        focusCircle.layer.borderColor = [UIColor orangeColor].CGColor;
        focusCircle.layer.borderWidth = 2;
        focusCircle.layer.cornerRadius = 50;
        focusCircle.layer.masksToBounds =YES;
        _focusCircle = focusCircle;
        [self.videoView addSubview:focusCircle];
    }
    return _focusCircle;
}

//更改设备属性前一定要锁上
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [_videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁,意义是---进行修改期间,先锁定,防止多处同时修改
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }else{
        [_captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_captureSession commitConfiguration];
    }
}

#pragma mark
#pragma mark pop

-(void)pop
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)showMsgWithTitle:(NSString *)title andContent:(NSString *)content
{
    [[[UIAlertView alloc] initWithTitle:title message:content delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
