//
//  R5PublisherStream.m
//  R5MultStreamView
//
//  Created by Todd Anderson on 3/30/18.
//  Copyright © 2018 Red5Pro. All rights reserved.
//

#import <R5Streaming/R5Streaming.h>
#import "R5PublisherStream.h"

@interface R5PublisherStream() {
    
    R5Stream *_stream;
    R5Connection *_connection;
    R5Configuration *_configuration;
    
    NSString *_streamName;
    R5VideoViewController *_view;
    id<EventEmitterProxy> _proxy;
    R5Camera *_camera;
    R5Microphone *_microphone;
    
    int _logLevel;
    int _streamType;
    BOOL _useAudio;
    BOOL _useBackfacingCamera;
    BOOL _isStreaming;
    
}
@end;

@implementation R5PublisherStream

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy {
    if (self = [super init]) {
        _proxy = proxy;
    }
    return self;
}

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy andView:(R5VideoViewController *)view {
    if (self = [super init]) {
        _proxy = proxy;
        _view = view;
    }
    return self;
}

- (void)cleanUp {
    
    if (_stream != NULL) {
        [_stream setDelegate:NULL];
        [_stream setClient:NULL];
    }
    
    _stream = NULL;
    _camera = NULL;
    _microphone = NULL;
    
}

- (AVCaptureDevice *)getCameraDevice:(BOOL)backfacing {
    
    NSArray *list = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    for (AVCaptureDevice *device in list) {
        if (device.position == AVCaptureDevicePositionFront) {
            frontCamera = device;
        }
        else if (device.position == AVCaptureDevicePositionBack) {
            backCamera = device;
        }
    }
    
    if (backfacing && backCamera != NULL) {
        return backCamera;
    }
    return frontCamera;
    
}

- (R5Camera* )setUpCamera:(int)width
         withHeight:(int)height
         andBitrate:(float)bitrate
       andFramerate:(float)framerate {
    
    AVCaptureDevice *video = [self getCameraDevice:_useBackfacingCamera];
    R5Camera *camera = [[R5Camera alloc] initWithDevice:video andBitRate:bitrate];
    [camera setWidth:width];
    [camera setHeight:height];
    [camera setOrientation:90];
    [camera setFps:framerate];
    return camera;
}

- (R5Microphone *)setUpMicrophone {
    
    AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    R5Microphone *microphone = [[R5Microphone alloc] initWithDevice:audio];
    [microphone setBitrate:32];
    [microphone setSampleRate:16000];
    return microphone;
    
}

- (void)setConfiguration:(R5Configuration *)configuration
             andCameraWidth:(int)width
            andCameraHeight:(int)height
                 andBitrate:(float)bitrate
               andFramerate:(float)framerate
              andStreamType:(int)type
                  andUseABR:(BOOL)useABR {
    
    _logLevel = 3;
    _useAudio = YES;
    _useBackfacingCamera = NO;
    
    _streamType = type;
    _streamName = configuration.streamName;
        
    _configuration = configuration;
    R5Connection *connection = [[R5Connection alloc] initWithConfig:_configuration];
    R5Stream *stream = [[R5Stream alloc] initWithConnection:connection];
        
    [stream setClient:self];
    [stream setDelegate:self];
        
    _stream = stream;
    _connection = connection;
    
    if (_view != NULL) {
        _camera = [self setUpCamera:width withHeight:height andBitrate:bitrate andFramerate:framerate];
    }
    
    if (_useAudio) {
        _microphone = [self setUpMicrophone];
    }
    
    if (useABR) {
        R5AdaptiveBitrateController *abrController = [[R5AdaptiveBitrateController alloc] init];
        [abrController attachToStream:_stream];
        if (_view != NULL) {
            [abrController setRequiresVideo:YES];
        }
        else {
            [abrController setRequiresVideo:NO];
        }
    }
    
    if (_view != NULL) {
        [_view attachStream:_stream];
    }
    if (_camera != NULL) {
        [_stream attachVideo:_camera];
    }
    
}

