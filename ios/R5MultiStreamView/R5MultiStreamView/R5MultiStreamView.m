//
//  R5MultiStreamView.m
//  React Native Red5 Pro
//
//  Created by Todd Anderson on 03/30/18.
//  Copyright © 2017 Infrared5, Inc. All rights reserved.
//

#import "R5MultiStreamView.h"

@interface R5MultiStreamView() {
  
    int _logLevel;
    BOOL _showDebugInfo;
    
    int _bitrate;
    int _framerate;
    NSString *_bundleID;
    NSString *_licenseKey;
    float _bufferTime;
    float _streamBufferTime;
    BOOL _useAdaptiveBitrateController;
  
    BOOL _isStreaming;
    int _currentRotation;
    
}
@end

@implementation R5MultiStreamView

- (id)init {
  
  if (self = [super init]) {
    
    _logLevel = 3;
    _showDebugInfo = NO;
    _bitrate = 750;
    _framerate = 15;
    _bufferTime = 0.5;
    _streamBufferTime = 2.0;
    _useAdaptiveBitrateController = NO;
    
  }
  return self;
  
}

- (R5VideoViewController *)createVideoView {
    R5VideoViewController *ctrl = [[R5VideoViewController alloc] init];
    [ctrl setView:self];
    return ctrl;
}

- (R5Configuration *)creatConfiguration:(NSString *)streamName
                               withHost:(NSString *)host
                             andContext:(NSString *)context {
    R5Configuration configuration = [[R5Configuration alloc] init];
    configuration.protocol = 1;
    configuration.host = host;
    configuration.port = 8554;
    configuruation.contextName = context;
    configuration.streamName = streamName;
    configuration.licenseKey = _licenseKey;
    configuration.bundleID = _bundleID;
    configuration.buffer_time = _bufferTime;
    configuration.stream_buffer_time = _streamBufferTime;
    return configuration;
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

- (void)subscribe:(NSString *)streamName
         withHost:(NSString *)host
       andContext:(NSString *)context
     andWithVideo:(BOOL)withVideo
     andAudioMode:(int)audioMode; {
  
  _isPublisher = NO;
  _streamName = streamName;
 
  if (_playbackVideo) {
    [self.controller setScaleMode:_scaleMode];
  }

  [self.stream setAudioController:[[R5AudioController alloc] initWithMode:_audioMode]];
  
  [self.stream play:streamName];
  
}

- (void)unsubscribe {
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (_isStreaming) {
      [self.stream stop];
    }
    else {
      self.onUnpublishNotification(@{});
      [self tearDown];
    }
  });
  
}

/*
- (void)preview {
    
    if (_useVideo) {
        AVCaptureDevice *video = [self getCameraDevice:_useBackfacingCamera];
        R5Camera *camera = [[R5Camera alloc] initWithDevice:video andBitRate:_bitrate];
        [camera setWidth:_cameraWidth];
        [camera setHeight:_cameraHeight];
        [camera setOrientation:90];
        [camera setFps:_framerate];
        [self.stream attachVideo:camera];
    }
    if (_useAudio) {
        AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        R5Microphone *microphone = [[R5Microphone alloc] initWithDevice:audio];
        microphone.bitrate = _audioBitrate;
        microphone.sampleRate = _audioSampleRate;
        [self.stream attachAudio:microphone];
    }

}
*/

- (void)publish:(NSString *)streamName withMode:(int)publishMode {
  
  _isPublisher = YES;
  _streamName = streamName;
  
  if (_useAdaptiveBitrateController) {
    R5AdaptiveBitrateController *abrController = [[R5AdaptiveBitrateController alloc] init];
    [abrController attachToStream:self.stream];
    [abrController setRequiresVideo:_useVideo];
  }
  
  [self onDeviceOrientation:NULL];
  [self.stream publish:streamName type:publishMode];
  [self.stream updateStreamMeta];
  
}

- (void)unpublish {

  dispatch_async(dispatch_get_main_queue(), ^{
    if (_isStreaming) {
      [self.stream stop];
    }
    else {
      self.onUnpublishNotification(@{});
      [self tearDown];
    }
  });
  
}

- (void)swapCamera {
  
  if (_isPublisher) {
    _useBackfacingCamera = !_useBackfacingCamera;
    AVCaptureDevice *device = [self getCameraDevice:_useBackfacingCamera];
    R5Camera *camera = (R5Camera *)[self.stream getVideoSource];
    [camera setDevice:device];
  }
  
}

- (void)updateScaleMode:(int)mode {
    
    [self setScaleMode:mode];
    
}

