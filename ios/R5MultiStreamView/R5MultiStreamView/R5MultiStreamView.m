//
//  R5MultiStreamView.m
//  React Native Red5 Pro
//
//  Created by Todd Anderson on 03/30/18.
//  Copyright © 2017 Infrared5, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "R5MultiStreamView.h"
#import "R5PublisherStream.h"
#import "R5SubscriberStream.h"

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
    
    BOOL _isResumable;
    BOOL _isInBackground;
    BOOL _isCheckingPermissions;
    
    NSMutableDictionary *_streamMap;
    
}
@end

@implementation R5MultiStreamView

- (id)init {
  
    if (self = [super init]) {
    
        _logLevel = 3;
        _showDebugInfo = YES;
        _bitrate = 750;
        _framerate = 15;
        _bufferTime = 0.5;
        _streamBufferTime = 2.0;
        _useAdaptiveBitrateController = NO;
      
        _streamMap = [[NSMutableDictionary alloc] initWithCapacity:4];
        r5_set_log_level(_logLevel);
        
    }
    return self;
    
}

- (R5VideoViewController *)createVideoView {
    R5VideoViewController *ctrl = [[R5VideoViewController alloc] init];
    return ctrl;
}

- (R5Configuration *)createConfiguration:(NSString *)streamName
                               withHost:(NSString *)host
                             andContext:(NSString *)context {
    
    R5Configuration *configuration = [[R5Configuration alloc] init];
    configuration.protocol = 1;
    configuration.host = host;
    configuration.port = 8554;
    configuration.contextName = context;
    configuration.streamName = streamName;
    configuration.licenseKey = _licenseKey;
    configuration.bundleID = _bundleID;
    configuration.buffer_time = _bufferTime;
    configuration.stream_buffer_time = _streamBufferTime;
    return configuration;
    
}

- (void)subscribe:(NSString *)streamName
         withHost:(NSString *)host
       andContext:(NSString *)context
     andWithVideo:(BOOL)withVideo
     andAudioMode:(int)audioMode {
  
    dispatch_async(dispatch_get_main_queue(), ^{
        
        R5SubscriberStream *subscriber = NULL;
        if (withVideo) {
            subscriber = [[R5SubscriberStream alloc] initWithEventProxy:self andView:[self createVideoView]];
        }
        else {
            subscriber = [[R5SubscriberStream alloc] initWithEventProxy:self];
        }
        
        [subscriber setConfiguration:[self createConfiguration:streamName withHost:host andContext:context]];
        [_streamMap setObject:subscriber forKey:streamName];
        
        if (withVideo) {
            R5VideoViewController *ctrl = [subscriber getView];
            [ctrl setView:self];
            UIViewController *rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
            [ctrl setFrame:rootVc.view.frame];
            [ctrl showDebugInfo:_showDebugInfo];
        }
        // TODO: If not in background ->
        [subscriber start];
        
        if (self.onConfigured) {
            self.onConfigured(@{@"key": streamName});
        }
        
    });
}

- (void)unsubscribe:(NSString *) streamName {
  
    dispatch_async(dispatch_get_main_queue(), ^{
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:streamName];
        if (stream != NULL) {
            [stream stop];
            [_streamMap removeObjectForKey:streamName];
        }
    });
    
}

- (void)publish:(NSString *)streamName
       withHost:(NSString *)host
     andContext:(NSString *)context
   andWithVideo:(BOOL)withVideo
 andCameraWidth:(int)width
