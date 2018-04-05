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

    R5SubscriberStream *subscriber = NULL;
    if (withVideo) {
        subscriber = [[R5SubscriberStream alloc] initWithEventProxy:self andView:[self createVideoView]];
    }
    else {
        subscriber = [[R5SubscriberStream alloc] initWithEventProxy:self];
    }

    [subscriber setConfiguration:[self createConfiguration:streamName withHost:host andContext:context]];

    // TODO: If not in background ->
    [subscriber start];

    [_streamMap setObject:subscriber forKey:streamName];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (withVideo) {
            R5VideoViewController *ctrl = [subscriber getView];
            [ctrl showPreview:YES];
            [ctrl setView:self];
            [ctrl setFrame:self.frame];
            [self layoutSubviews];
        }
        if (self.onConfigured) {
            self.onConfigured(@{@"key": streamName});
        }
    });
}

- (void)unsubscribe:(NSString *) streamName {

    R5SubscriberStream *stream = (R5SubscriberStream *)[_streamMap objectForKey:streamName];
    if (stream != NULL) {
        [stream stop];
        R5VideoViewController *controller = [stream getView];
        if (controller != NULL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller.view removeFromSuperview];
                [controller removeFromParentViewController];
            });
        }
        [_streamMap removeObjectForKey:streamName];
    }

}

- (void)publish:(NSString *)streamName
       withHost:(NSString *)host
     andContext:(NSString *)context
   andWithVideo:(BOOL)withVideo
 andCameraWidth:(int)width
andCameraHeight:(int)height
        andMode:(int)publishMode {

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
        [ctrl showPreview:YES];
        [ctrl showDebugInfo:_showDebugInfo];
        [ctrl setView:self];
        [ctrl setFrame:self.frame];
        [self layoutSubviews];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onConfigured) {
            self.onConfigured(@{@"key": streamName});
        }
    });

    [self onDeviceOrientation:NULL];

}

- (void)unpublish:(NSString *)streamName {

    R5PublisherStream *stream = (R5PublisherStream *)[_streamMap objectForKey:streamName];
    if (stream != NULL) {
        [stream stop];
        [_streamMap removeObjectForKey:streamName];
    }

}

- (void)updateScaleSize:(NSString *)streamName
              withWidth:(int)width
             andHeight:(int)height
        andScreenWidth:(int)screenWidth
       andScreenHeight:(int)screenHeight {

    for (id key in _streamMap) {
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
        R5VideoViewController *controller = [stream getView];
        if (controller != NULL) {
            CGRect b = self.frame;
            [controller setFrame:CGRectMake(0.0, 0.0, b.size.width, b.size.height)];
        }
    }

    /*
    if (_playbackVideo) {
        float xscale = (width*1.0f) / (screenWidth*1.0f);
        float yscale = (height*1.0f) / (screenHeight*1.0f);
        int dwidth = [[UIScreen mainScreen] bounds].size.width;
        int dheight = [[UIScreen mainScreen] bounds].size.height;

        NSLog(@"R5VideoView:: dims(%d, %d), in(%d, %d)", width, height, screenWidth, screenHeight);
        NSLog(@"R5VideoView:: scale(%f, %f), screen(%d, %d)", xscale, yscale, dwidth, dheight);
        [self.controller setFrame:CGRectMake(0.0, 0.0, dwidth * xscale, dheight * yscale)];
    }
     */

}

- (void)swapCamera:(NSString *)streamName {

    R5PublisherStream *stream = (R5PublisherStream *)[_streamMap objectForKey:streamName];
    if (stream != NULL) {
        [stream swapCamera];
    }

}

- (void)shutdown {

    for (id key in _streamMap) {
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
        [stream stop];
    }
    [_streamMap removeAllObjects];

}

- (void)setPermissionsFlag:(BOOL)flag {

}

#pragma NSNotificationDelegate
- (void)onDeviceOrientation:(NSNotification *)notification {

    for (id key in _streamMap) {
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
        R5PublisherStream *publisher = (R5PublisherStream *)stream;
        if (publisher != NULL) {
            [publisher setDeviceOrientation:[UIDevice currentDevice].orientation];
        }
    }

}

- (void)layoutSubviews {

    [super layoutSubviews];
    for (id key in _streamMap) {
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
        R5VideoViewController *controller = [stream getView];
        if (controller != NULL) {
            CGRect b = self.frame;
            [controller setFrame:CGRectMake(0.0, 0.0, b.size.width, b.size.height)];
        }
    }

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
    for (id key in _streamMap) {
        id<Stream> stream = (id<Stream>)[_streamMap objectForKey:key];
        R5VideoViewController *controller = [stream getView];
        if (controller != NULL) {
            [controller showDebugInfo:show];
        }
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
