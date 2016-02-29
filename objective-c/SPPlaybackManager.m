//
//  SPPlaybackManager.m
//  spotify
//
//  Created by Oleksii Pylko on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SPPlaybackManager.h"
#import "SPCircularBuffer.h"
#import "SPSession.h"

#define CHECK_ERROR( status )\
    if( noErr != status )\
    {\
        NSError * error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];\
        NSLog( @"Error: %@", [error description] );\
        return status;\
    }

@interface SPPlaybackManager ()

-(BOOL) setupAudioSession;
-(BOOL) cleanupAudioSession;

-(OSStatus) setupAudioCore:(const sp_audioformat*)audioFormat;
-(OSStatus) cleanupAudioCore;

-(OSStatus) setupAUGraph:(const sp_audioformat*)audioFormat;
-(OSStatus) cleanupAUGraph;
-(BOOL) isAUGraphInitialized;

-(OSStatus) fillAUGraph;
-(OSStatus) configureAudioUnits:(const sp_audioformat*)audioFormat;

-(OSStatus) startAUGraph;
-(OSStatus) stopAUGraph;

-(OSStatus) setupStreamFormat:(const sp_audioformat*)audioFormat;
-(OSStatus) setupRenderCallback;
-(OSStatus) setupNumberOfInputBuses;
-(OSStatus) setupMixerVolume:(float)vol;
-(OSStatus) setupMaximumFramesPerSlice;

-(void) trackPositionUpdate:(UInt32)numFrames;

@end


@implementation SPPlaybackManager

@synthesize buffer;
@synthesize volume;
@synthesize session;
@synthesize playing;
@synthesize position;

static SPPlaybackManager * gPlaybackManager = nil;
static UInt32 numberFrames = 0;

static OSStatus playbackCallback( void *                        inRefCon,
                                  AudioUnitRenderActionFlags *	ioActionFlags,
                                  const AudioTimeStamp *		inTimeStamp,
                                  UInt32						inBusNumber,
                                  UInt32						inNumberFrames,
                                  AudioBufferList *				ioData )
{
    OSStatus status = noErr;
    
    SPPlaybackManager * self = inRefCon;
    numberFrames = inNumberFrames;
    
    AudioBuffer * audioBuffer = & ( ioData->mBuffers[0] );
    UInt32 audioBufferSize = audioBuffer->mDataByteSize;
    
    NSUInteger availableBytesLength = [[self buffer] length];
    if( availableBytesLength < audioBufferSize )
    {
        audioBuffer->mDataByteSize = 0;
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
        return noErr;
    }
    
    audioBuffer->mDataByteSize = [ [self buffer] readDataOfLength:audioBufferSize intoAllocatedBuffer:&audioBuffer->mData];
        
    [self->trackPositionInvocation setArgument:(void*)&numberFrames atIndex:2];
    [self->trackPositionInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    return status;
}


-(void) setSession:(SPSession *)aSession;
{
    session = aSession;
    [session setPlaybackDelegate:self];
}

+(void) initialize;
{
    if( nil == gPlaybackManager )
    {
        gPlaybackManager = [[SPPlaybackManager alloc] init];
    }
}

+(SPPlaybackManager*) sharedPlaybackManager
{
    return gPlaybackManager;
}

-(id) initWithSPSession:(SPSession*)aSession
{
    session = aSession;
    return [self init];
}

-(id) init;
{
    self = [super init];
    if (self) 
    {
        buffer = [[SPCircularBuffer alloc] init];
        playing = FALSE;
        position = 0.0;
        volume = 1.0;
        SEL trackPositionSelector = @selector(trackPositionUpdate:);
        trackPositionSignature = [[SPPlaybackManager instanceMethodSignatureForSelector:trackPositionSelector] retain];
        trackPositionInvocation = [[NSInvocation invocationWithMethodSignature:trackPositionSignature] retain];
        [trackPositionInvocation setTarget:self];
        [trackPositionInvocation setSelector:trackPositionSelector];
    }
    return self;
}

-(void) trackPositionUpdate:(UInt32)numFrames
{
    @synchronized(self)
    {
        if( 0.0 == position )
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCRRadioPlayerPlaybackChangedNotificationName 
                                                                object:self];
        }
        position += (double)( numFrames * 1000 / 44100.0 );
        //NSLog( @"position %f", position );
    }
}

-(void) dealloc;
{
    [self cleanupAudioCore];
    session = nil;
    [buffer dealloc];
    [trackPositionInvocation release];
    [trackPositionSignature release];
    [super dealloc];
}

-(void) setVolume:(float)vol;
{
    [self setupMixerVolume:vol];
    volume = vol;
}

-(void) playTrack:(SPTrack*)track
{
    position = 0.0;
    [buffer clear];
    [session load:track];
    [self play];
}

-(void) play;
{
    [session play];
    [self startAUGraph];
    playing = TRUE;
}

-(void) pause;
{
    [session stop];
    [self stopAUGraph];
    playing = FALSE;
}

