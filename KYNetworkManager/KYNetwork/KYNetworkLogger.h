//
//  KYNetworkLogger.h
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KYNetworkLogger : NSObject

/**
 打印消息

 @param message 消息
 */
+ (void)logInfo:(NSString *)message;

/**
 打印消息，带标签的

 @param message 消息
 @param label 标签
 */
+ (void)logInfo:(NSString *)message label:(NSString *)label;

/**
 打印请求调试信息

 @param type 请求类型，GET/POST/PUT/DELETE
 @param path 请求路径
 @param requestParams 请求参数
 */
+ (void)logDebugInfoWithRequestType:(NSString *)type path:(NSString *)path params:(id)requestParams;

/**
 打印请求结果

 @param responseObject 请求结果
 */
+ (void)logResponse:(id)responseObject;

/**
 打印错误信息

 @param message 错误信息
 */
+ (void)logErrorMessage:(NSString *)message;

/**
 打印错误

 @param error 错误
 */
+ (void)logError:(NSError *)error;
@end