andCameraHeight:(int)height
        andMode:(int)publishMode {
  
    dispatch_async(dispatch_get_main_queue(), ^{
        
        R5PublisherStream *publisher = NULL;
        if (withVideo) {
            publisher = [[R5PublisherStream alloc] initWithEventProxy:self andView:[self createVideoView]];
        }
        else {
            publisher = [[R5PublisherStream alloc] initWithEventProxy:self];
        }
    
        [publisher setConfiguration:[self createConfiguration:streamName withHost:host andContext:context]
                     andCameraWidth:width
                    andCameraHeight:height
                         andBitrate:_bitrate
                       andFramerate:_framerate
                      andStreamType:publishMode
                          andUseABR:_useAdaptiveBitrateController];
    
        [publisher start];
        [_streamMap setObject:publisher forKey:streamName];
    
    
        if (withVideo) {
            R5VideoViewController *ctrl = [publisher getView];
            [ctrl setView:self];
            UIViewController *rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
            [ctrl setFrame:rootVc.view.frame];
            [ctrl showDebugInfo:_showDebugInfo];
        }

        if (self.onConfigured) {
            self.onConfigured(@{@"key": streamName});
        }
        
        [self onDeviceOrientation:NULL];
        
    });
    
}

- (void)unpublish:(NSString *)streamName {

    dispatch_async(dispatch_get_main_queue(), ^{
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:streamName];
        if (stream != NULL) {
            [stream stop];
            [_streamMap removeObjectForKey:streamName];
        }
    });
  
}

- (void)updateScaleSize:(NSString *)streamName
              withWidth:(int)width
             andHeight:(int)height
        andScreenWidth:(int)screenWidth
       andScreenHeight:(int)screenHeight {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
        CGSize size = rootVc.view.frame.size;
        float xscale = (width * 1.0f) / (screenWidth * 1.0f);
        float yscale = (height * 1.0f) / (screenHeight * 1.0f);
        float dimsWidth = size.width;
        float dimsHeight = size.height;
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            R5VideoViewController *controller = [stream getView];
            if (controller != NULL) {
                [controller setFrame:CGRectMake(0.0, 0.0, dimsWidth * xscale, dimsHeight * yscale)];
            }
        }
    });

}

- (void)swapCamera:(NSString *)streamName {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:streamName];
        if ([stream respondsToSelector:@selector(swapCamera)]) {
            [(R5PublisherStream *)stream swapCamera];
        }
    });
    
}

- (void)shutdown {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            [stream stop];
        }
        [_streamMap removeAllObjects];
    });
    
}

- (void)setPermissionsFlag:(BOOL)flag {
    _isCheckingPermissions = flag;
}

#pragma NSNotificationDelegate
- (void)willPause {
    _isInBackground = YES;
    if (_isCheckingPermissions) {
        return;
    }
    
    _isResumable = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            [stream pause];
            if ([stream respondsToSelector:@selector(swapCamera)]) { // its a publisher...
                [_streamMap removeObjectForKey:key];
            }
        }
    });
    
}
- (void)willResume {
    _isInBackground = NO;
    if (!_isResumable) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            [stream resume];
        }
    });
    _isResumable = NO;
    
}
- (void)willDestroy {
    _isCheckingPermissions = NO;
    _isInBackground = NO;
    _isResumable = NO;
    [self shutdown];
}

- (void)onDeviceOrientation:(NSNotification *)notification {
  
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            if ([stream respondsToSelector:@selector(setDeviceOrientation:)]) {
                [(R5PublisherStream *)stream setDeviceOrientation:[UIDevice currentDevice].orientation];
            }
        }
    });

}

- (void)layoutSubviews {
  
    [super layoutSubviews];
}

# pragma EventEmitterProxy
- (void)onStreamMetaDataEvent:(NSString *)streamName andMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onMetaDataEvent(message);
    });
}
- (void)onStreamPublisherStatus:(NSString *)streamName andMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onPublisherStreamStatus(message);
    });
}
- (void)onStreamSubscriberStatus:(NSString *)streamName andMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onSubscriberStreamStatus(message);
    });
}
- (void)onStreamUnpublishNotification:(NSString *)streamName andMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onUnpublishNotification(message);
    });
}
- (void)onStreamUnsubscribeNotification:(NSString *)streamName andMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onUnsubscribeNotification(message);
    });
}

- (BOOL)getShowDebugInfo {
    return _showDebugInfo;
}
- (void)setShowDebugInfo:(BOOL)show {
    _showDebugInfo = show;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in _streamMap) {
            id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
            R5VideoViewController *controller = [stream getView];
            if (controller != NULL) {
                [controller showDebugInfo:show];
            }
        }
    });
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
