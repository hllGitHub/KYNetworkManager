//
//  KYNetworkConfig.m
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import "KYNetworkConfig.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@implementation KYNetworkConfig

+ (KYNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseUrl = @"";
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _debugLogEnabled = NO;
        _requestSerializer = KYRequestSerializerHTTP;
        _responseSerializer = KYResponseSerializerJSON;
        _timeoutInterval = 30;
        _openNetworkActivityIndicator = YES;
    }
    return self;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl];
}


@end
