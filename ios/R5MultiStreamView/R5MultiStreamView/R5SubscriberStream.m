//
//  R5SubscriberStream.m
//
//  Created by Todd Anderson on 4/3/18.
//  Copyright © 2018 Red5Pro. All rights reserved.
//

#import <R5Streaming/R5Streaming.h>
#import "R5SubscriberStream.h"

@interface R5SubscriberStream() {

    R5Stream *_stream;
    R5Connection *_connection;
    R5Configuration *_configuration;

    NSString *_streamName;
    R5VideoViewController *_view;
    id<EventEmitterProxy> _proxy;

    BOOL _isStreaming;
    int _currentRotation;

    BOOL _isActive;
    BOOL _isRetry;
    int _retryCount;
    int _retryLimit;

}
@end

@implementation R5SubscriberStream

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
    _isStreaming = NO;

}

- (void)setConfiguration:(R5Configuration *)configuration {

    _retryLimit = 3;
    _streamName = configuration.streamName;

    _configuration = configuration;
    R5Connection *connection = [[R5Connection alloc] initWithConfig:_configuration];
    R5Stream *stream = [[R5Stream alloc] initWithConnection:connection];

    [stream setClient:self];
    [stream setDelegate:self];

    if (_view != NULL) {
        [_view attachStream:stream];
//        [_view showPreview:YES];
    }

    _stream = stream;
    _connection = connection;
    _isActive = YES;

}

# pragma Stream
- (void)start {

    if (_view != NULL) {
        [_view setScaleMode:r5_scale_fill];
    }
    [_stream setAudioController:[[R5AudioController alloc] init]];
    [_stream play:_streamName];

}

- (void)stop {

    if (_stream != NULL) {

        if (_view != NULL) {
            [_view pauseRender];
            [_view.view removeFromSuperview];
            [_view removeFromParentViewController];
            _view = NULL;
        }

        [_stream stop];
        _stream = NULL;
    }
    else {
        [_proxy onStreamUnsubscribeNotification:_streamName andMessage:@{}];
        [self cleanUp];
    }

}

- (void)pause {

    if (_stream != NULL) {

        [_stream setDelegate:NULL];
        [_stream setClient:NULL];
        [_stream stop];
        _stream = NULL;

    }

}

- (void)resume {

    [self setConfiguration:_configuration];
    [self start];

}

- (void)detach {
    if (_view != NULL) {
        [_view pauseRender];
    }
}

- (void)reattach {
    if (_stream != NULL && _view != NULL) {
        [_view resumeRender];
    }
}

- (void)updateOrientation:(int)value {

    if (_currentRotation == value) {
        return;
    }
    _currentRotation = value;
    if (_view != NULL) {
        [_view.view.layer setTransform:CATransform3DMakeRotation(value, 0.0, 0.0, 0.0)];
    }

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
            [self updateOrientation:[[keyValue objectAtIndex:1] intValue]];
        }
    }

    [_proxy onStreamMetaDataEvent:_streamName andMessage:@{
                                                           @"metadata": params,
                                                           @"streamName": _streamName
                                                           }];

}

# pragma R5StreamDelegate
- (void)onR5StreamStatus:(R5Stream *)stream withStatus:(int) statusCode withMessage:(NSString*)msg {

    if (statusCode == r5_status_start_streaming) {
        _isStreaming = YES;
    }
    else if (statusCode == r5_status_connection_error && [msg isEqualToString:@"No Valid Media Found"]) {
        if (_retryCount++ < _retryLimit) {
            _isRetry = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (_isActive) {
                    [self resume];
                }
            });
            return;
        }
        else {
            _isActive = NO;
            _isRetry = NO;
        }
    }
    else if (statusCode == r5_status_disconnected && _isStreaming && !_isRetry) {
        [_proxy onStreamUnsubscribeNotification:_streamName andMessage:@{}];
        _isStreaming = false;
    }
    else if (statusCode == r5_status_connection_close && _isRetry) {
        // still retrying...
        return;
    }
    else if (statusCode == r5_status_netstatus && [msg isEqualToString:@"NetStream.Play.StreamDry"]) {
        [self stop];
        return;
    }

    NSDictionary *dict = @{
                           @"streamName": _streamName,
                           @"status": @{
                                   @"code": @(statusCode),
                                   @"message": msg,
                                   @"name": @(r5_string_for_status(statusCode)),
                                   @"streamName": _streamName
                                   }
                           };
    [_proxy onStreamSubscriberStatus:_streamName andMessage:dict];

}

@end
