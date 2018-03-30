//
//  R5PublisherStream.m
//  R5MultStreamView
//
//  Created by Todd Anderson on 3/30/18.
//  Copyright © 2018 Red5Pro. All rights reserved.
//

#ifndef R5PublisherStream_h
#define R5PublisherStream_h

#import <R5Streaming/R5Streaming.h>
@import "R5MultiStreamView.h"

@interface R5PublisherStream: NSObject <Stream, R5StreamDelegate>
@end