- (void)updateScaleSize:(int)width withHeight:(int)height withScreenWidth:(int)screenWidth withScreenHeight:(int)screenHeight {
    
    if (_playbackVideo) {
        float xscale = (width*1.0f) / (screenWidth*1.0f);
        float yscale = (height*1.0f) / (screenHeight*1.0f);
        int dwidth = [[UIScreen mainScreen] bounds].size.width;
        int dheight = [[UIScreen mainScreen] bounds].size.height;

        NSLog(@"R5VideoView:: dims(%d, %d), in(%d, %d)", width, height, screenWidth, screenHeight);
        NSLog(@"R5VideoView:: scale(%f, %f), screen(%d, %d)", xscale, yscale, dwidth, dheight);
        [self.controller setFrame:CGRectMake(0.0, 0.0, dwidth * xscale, dheight * yscale)];
    }
    
}

- (void)tearDown {
  
  if (self.stream != nil) {
    [self.stream setDelegate:nil];
    [self.stream setClient:nil];
  }
  
  _streamName = nil;
  _isStreaming = NO;

}

- (void)updateOrientation:(int)value {
  
  if (_currentRotation == value) {
    return;
  }
  _currentRotation = value;
  [self.controller.view.layer setTransform:CATransform3DMakeRotation(value, 0.0, 0.0, 0.0)];
  
}

- (void)onDeviceOrientation:(NSNotification *)notification {
  
  if (_isPublisher) {
    R5Camera *camera = (R5Camera *)[self.stream getVideoSource];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
  
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
    [self.controller showPreview:YES];
    [self.stream updateStreamMeta];
    
  }

}

- (void)layoutSubviews {
  
  [super layoutSubviews];
    // TODO: Travers stream map and set frame if view found
    /*
  if (_playbackVideo) {
    CGRect b = self.frame;
    [self.controller setFrame:CGRectMake(0.0, 0.0, b.size.width, b.size.height)];
  }
     */
  
}

# pragma R5StreamDelegate
-(void)onR5StreamStatus:(R5Stream *)stream withStatus:(int) statusCode withMessage:(NSString*)msg {
  
  NSString *tmpStreamName = _streamName;
  
  if (statusCode == r5_status_start_streaming) {
    _isStreaming = YES;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    
    if (_isPublisher) {
      self.onPublisherStreamStatus(@{
                                     @"status": @{
                                         @"code": @(statusCode),
                                         @"message": msg,
                                         @"name": @(r5_string_for_status(statusCode)),
                                         @"streamName": tmpStreamName
                                         }
                                     });
    }
    else {
      self.onSubscriberStreamStatus(@{
                                      @"status": @{
                                          @"code": @(statusCode),
                                          @"message": msg,
                                          @"name": @(r5_string_for_status(statusCode)),
                                          @"streamName": tmpStreamName
                                          }
                                      });
    }
    
    if (statusCode == r5_status_disconnected && _isStreaming) {
      if (!_isPublisher) {
        self.onUnsubscribeNotification(@{});
      }
      else if (_isPublisher) {
        self.onUnpublishNotification(@{});
      }
      [self tearDown];
      _isStreaming = NO;
    }
    
  });
  
}

# pragma R5Stream:client
- (void)onMetaData:(NSString *)params {
  
  NSArray *paramListing = [params componentsSeparatedByString:@";"];
  for (id param in paramListing) {
    NSArray *keyValue = [(NSString *)param componentsSeparatedByString:@"="];
    NSString *key = (NSString *)[keyValue objectAtIndex:0];
    if ([key  isEqual: @"streamingMode"]) {
      NSString *streamMode = (NSString *)[keyValue objectAtIndex:1];
    }
    else if ([key isEqual: @"orientation"]) {
      [self updateOrientation:[[keyValue objectAtIndex:1] intValue]];
    }
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self.onMetaDataEvent(@{@"metadata": params});
  });
  
}

- (BOOL)getShowDebugInfo {
  return _showDebugInfo;
}
- (void)setShowDebugInfo:(BOOL)show {
  _showDebugInfo = show;
  if (self.controller != nil) {
    [self.controller showDebugInfo:show];
  }
}

- (int)getLogLevel {
  return _logLevel;
}
- (void)setLogLevel:(int)level {
  _logLevel = level;
  r5_set_log_level(_logLevel);
}

- (int)getBitrate {
  return _bitrate;
}
- (void)setBitrate:(int)value {
  _bitrate = value;
}

- (int)getFramerate {
  return _framerate;
}
- (void)setFramerate:(int)value {
  _framerate = value;
}

- (float)getBufferTime {
    return _bufferTime;
}
- (void)setBufferTime:(float)value {
    _bufferTime = value;
}

- (float)getStreamBufferTime {
    return _streamBufferTime;
}
- (void)setStreamBufferTime:(float)value {
    _streamBufferTime = value;
}

- (NSString *)bundleID {
    return _bundleID;
}
- (void)bundleID:(NSString *)value {
    _bundleID = value;
}

- (NSString *)licenseKey {
    return _licenseKey;
}
- (void)licenseKey:(NSString *)value {
    _licenseKey = value;
}

- (BOOL)getUseAdaptiveBitrateController {
  return _useAdaptiveBitrateController;
}
- (void)setUseAdaptiveBitrateController:(BOOL)value {
  _useAdaptiveBitrateController = value;
}

@end
