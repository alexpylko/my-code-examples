//
//  SPPlaybackManager.h
//  spotify
//
//  Created by Oleksii Pylko on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import <libspotify/api.h>

#import "SPPlaybackDelegate.h"

@class SPSession;
@class SPCircularBuffer;
@class SPTrack;

@interface SPPlaybackManager : NSObject<SPPlaybackDelegate>
{
    BOOL playing;
    SPSession * session;
    AUGraph outGraph;
    AudioUnit ioUnit;
    AudioUnit mixerUnit;
    NSMethodSignature * trackPositionSignature;
    NSInvocation * trackPositionInvocation;
}

@property (readonly) SPCircularBuffer * buffer;
@property (nonatomic, retain) SPSession * session;
@property (nonatomic) NSTimeInterval position;

@property (nonatomic) float volume;
@property (nonatomic, readonly) BOOL playing;

+(SPPlaybackManager*) sharedPlaybackManager;

-(id)initWithSPSession:(SPSession*)aSession;

-(void) playTrack:(SPTrack*)track;
-(void) play;
-(void) pause;
-(void) stop;
-(void) forward:(NSTimeInterval)offset;
-(void) backward:(NSTimeInterval)offset;

@end
