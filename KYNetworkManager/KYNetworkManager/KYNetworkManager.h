//
//  KYNetworkManager.h
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KYNetworkCache.h"
#import "KYNetworkConfig.h"


#ifndef kIsNetwork
#define kIsNetwork  [KYNetworkManager isNetwork]    // 一次性判断是否有网的宏
#endif

#ifndef kIsWWANNetwork
#define kIsWWANNetwork  [kYNetworkManager isWWANNetwork]    // 一次性判断是否为手机网络的宏
#endif

#ifndef kISWiFiNetwork
#define kISWiFiNetwork  [KYNetworkManager isWiFiNetwork];   // 一次性判断是否为wifi网络的宏
#endif

typedef NS_ENUM(NSUInteger, KYNetworkStatus) {
    /** 未知网络 */
    KYNetworkStatusUnKnown,
    /** 无网络  */
    KYNetworkStatusNotReachable,
    /** 手机网络 */
    KYNetworkStatusReachableViaWWAN,
    /** WIFI 网络 */
    KYNetworkStatusReachableViaWiFi
};


/** 请求成功的Block */
typedef void(^KYHttpRequestSuccess)(id responseObject);

/** 请求失败的Block */
typedef void(^KYHttpRequestFailure)(NSError *error, NSString *errorMessage);

/** 缓存的Block */
typedef void(^KYHttpRequestCache)(id responseCache);

/** 上传或者下载的进度， Progress.completeUnitCount:当前大小 - Progress.totalUnitCount:总大小 */
typedef void(^KYHttpProgress)(NSProgress *progress);

/** 网络状态的Block */
typedef void(^KYNetworkStatusBlock)(KYNetworkStatus status);

@interface KYNetworkManager : NSObject

+ (KYNetworkManager *)sharedManager;


/**
 有网YES， 无网NO
 */
+ (BOOL)isNetwork;

/**
 手机网络：YES，反之：NO
 */
+ (BOOL)isWWANNetwork;

/**
 WiFi网络：YES，反之：NO
 */
+ (BOOL)isWiFiNetwork;

/**
 取消所有HTTP请求
 */
- (void)cancelAllRequest;


/**
 实时获取网络状态，通过Block回调实时获取

 @param networkStatusBlock 网络状态
 */
+ (void)networkStatusWithBlock:(KYNetworkStatusBlock)networkStatusBlock;


/**
 取消指定URL的http请求

 @param URL 指定URL
 */
- (void)cancelRequestWithURL:(NSString *)URL;

#pragma mark - 网络请求部分
#pragma mark - GET
/*****************************************************************/
/****                        GET                              ****/
/*****************************************************************/

/**
 GET请求，无缓存

 @param URLString 请求地址
 @param parameters 请求参数
 @param success 请求成功回调
 @param failure 请求失败回调
 @return 返回的对象可取消请求，调用cancel方法
 */
- (__kindof NSURLSessionTask *)GET:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(KYHttpRequestSuccess)success
                           failure:(KYHttpRequestFailure)failure;

/**
 GET请求，自动缓存

 @param URLString 请求地址
 @param parameters 请求参数
 @param responseCache 缓存数据回调
 @param success 请求成功回调
 @param failure 请求失败回调
 @return 返回的对象可取消请求，调用cancel方法
 */
- (__kindof NSURLSessionTask *)GET:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                     responseCache:(KYHttpRequestCache)responseCache
                           success:(KYHttpRequestSuccess)success
                           failure:(KYHttpRequestFailure)failure;

#pragma mark - POST
/*****************************************************************/
/****                        POST                             ****/
/*****************************************************************/

/**
 POST请求，无缓存

 @param URLString 请求地址
 @param parameters 请求参数
 @param success 请求成功的回调
 @param failure 请求失败的回调
 @return 返回的对象可取消请求，调用cancel方法
 */
- (__kindof NSURLSessionTask *)POST:(NSString *)URLString
                         parameters:(NSDictionary *)parameters
                            success:(KYHttpRequestSuccess)success
                            failure:(KYHttpRequestFailure)failure;

/**
 POST请求，自动缓存

 @param URLString 请求地址
 @param parameters 请求参数
 @param responseCache 缓存数据的回调
 @param success 请求成功的回调
 @param failure 请求失败的回调
 @return 返回的对象可取消请求，调用cancel方法
 */
- (__kindof NSURLSessionTask *)POST:(NSString *)URLString
                         parameters:(NSDictionary *)parameters
                      responseCache:(KYHttpRequestCache)responseCache
                            success:(KYHttpRequestSuccess)success
                            failure:(KYHttpRequestFailure)failure;

#pragma mark - HEAD
/*****************************************************************/
/****                        HEAD                             ****/
/*****************************************************************/

/**
 HEAD请求，无缓存

 @param URLString 请求地址
 @param parameters 请求参数
 @param success 请求成功回调
 @param failure 请求失败回调
 @return 返回的对象可取消请求，调用cancel方法
 */
- (__kindof NSURLSessionTask *)HEAD:(NSString *)URLString
                         parameters:(NSDictionary *)parameters
                            success:(KYHttpRequestSuccess)success
                            failure:(KYHttpRequestFailure)failure;

#pragma mark - PUT
/*****************************************************************/
/****                         PUT                             ****/
/*****************************************************************/
- (__kindof NSURLSessionTask *)PUT:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(KYHttpRequestSuccess)success
                           failure:(KYHttpRequestFailure)failure;

#pragma mark - DELETE
/*****************************************************************/
/****                        DELETE                           ****/
/*****************************************************************/

- (__kindof NSURLSessionTask *)DELETE:(NSString *)URLString
                           parameters:(NSDictionary *)parameters
                              success:(KYHttpRequestSuccess)success
                              failure:(KYHttpRequestFailure)failure;

#pragma mark - Upload
/*****************************************************************/
/****                        Upload                           ****/
/*****************************************************************/

- (__kindof NSURLSessionTask *)uploadFile:(NSString *)URLString
                               parameters:(NSDictionary *)parameters
                                     name:(NSString *)name
                                 filePath:(NSString *)filePath
                                 progress:(KYHttpProgress)progress
                                  success:(KYHttpRequestSuccess)success
                                  failure:(KYHttpRequestFailure)failure;

- (__kindof NSURLSessionTask *)uploadImages:(NSString *)URLString
                                 parameters:(NSDictionary *)parameters
                                       name:(NSString *)name
                                     images:(NSArray<UIImage *> *)images
                                  fileNames:(NSArray<NSString *> *)fileNames
                                 imageScale:(CGFloat)imageScale
                                  imageType:(NSString *)imageType
                                   progress:(KYHttpProgress)progress
                                    success:(KYHttpRequestSuccess)success
                                    failure:(KYHttpRequestFailure)failure;

#pragma mark - Download
/*****************************************************************/
/****                        Download                         ****/
/*****************************************************************/

- (__kindof NSURLSessionTask *)download:(NSString *)URLString
                                fileDir:(NSString *)fileDir
                               progress:(KYHttpProgress)progress
                                success:(void(^)(NSString *filePath))success
                                failure:(KYHttpRequestFailure)failure;

#pragma mark - 重置AFHTTPSessionManager相关属性

/**
 *  设置请求头
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
