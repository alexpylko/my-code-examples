//
//  JORemoteConnection.m
//  JokeOff
//
//  Created by Alex Pylko on 1/9/12.
//  Copyright (c) 2012 alexpylko@gmail.com. All rights reserved.
//

#import "JOURLRequest.h"
#import "JokeOffAppDelegate.h"
#import "JSON.h"
#import "JOAPI.h"
#import "JOError.h"

@interface JOURLRequest ()
    -(void)scheduleURLRequest:(NSURLRequest*)request;
    -(void)sendURLRequest:(NSURLRequest*)request;
@end

@implementation JOURLRequest

@synthesize delegate;

+(id)requestWithURLRequest:(NSURLRequest*)request delegate:(id)delegateObject;
{
    return [[[JOURLRequest alloc] initWithURLRequest:request delegate:delegateObject] autorelease];
}

-(id)initWithURLRequest:(NSURLRequest*)request delegate:(id)delegateObject;
{
    if ( self = [super init] )
    {
        [self setDelegate:delegateObject];
        [self scheduleURLRequest:request];
    }
    return self;
}

-(void)scheduleURLRequest:(NSURLRequest*)request;
{
	JokeOffAppDelegate *queue = 
	(JokeOffAppDelegate*)[UIApplication sharedApplication].delegate;
	
	NSInvocationOperation * operation = [[NSInvocationOperation alloc] 
                                         initWithTarget:self 
                                         selector:@selector(sendURLRequest:)
                                         object:request];
	
	[queue.loadQueue addOperation:operation];
    
	[operation release];
}

-(void)sendURLRequest:(NSURLRequest*)request;
{
	NSURLResponse * response = nil;
    NSError * error = nil;
    
	NSData * responseData = [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response
                                                              error:&error];
    
    if ( nil != error )
    {
        [self didFailWithError:error onURLRequest:request];
    }
    else
    {
        [self didReceiveData:responseData onURLRequest:request];
	}
}

-(void)didReceiveData:(NSData*)responseData onURLRequest:(NSURLRequest*) request;
{
    NSError * error = nil;
    
	NSString *responseString = [[NSString alloc] initWithData:responseData 
                                                     encoding:NSUTF8StringEncoding];
    
	id jsonData = [responseString JSONValue];
    if( nil == jsonData )
    {
        error = [NSError errorWithDomain:JOJSONParsingErrorDomain 
                                    code:100 
                                userInfo:nil];
    }
    else if ( [jsonData isKindOfClass:[NSDictionary class]] )
    {
        NSDictionary * errorObj = [jsonData objectForKey:@"error"];
        if ( nil != errorObj )
        {
            error = [JOError errorWithJSONEncoder:errorObj];
        }
    }
    
    if( nil != error)
    {
        [self didFailWithError:error onURLRequest:request];
    }
    else if ( [delegate respondsToSelector:@selector(didReceiveData:onURLRequest:)] )
    {
        NSLog( @"%@", jsonData );
        [delegate didReceiveData:jsonData onURLRequest:request];
    }
    
	[responseString release];
}

-(void)didFailWithError:(NSError*)error onURLRequest:(NSURLRequest*)request;
{
    if ( [delegate respondsToSelector:@selector(didFailWithError:onURLRequest:)] ) 
    {
        [delegate didFailWithError:error onURLRequest:request];
    }    
}

@end
