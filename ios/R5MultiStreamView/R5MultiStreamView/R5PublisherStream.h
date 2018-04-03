//
//  R5PublisherStream.h
//  R5MultStreamView
//
//  Created by Todd Anderson on 4/2/18.
//  Copyright © 2018 Red5Pro. All rights reserved.
//

#ifndef R5PublisherStream_h
#define R5PublisherStream_h

#import <R5Streaming/R5Streaming.h>
#import "R5MultiStreamView.h"

@interface R5PublisherStream: NSObject <Stream, R5StreamDelegate>

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy;

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy andView:(R5VideoViewController *)view;

- (void)setConfiguration:(R5Configuration *)configuration
             andCameraWidth:(int)width
            andCameraHeight:(int)height
                 andBitrate:(float)bitrate
               andFramerate:(float)framerate
              andStreamType:(int)type
                  andUseABR:(BOOL)usABR;

- (void)swapCamera;
- (void)setDeviceOrientation:(UIDeviceOrientation)orientation;

@end

#endif /* R5PublisherStream_h */
