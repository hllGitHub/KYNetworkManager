//
//  KYNetworkManager.m
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import "KYNetworkManager.h"
#import <UIKit/UIKit.h>
#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>
#import <pthread/pthread.h>
#import "KYNetworkLogger.h"
#import "KYNetworkCache.h"

#define NSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]

@implementation KYNetworkManager {
    BOOL _isOpenLog;     // 是否已开启日志打印
    NSMutableArray *_allSessionTask;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
    
    KYNetworkConfig *_config;
    AFHTTPSessionManager *_sessionManager;
    NSString *_baseUrl;
}

+ (KYNetworkManager *)sharedManager {
    static KYNetworkManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc]init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [KYNetworkConfig sharedConfig];
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _sessionManager.securityPolicy = _config.securityPolicy;
        // 设置请求的超时时间
        _sessionManager.requestSerializer.timeoutInterval = _config.timeoutInterval;
        // 设置服务器返回结果的类型：JSON
        _sessionManager.responseSerializer = (_config.responseSerializer == KYResponseSerializerHTTP ) ? [AFHTTPResponseSerializer serializer ]: [AFJSONResponseSerializer serializer];
        _sessionManager.requestSerializer =  (_config.requestSerializer == KYRequestSerializerHTTP) ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
        
        _isOpenLog = _config.debugLogEnabled;
        _baseUrl = _config.baseUrl;
        [AFNetworkActivityIndicatorManager sharedManager].enabled = _config.openNetworkActivityIndicator;
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(KYNetworkStatusBlock)networkStatusBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    networkStatusBlock ? networkStatusBlock(KYNetworkStatusUnKnown) : nil;
                    [KYNetworkLogger logInfo:@"未知网络"];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    networkStatusBlock ? networkStatusBlock(KYNetworkStatusNotReachable) : nil;
                    [KYNetworkLogger logInfo:@"无网络"];
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    networkStatusBlock ? networkStatusBlock(KYNetworkStatusReachableViaWWAN) : nil;
                    [KYNetworkLogger logInfo:@"手机自带网络"];
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    networkStatusBlock ? networkStatusBlock(KYNetworkStatusReachableViaWiFi) : nil;
                    [KYNetworkLogger logInfo:@"WIFI"];
                    break;
            }
        }];

    });
}

+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

- (void)openLog {
    _isOpenLog = YES;
}

- (void)closeLog {
    _isOpenLog = NO;
}