- (void)swapCamera {
    
    _useBackfacingCamera = !_useBackfacingCamera;
    AVCaptureDevice *device = [self getCameraDevice:_useBackfacingCamera];
    R5Camera *camera = (R5Camera *)[_stream getVideoSource];
    [camera setDevice:device];
    
}

- (void)setDeviceOrientation:(UIDeviceOrientation)orientation {
    
    R5Camera *camera = (R5Camera *)[self.stream getVideoSource];
    if (camera != NULL) {
        
        if (orientation == UIDeviceOrientationPortraitUpsideDown) {
            [camera setOrientation: 270];
        }
        else if (orientation == UIDeviceOrientationLandscapeLeft) {
            if (_useBackfacingCamera) {
                [camera setOrientation: 0];
            }
            else {
                [camera setOrientation: 180];
            }
        }
        else if (orientation == UIDeviceOrientationLandscapeRight) {
            if (_useBackfacingCamera) {
                [camera setOrientation: 180];
            }
            else {
                [camera setOrientation: 0];
            }
        }
        else {
            [camera setOrientation: 90];
        }
        
        if (_view != NULL) {
            [_view showPreview:YES];
        }
        [_stream updateStreamMeta];
    }
    
}

# pragma Stream
- (void)start {
    
    [_stream publish:_streamName type:_streamType];
    [_stream updateStreamMeta];
    
    if (_view != NULL) {
        [_view showPreview:YES];
    }
    
}

- (void)stop {
    
    if (_stream != NULL) {
        if (_camera != NULL) {
            [_camera stopVideoCapture];
            _camera = NULL;
            [_stream attachVideo:NULL];
        }
        if (_view != NULL) {
            [_view attachStream:NULL];
            _view = NULL;
        }
                                      
        [_stream stop];
        _stream = NULL;
    }
    else {
        [_proxy onStreamUnpublishNotification:_streamName andMessage:@{}];
        [self cleanUp];
    }
    
}

- (void)pause {
    [self stop];
}

- (void)resume {
    // nada.
}

- (void)updateScaleSize:(int)width
             withHeight:(int)height
         andScreenWidth:(int)screenWidth
        andScreenHeight:(int)screenHeight {
    
}

- (int)getLogLevel {
    return _logLevel;
}

- (void)setLogLevel:(int)value {
    _logLevel = value;
    r5_set_log_level(_logLevel);
}

- (R5VideoViewController *)getView {
    return _view;
}

# pragma R5Stream:client
- (void)onMetaData:(NSString *)params {
    
    NSArray *paramListing = [params componentsSeparatedByString:@";"];
    for (id param in paramListing) {
        NSArray *keyValue = [(NSString *)param componentsSeparatedByString:@"="];
        NSString *key = (NSString *)[keyValue objectAtIndex:0];
        if ([key  isEqual: @"streamingMode"]) {
//            NSString *streamMode = (NSString *)[keyValue objectAtIndex:1];
        }
        else if ([key isEqual: @"orientation"]) {
            // FOR SUBSCRIBERS ->
//            [self updateOrientation:[[keyValue objectAtIndex:1] intValue]];
        }
    }
    
    [_proxy onStreamMetaDataEvent:_streamName andMessage:@{@"metadata": params}];
    
}

# pragma R5StreamDelegate
- (void)onR5StreamStatus:(R5Stream *)stream withStatus:(int) statusCode withMessage:(NSString*)msg {
    
    if (statusCode == r5_status_start_streaming) {
        _isStreaming = YES;
    }
    
    [_proxy onStreamPublisherStatus:_streamName andMessage:@{
                                                              @"status": @{
                                                                      @"code": @(statusCode),
                                                                      @"message": msg,
                                                                      @"name": @(r5_string_for_status(statusCode)),
                                                                      @"streamName": _streamName
                                                                      }
                                                              }];
    
    if (statusCode == r5_status_disconnected && _isStreaming) {
        [_proxy onStreamUnpublishNotification:_streamName andMessage:@{}];
        _isStreaming = false;
    }
    
}

@end
