//
//  R5MultiStreamViewManager.m
//  React Native Red5Pro
//
//  Created by Todd Anderson on 03/30/18.
//  Copyright © 2017 Infrared5, Inc. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <R5Streaming/R5Streaming.h>

#import "R5MultiStreamView.h"
#import "R5MultiStreamViewManager.h"

@interface R5MultiStreamViewManager() {

  R5MultiStreamView *r5View;

}
@end

@implementation R5MultiStreamViewManager

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (instancetype)init {
    self = [super init];
    if ( self ) {
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (r5View != NULL) {
//        [r5View willPause];
    }
//    [self dispatchAppEventWithName:@"ApplicationDidEnterBackground" body:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self dispatchAppEventWithName:@"ApplicationWillEnterBackground" body:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self dispatchAppEventWithName:@"ApplicationDidFinishLaunching" body:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (r5View != NULL) {
        [r5View willResume];
    }
//    [self dispatchAppEventWithName:@"ApplicationDidBecomeActive" body:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    if (r5View != NULL) {
        [r5View willPause];
    }
//    [self dispatchAppEventWithName:@"ApplicationWillResignActive" body:nil];
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification {
    [self dispatchAppEventWithName:@"ApplicationDidReceiveMemoryWarning" body:nil];
}

- (void)dispatchAppEventWithName:(NSString *)name body:(NSDictionary *)body {
//    [self.bridge.eventDispatcher sendAppEventWithName:name body:body];
}

# pragma RN Events
RCT_EXPORT_VIEW_PROPERTY(onConfigured, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMetaDataEvent, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPublisherStreamStatus, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSubscriberStreamStatus, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onUnpublishNotification, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onUnsubscribeNotification, RCTBubblingEventBlock)


# pragma RN Methods
RCT_EXPORT_METHOD(subscribe:(nonnull NSString *)streamName
                  withHost:(NSString *)host
                  andContext:(NSString*)context
                  andWithVideo:(BOOL)withVideo
                  andAudioMode:(int)audioMode) {

    [r5View subscribe:streamName
             withHost:host
           andContext:context
         andWithVideo:withVideo
         andAudioMode:audioMode];

}

RCT_EXPORT_METHOD(unsubscribe:(nonnull NSString*)streamName) {
    [r5View unsubscribe:streamName];
}

RCT_EXPORT_METHOD(publish:(nonnull NSString *)streamName
                  withHost:(NSString *)host
                  andContext:(NSString*)context
                  andWithVideo:(BOOL)withVideo
                  andCameraWidth:(int)width
                  andCameraHeight:(int)height
                  andMode:(int)publishMode) {

    [r5View publish:streamName
           withHost:host
         andContext:context
       andWithVideo:withVideo
     andCameraWidth:width
    andCameraHeight:height
            andMode:publishMode];

}

RCT_EXPORT_METHOD(unpublish:(nonnull NSString *)streamName) {
    [r5View unpublish:streamName];
}

RCT_EXPORT_METHOD(swapCamera:(nonnull NSString *)streamName) {
    [r5View swapCamera:streamName];
}

RCT_EXPORT_METHOD(updateScaleSize:(nonnull NSString *)streamName
                  withWidth:(int)width
                  andHeight:(int)height
                  andScreenWidth:(int)screenWidth
                  andScreenHeight:(int)screenHeight) {

    [r5View updateScaleSize:streamName
                  withWidth:width
                  andHeight:height
             andScreenWidth:screenWidth
            andScreenHeight:screenHeight];

}

RCT_EXPORT_METHOD(setPermissionsFlag:(BOOL)flag) {
    [r5View setPermissionsFlag:flag];
}

RCT_EXPORT_METHOD(shutdown) {
    [r5View shutdown];
}

# pragma RN Properties
RCT_EXPORT_VIEW_PROPERTY(logLevel, int);
RCT_EXPORT_VIEW_PROPERTY(licenseKey, NSString);
RCT_EXPORT_VIEW_PROPERTY(bundleID, NSString);
RCT_EXPORT_VIEW_PROPERTY(bitrate, int);
RCT_EXPORT_VIEW_PROPERTY(framerate, int);
RCT_EXPORT_VIEW_PROPERTY(bufferTime, float);
RCT_EXPORT_VIEW_PROPERTY(streamBufferTime, float);
RCT_EXPORT_VIEW_PROPERTY(useAdaptiveBitrateController, BOOL);

RCT_CUSTOM_VIEW_PROPERTY(showDebugView, BOOL, R5MultiStreamView) {
    [r5View setShowDebugInfo:[json boolValue]];
}

- (void)onDeviceOrientation:(NSNotification *)notification {
    [r5View onDeviceOrientation:notification];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (UIView *)view {
  r5View = [[R5MultiStreamView alloc] init];

  [self addObservers];

  return r5View;
}

@end