-(void) forward:(NSTimeInterval)offset;
{
    self.position += offset;
}

-(void) backward:(NSTimeInterval)offset;
{
    self.position -= offset;
}

-(void) setPosition:(NSTimeInterval)newPosition;
{	
    NSLog( @"position %f, set new position %f", (double)position, newPosition );
    if( [session seek:newPosition] )
    {
        position = newPosition;
    }
}

-(void) stop;
{
    [self pause];
    [buffer clear];
    [self cleanupAudioCore];
}

#pragma mark -
#pragma mark SPPlaybackDelegate

-(void) endOfTrack;
{
    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCRRadioPlayerPlaybackChangedNotificationName 
                                                        object:self];
}

-(void) playTokenLost;
{
    [self pause];
}

-(int) deliveryAudioFrames:(const void*)frames ofCount:(int)countOfFrames inFormat:(const sp_audioformat*)audioFormat;
{
    if( 0 == countOfFrames )
    {
        [buffer clear];
        return 0;
    }
    
    if( !( [self isAUGraphInitialized] ) )
    {
        if( !( [self setupAudioCore:audioFormat] ) )
        {
            return 0;
        }
    }
    
    NSUInteger dataSize = sizeof( SInt16 ) * countOfFrames * audioFormat->channels;
    if( ( buffer.maximumLength - buffer.length ) < dataSize )
    {
        return 0;
    }
    
    [buffer attemptAppendData:frames ofLength:dataSize];
    
    return countOfFrames;
}

#pragma mark -
#pragma mark private methods

-(OSStatus) setupMixerVolume:(float)vol;
{
    OSStatus status = noErr;
    if ( NULL != mixerUnit )
    {
        NSLog( @"SET VOLUME %f", vol );
        
        status = AudioUnitSetParameter( mixerUnit,
                                        kMultiChannelMixerParam_Volume,
                                        kAudioUnitScope_Output,
                                        0,
                                        vol,
                                        sizeof( vol ) );
        CHECK_ERROR( status );
    }
    return status;
}

-(OSStatus) setupAudioCore:(const sp_audioformat*)audioFormat;
{
    OSStatus status = noErr;
    
    if( [self setupAudioSession] )
    {
        status = [self setupAUGraph:audioFormat];
        CHECK_ERROR( status );

        status = [self startAUGraph];
        CHECK_ERROR( status );
    }
    
    return status;
}

-(OSStatus) cleanupAudioCore;
{
    OSStatus status = noErr;
    
    if( [self cleanupAudioSession] )
    {
        status = [self stopAUGraph];
        CHECK_ERROR( status );
        
        status = [self cleanupAUGraph];
        CHECK_ERROR( status );
    }
    
    return status;
}

