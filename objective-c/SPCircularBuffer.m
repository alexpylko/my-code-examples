//
//  SPCircularBuffer.m
//  spotify
//
//  Created by Oleksii Pylko on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SPCircularBuffer.h"

static NSUInteger kMaxCircularBufferSize = 44100 * 2 * 2 * 0.5;

@implementation SPCircularBuffer

@synthesize maximumLength;

-(id) init 
{
    return [self initWithMaximumLength:kMaxCircularBufferSize];
}

-(id) initWithMaximumLength:(NSUInteger)size 
{
	self = [super init];
    if ( self ) 
    {
		buffer = malloc(size);
		maximumLength = size;
		[self clear];
    }
    
    return self;
}

-(void)clear 
{
	@synchronized( buffer ) 
    {
		memset( buffer, 0, maximumLength );
		dataStartOffset = 0;
		dataEndOffset = 0;
		empty = YES;
	}
}

-(NSUInteger) attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength;
{
    NSUInteger availableBufferSpace = self.maximumLength - self.length;
	@synchronized( buffer )
    {
		if ( availableBufferSpace == 0 )
			return 0;
		
		NSUInteger writableByteCount = MIN( dataLength, availableBufferSpace );
		NSUInteger directCopyByteCount = MIN( writableByteCount, self.maximumLength - ( dataEndOffset + 1 ) );
		NSUInteger wraparoundByteCount = writableByteCount - directCopyByteCount;
		
		if ( directCopyByteCount > 0 )
        {
			void *writePtr = buffer + (empty ? 0 : dataEndOffset + 1);
			memcpy( writePtr, data, directCopyByteCount );
			dataEndOffset += (empty ? directCopyByteCount - 1 : directCopyByteCount);
		}
		
		if ( wraparoundByteCount > 0 ) 
        {
			memcpy( buffer, data + directCopyByteCount, wraparoundByteCount );
			dataEndOffset = wraparoundByteCount - 1;
		}
		
		if ( writableByteCount > 0 )
			empty = NO;
		
		return writableByteCount;
	}
}

-(NSUInteger) readDataOfLength:(NSUInteger)desiredLength intoAllocatedBuffer:(void **)outBuffer;
{
	
	if (outBuffer == NULL || desiredLength == 0)
		return 0;
	
    NSUInteger usedBufferSpace = self.length;
    
	@synchronized( buffer ) 
    {
		if ( usedBufferSpace == 0 ) 
        {
			return 0;
		}
		
		NSUInteger readableByteCount = MIN( usedBufferSpace, desiredLength );
		NSUInteger directCopyByteCount = MIN( readableByteCount, self.maximumLength - dataStartOffset );
		NSUInteger wraparoundByteCount = readableByteCount - directCopyByteCount;
		
		void *destinationBuffer = *outBuffer;
		
		if ( directCopyByteCount > 0 )
        {
			memcpy(destinationBuffer, buffer + dataStartOffset, directCopyByteCount);
			dataStartOffset += directCopyByteCount;
		}
		
		if ( wraparoundByteCount > 0 )
        {
			memcpy(destinationBuffer + directCopyByteCount, buffer, wraparoundByteCount);
			dataStartOffset = wraparoundByteCount;
		}
		
		return readableByteCount;
	}
}

-(NSUInteger) length 
{
	@synchronized( buffer ) 
    {
		if ( dataStartOffset == dataEndOffset ) 
        {
			return 0;
		} 
        else if ( dataEndOffset > dataStartOffset ) 
        {
			return dataEndOffset - dataStartOffset;
		}
        else 
        {
			return ( maximumLength - dataStartOffset ) + dataEndOffset;
		}
	}
}

-(void) dealloc 
{
	@synchronized( buffer ) 
    {
		memset( buffer, 0, maximumLength );
		free( buffer );
		[super dealloc];
	}
}

@end
