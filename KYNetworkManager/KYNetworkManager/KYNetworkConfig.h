//
//  KYNetworkConfig.h
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN;

@class AFSecurityPolicy;

typedef NS_ENUM(NSUInteger, KYRequestSerializer) {
    /** 设置请求数据为JSON格式 */
    KYRequestSerializerJSON,
    /** 设置请求数据为二进制格式 */
    KYRequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, KYResponseSerializer) {
    /** 设置响应数据为JSON格式 */
    KYResponseSerializerJSON,
    /** 设置响应数据为二进制格式 */
    KYResponseSerializerHTTP,
};

@interface KYNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (KYNetworkConfig *)sharedConfig;

/**
 base URL 所有请求的base部分
 */
@property (nonatomic, strong) NSString *baseUrl;

/**
 security设置，默认为AFNetworking的defaultPolicy
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 是否开启日志，默认关闭，NO
 */
@property (nonatomic, assign) BOOL debugLogEnabled;

/**
 用来初始化AFHttpSessionManager
 */
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

/**
 设置网络请求参数的格式，默认为二进制格式
 */
@property (nonatomic, assign) KYRequestSerializer requestSerializer;

/**
 设置服务器响应数据格式，默认为JSON格式
 */
@property (nonatomic, assign) KYResponseSerializer responseSerializer;

/**
 设置请求超时时间，默认为30s
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 是否打开网络状态转圈，默认打开，YES
 */
@property (nonatomic, assign) BOOL openNetworkActivityIndicator;

@end

NS_ASSUME_NONNULL_END
