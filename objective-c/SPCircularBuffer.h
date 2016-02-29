//
//  SPCircularBuffer.h
//  spotify
//
//  Created by Oleksii Pylko on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCircularBuffer : NSObject 
{
    void *buffer;
	NSUInteger maximumLength;
	NSUInteger dataStartOffset;
	NSUInteger dataEndOffset;
	BOOL empty;
}

@property (readonly) NSUInteger length;
@property (readonly) NSUInteger maximumLength;

-(id)initWithMaximumLength:(NSUInteger)size;
-(void)clear;
-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength;
-(NSUInteger)readDataOfLength:(NSUInteger)desiredLength intoAllocatedBuffer:(void **)outBuffer;

@end