- (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

- (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

/**
 *  json转字典
 */
- (NSDictionary *)jsonToDictionary:(id)data {
    if (!data) {
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

/*
 *  json转字符串
 */
- (NSString *)jsonToString:(id)data {
    if (!data) {
        return nil;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 存储着所有的请求task数组
 */
- (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark -

- (NSString *)buildRequestUrl:(NSString *)URLString {
    NSParameterAssert(URLString != nil);
    
    NSString *detailUrl = URLString;
    NSURL *temp = [NSURL URLWithString:detailUrl];
    // 如果 detailUrl就是有效的URL
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    
    NSString *baseUrl = _baseUrl;
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

- (NSDictionary *)buildRequestParameters:(NSDictionary *)parameters {
//    NSParameterAssert(parameters != nil);
    // 这里需要根据项目定制一下，因为需要加入token之类，还有cityId
    return parameters;
}

#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 *  开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

#pragma mark - GET请求无缓存

- (__kindof NSURLSessionTask *)GET:(NSString *)URLString parameters:(NSDictionary *)parameters success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    return [[KYNetworkManager sharedManager] GET:URLString parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求有缓存

- (__kindof NSURLSessionTask *)GET:(NSString *)URLString parameters:(NSDictionary *)parameters responseCache:(KYHttpRequestCache)responseCache success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 读取缓存
    responseCache ? responseCache([KYNetworkCache httpCacheForURL:requestURLString parameters:requestParameters]) : nil;
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"GET" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager GET:requestURLString parameters:requestParameters progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        // 对数据进行异步缓存
        responseCache ? [KYNetworkCache setHttpCache:responseObject URL:requestURLString parameters:requestParameters] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        _isOpenLog ? [KYNetworkLogger logError:error] : nil;
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - POST请求无缓存

- (__kindof NSURLSessionTask *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    return [[KYNetworkManager sharedManager] POST:URLString parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求有缓存

- (__kindof NSURLSessionTask *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters responseCache:(KYHttpRequestCache)responseCache success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 读取缓存
    responseCache ? responseCache([KYNetworkCache httpCacheForURL:requestURLString parameters:requestParameters]) : nil;
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"POST" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:requestURLString parameters:requestParameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        // 对数据进行异步缓存
        responseCache ? [KYNetworkCache setHttpCache:responseObject URL:requestURLString parameters:requestParameters] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - HEAD请求无缓存

- (__kindof NSURLSessionTask *)HEAD:(NSString *)URLString parameters:(NSDictionary *)parameters success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"HEAD" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager HEAD:requestURLString parameters:requestParameters success:^(NSURLSessionDataTask * _Nonnull task) {
        // 请求成功
        [[self allSessionTask] removeObject:task];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - PUT请求

- (__kindof NSURLSessionTask *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"PUT" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager PUT:requestURLString parameters:requestParameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - DELETE

- (__kindof NSURLSessionTask *)DELETE:(NSString *)URLString parameters:(NSDictionary *)parameters success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"DELETE" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager DELETE:requestURLString parameters:requestParameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - 上传文件

- (__kindof NSURLSessionTask *)uploadFile:(NSString *)URLString parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progress:(KYHttpProgress)progress success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"UPLOADFILE" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:requestURLString parameters:requestParameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - 上传图片

- (__kindof NSURLSessionTask *)uploadImages:(NSString *)URLString parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progress:(KYHttpProgress)progress success:(KYHttpRequestSuccess)success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    NSDictionary *requestParameters = [self buildRequestParameters:parameters];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"UPLOADIMAGES" path:requestURLString params:requestParameters] : nil;
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:requestURLString parameters:requestParameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            
            // 默认图片的文件名，若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *string = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = NSStringFormat(@"%@%ld.%@", string, i, imageType ? : @"jpg");
            
            [formData appendPartWithFileData:imageData name:name fileName:fileNames ?  NSStringFormat(@"%@.%@",fileNames[i],imageType?:@"jpg") : imageFileName mimeType:NSStringFormat(@"image/%@",imageType ?: @"jpg")];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        // 上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，输出结果
        _isOpenLog ? [KYNetworkLogger logResponse:[self jsonToString:responseObject]] : nil;
        
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败，输出错误日志
        [KYNetworkLogger logError:error];
        [[self allSessionTask] removeObject:task];
        failure ? failure(error, [error localizedDescription]) : nil;
    }];
    
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
    
    return sessionTask;
}

#pragma mark - 下载文件

- (__kindof NSURLSessionTask *)download:(NSString *)URLString fileDir:(NSString *)fileDir progress:(KYHttpProgress)progress success:(void (^)(NSString *))success failure:(KYHttpRequestFailure)failure {
    // 获取完整的URL和参数
    NSString *requestURLString = [self buildRequestUrl:URLString];
    
    // 输出请求日志
    _isOpenLog ? [KYNetworkLogger logDebugInfoWithRequestType:@"DOWNLOAD" path:requestURLString params:nil] : nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURLString]];
    NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

        if (error) {
            [KYNetworkLogger logError:error];
            failure ? failure(error, [error localizedDescription]) : nil;
        } else {
            success ? success(filePath.absoluteString) : nil;
        }
    }];
    
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    
    return downloadTask;
}

@end

#pragma mark - NSDictionary, NSArray的分类
/*
 * 新建NSDictionary与NSArray的分类，控制台打印json数据中的中文
 */

#ifdef DEBUG

@implementation NSArray (KY)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (KY)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end

#endif
