//
//  R5SubscriberStream.h
//  R5MultStreamView
//
//  Created by Todd Anderson on 4/3/18.
//  Copyright © 2018 Red5Pro. All rights reserved.
//

#ifndef R5SubscriberStream_h
#define R5SubscriberStream_h

#import <R5Streaming/R5Streaming.h>
#import "R5MultiStreamView.h"

@interface R5SubscriberStream: NSObject <Stream, R5StreamDelegate>

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy;

- (id)initWithEventProxy:(id<EventEmitterProxy>)proxy andView:(R5VideoViewController *)view;

- (void)setConfiguration:(R5Configuration *)configuration;

@end

#endif /* R5SubscriberStream_h */
