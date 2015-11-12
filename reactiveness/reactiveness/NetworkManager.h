//
// Created by Paul Taykalo on 11/11/15.
// Copyright (c) 2015 Paul Taykalo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@class RACSignal;

typedef void (^SuccessResponse)(NSDictionary *responseDictionary);
typedef void (^FailureResponse)(NSError * error);

@interface NetworkManager : NSObject

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password success:(SuccessResponse)success failure:(FailureResponse)failure;

- (void)registerUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName success:(SuccessResponse)success failure:(FailureResponse)failure;

- (void)verifyEmail:(NSString *)email success:(SuccessResponse)success failure:(FailureResponse)failure;

- (void)logoutUserWithSuccess:(SuccessResponse)success failure:(FailureResponse)failure;

- (void)getUserInfoWithSuccess:(SuccessResponse)success failure:(FailureResponse)failure;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

@interface NetworkManager (RAC)

- (RACSignal*)loginUserWithEmail:(NSString *)email password:(NSString *)password;

- (RACSignal*)registerUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName;

- (RACSignal*)verifyEmail:(NSString *)email;

- (RACSignal*)logoutUser;

- (RACSignal*)getUserInfo;

@end

#pragma clang diagnostic pop

