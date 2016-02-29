//
//  JORemoteConnection.h
//  JokeOff
//
//  Created by Alex Pylko on 1/9/12.
//  Copyright (c) 2012 alexpylko@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JOURLRequestDelegate <NSObject>

@optional

-(void)didReceiveData:(id)responseData onURLRequest:(NSURLRequest*) request;

-(void)didFailWithError:(NSError*)error onURLRequest:(NSURLRequest*)request;

@end


@interface JOURLRequest : NSObject <JOURLRequestDelegate>

-(id)initWithURLRequest:(NSURLRequest*)request delegate:(id)delegateObject;

+(id)requestWithURLRequest:(NSURLRequest*)request delegate:(id)delegateObject;

@property (nonatomic, retain) id delegate;

@end
