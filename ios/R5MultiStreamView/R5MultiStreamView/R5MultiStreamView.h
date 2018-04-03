//
//  R5MultiStreamView.h
//  React Native Red5 Pro
//
//  Created by Todd Anderson on 03/30/18.
//  Copyright © 2017 Infrared5, Inc. All rights reserved.
//

#ifndef R5MultiStreamView_h
#define R5MultiStreamView_h

#import <UIKit/UIKit.h>
#import <React/RCTView.h>
#import <React/RCTComponent.h>
#import <React/RCTBridgeModule.h>
#import <R5Streaming/R5Streaming.h>

@protocol Stream;
@protocol EventEmitterProxy;

@protocol Stream <NSObject>

- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)updateScaleSize:(int)width withHeight:(int)height andScreenWidth:(int)screenWidth andScreenHeight:(int)screenHeight;
- (int)getLogLevel;
- (void)setLogLevel:(int)value;
- (R5VideoViewController *)getView;

@end

@protocol EventEmitterProxy <NSObject>

- (void)onStreamMetaDataEvent:(NSString *)streamName andMessage:(NSDictionary *)message;
- (void)onStreamPublisherStatus:(NSString *)streamName andMessage:(NSDictionary *)message;
- (void)onStreamSubscriberStatus:(NSString *)streamName andMessage:(NSDictionary *)message;
- (void)onStreamUnpublishNotification:(NSString *)streamName andMessage:(NSDictionary *)message;
- (void)onStreamUnsubscribeNotification:(NSString *)streamName andMessage:(NSDictionary *)message;

@end

@interface R5MultiStreamView : RCTView <EventEmitterProxy>

- (void)onDeviceOrientation:(NSNotification *)notification;

# pragma RN Events
@property (nonatomic, copy) RCTBubblingEventBlock onConfigured;
@property (nonatomic, copy) RCTBubblingEventBlock onMetaDataEvent;
@property (nonatomic, copy) RCTBubblingEventBlock onPublisherStreamStatus;
@property (nonatomic, copy) RCTBubblingEventBlock onSubscriberStreamStatus;
@property (nonatomic, copy) RCTBubblingEventBlock onUnpublishNotification;
@property (nonatomic, copy) RCTBubblingEventBlock onUnsubscribeNotification;

# pragma RN Methods
- (void)subscribe:(NSString *)streamName
         withHost:(NSString *)host
       andContext:(NSString *)context
     andWithVideo:(BOOL)withVideo
     andAudioMode:(int)audioMode;

- (void)publish:(NSString *)streamName
       withHost:(NSString *)host
     andContext:(NSString *)context
   andWithVideo:(BOOL)withVideo
 andCameraWidth:(int)with
andCameraHeight:(int)height
        andMode:(int)publishMode;

- (void)unsubscribe:(NSString *)streamName;

- (void)unpublish:(NSString *)streamName;

- (void)swapCamera:(NSString *)streamName;

- (void)updateScaleMode:(NSString *)streamName
               withMode:(int)mode;

- (void)updateScaleSize:(NSString *)streamName
              withWidth:(int)width
              andHeight:(int)height
         andScreenWidth:(int)screenWidth
        andScreenHeight:(int)screenHeight;

- (void)setPermissionsFlag:(BOOL)flag;

- (void)shutdown;

# pragma RN Properties
- (BOOL)getShowDebugInfo;
- (void)setShowDebugInfo:(BOOL)show;

- (int)getLogLevel;
- (void)setLogLevel:(int)level;
@property (setter=setLogLevel:, getter=getLogLevel) int logLevel;

@end

#endif /* R5MultiStreamView_h */