-(BOOL) setupAudioSession;
{
    NSError * error = nil;
    BOOL success = TRUE;
    
    success &= [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    success &= [[AVAudioSession sharedInstance] setActive:TRUE error:&error];
    
    return success;
}


-(BOOL) cleanupAudioSession;
{
    NSError * error = nil;
    
    BOOL success = [[AVAudioSession sharedInstance] setActive:FALSE error:&error];
    
    return success;
}

-(OSStatus) setupAUGraph:(const sp_audioformat*)audioFormat;
{
    OSStatus status = noErr;
    
    status = NewAUGraph( & outGraph );
    CHECK_ERROR( status );
    
    status = AUGraphOpen( outGraph );
    CHECK_ERROR( status );
    
    status = [self fillAUGraph];
    CHECK_ERROR( status );
    
    [self configureAudioUnits:audioFormat];
    CHECK_ERROR( status );
    
    status = AUGraphInitialize( outGraph );    
    CHECK_ERROR( status );
    
    return status;
}

-(BOOL) isAUGraphInitialized;
{
    Boolean outIsInitialized = 0;
    
    if( NULL != outGraph )
    {
        OSStatus status = AUGraphIsInitialized( outGraph, & outIsInitialized );
        CHECK_ERROR( status );
    }
    
    return outIsInitialized;
}


-(OSStatus) cleanupAUGraph;
{
    OSStatus status = noErr;
    
    status = [self stopAUGraph];
    CHECK_ERROR( status );
    
    status = AUGraphUninitialize( outGraph );
    CHECK_ERROR( status );

    status = AUGraphClose( outGraph );
    CHECK_ERROR( status );
    
    status = DisposeAUGraph( outGraph );
    CHECK_ERROR( status );
    
    ioUnit = mixerUnit = NULL;
    outGraph = NULL;
    
    return status;
}

-(OSStatus) fillAUGraph;
{
    OSStatus status = noErr;
    AUNode ioNode, mixerNode;
    AudioComponentDescription ioDesc = { 0 }; 
    AudioComponentDescription mixerDesc = { 0 }; 
    
    // Add IO Node
    
    ioDesc.componentType = kAudioUnitType_Output;
    ioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDesc.componentFlags = 0;
    ioDesc.componentFlagsMask = 0;
    
    status = AUGraphAddNode( outGraph, & ioDesc, & ioNode );
    CHECK_ERROR( status );
    
    status = AUGraphNodeInfo( outGraph, ioNode, NULL, & ioUnit );
    CHECK_ERROR( status );
    
    // Add Mixer Node
    
    mixerDesc.componentType = kAudioUnitType_Mixer;
    mixerDesc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerDesc.componentFlags = 0;
    mixerDesc.componentFlagsMask = 0;
    
    status = AUGraphAddNode( outGraph, & mixerDesc, & mixerNode );
    CHECK_ERROR( status );
    
    status = AUGraphNodeInfo( outGraph, mixerNode, NULL, & mixerUnit );
    CHECK_ERROR( status );

    // Connect Mixer & IO nodes
    
    status = AUGraphConnectNodeInput( outGraph, mixerNode, 0, ioNode, 0 );
    CHECK_ERROR( status );
    
    return status;
}

-(OSStatus) configureAudioUnits:(const sp_audioformat*)audioFormat;
{
    OSStatus status = noErr;
    
    status = [self setupRenderCallback];
    CHECK_ERROR( status );
    
    status = [self setupStreamFormat:audioFormat];
    CHECK_ERROR( status );
    
    status = [self setupNumberOfInputBuses];
    CHECK_ERROR( status );
    
    status = [self setupMaximumFramesPerSlice];
    CHECK_ERROR( status );
    
    return status;
}


-(OSStatus) startAUGraph;
{
    OSStatus status = noErr;
    
    if( NULL != outGraph )
    {
        status = [self setupMixerVolume:volume];
        CHECK_ERROR( status );
        
        status = AUGraphStart( outGraph );
        CHECK_ERROR( status );
    }
    
    return status;
}

-(OSStatus) stopAUGraph;
{
    OSStatus status = noErr;

    if( NULL != outGraph )
    {
        status = AUGraphStop( outGraph );
        CHECK_ERROR( status );
    }
    
    return status;
}

-(OSStatus) setupStreamFormat:(const sp_audioformat*)audioFormat;
{
    OSStatus status = noErr;
    
    AudioStreamBasicDescription streamFormatStruct = { 0 };
    
    streamFormatStruct.mSampleRate = (float) audioFormat->sample_rate;
    streamFormatStruct.mFormatID = kAudioFormatLinearPCM;
    streamFormatStruct.mFormatFlags = ( kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagsNativeEndian );
    streamFormatStruct.mBytesPerPacket = ( sizeof( SInt16 ) * audioFormat->channels );
    streamFormatStruct.mFramesPerPacket = 1;
    streamFormatStruct.mBytesPerFrame = streamFormatStruct.mBytesPerPacket;
    streamFormatStruct.mChannelsPerFrame = audioFormat->channels;
    streamFormatStruct.mBitsPerChannel = 16;
    streamFormatStruct.mReserved = 0;
    
    /*status = AudioUnitSetProperty( ioUnit, 
                                  kAudioUnitProperty_StreamFormat, 
                                  kAudioUnitScope_Input, 
                                  0, 
                                  & streamFormatStruct, 
                                  sizeof( streamFormatStruct ) );
    CHECK_ERROR( status );*/
    
    status = AudioUnitSetProperty( mixerUnit, 
                                  kAudioUnitProperty_StreamFormat, 
                                  kAudioUnitScope_Input, 
                                  0, 
                                  & streamFormatStruct, 
                                  sizeof( streamFormatStruct ) );
    CHECK_ERROR( status );
    
    /*status = AudioUnitSetProperty( mixerUnit, 
                                  kAudioUnitProperty_StreamFormat, 
                                  kAudioUnitScope_Output, 
                                  0, 
                                  & streamFormatStruct, 
                                  sizeof( streamFormatStruct ) );
    CHECK_ERROR( status );*/
    
    return status;
}

-(OSStatus) setupMaximumFramesPerSlice;
{
    OSStatus status = noErr;    
    UInt32 maximumFramesPerSlice = 4096;
    
    status = AudioUnitSetProperty ( mixerUnit,
                          kAudioUnitProperty_MaximumFramesPerSlice,
                          kAudioUnitScope_Global,
                          0,
                          & maximumFramesPerSlice,
                          sizeof ( maximumFramesPerSlice ) );

    return status;
}


-(OSStatus) setupRenderCallback;
{
    OSStatus status = noErr;
    
    AURenderCallbackStruct callbackStruct = { 0 };
    
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty( mixerUnit, 
                                  kAudioUnitProperty_SetRenderCallback, 
                                  kAudioUnitScope_Input, 
                                  0,
                                  & callbackStruct,
                                  sizeof( callbackStruct ) );
    return status;
}

-(OSStatus) setupNumberOfInputBuses;    
{
    OSStatus status = noErr;

    UInt32 numBuses = 1;

    status = AudioUnitSetProperty( mixerUnit, 
                                  kAudioUnitProperty_ElementCount, 
                                  kAudioUnitScope_Input, 
                                  0, 
                                  & numBuses, 
                                  sizeof( numBuses ) );

    return status;
}

@end
