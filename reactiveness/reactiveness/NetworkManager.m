//
// Created by Paul Taykalo on 11/11/15.
// Copyright (c) 2015 Paul Taykalo. All rights reserved.
//

#import <objc/runtime.h>
#import "NetworkManager.h"
#import "RACSignal.h"


@implementation NetworkManager

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password success:(SuccessResponse)success failure:(FailureResponse)failure {
    NSLog(@"%s", sel_getName(_cmd));
    [self asyncRequestWithSuccess:success failure:failure response:@{@"user" : @"user"}];
}

- (void)registerUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName success:(SuccessResponse)success failure:(FailureResponse)failure {
    [self asyncRequestWithSuccess:success failure:failure response:@{@"user" : @"user"}];
}

- (void)verifyEmail:(NSString *)email success:(SuccessResponse)success failure:(FailureResponse)failure {
    [self asyncRequestWithSuccess:success failure:failure response:@{@"email" : @"email"}];
}

- (void)logoutUserWithSuccess:(SuccessResponse)success failure:(FailureResponse)failure {
    NSLog(@"%s", sel_getName(_cmd));
    [self asyncRequestWithSuccess:success failure:failure response:@{@"success" : @"success"}];
}

- (void)getUserInfoWithSuccess:(SuccessResponse)success failure:(FailureResponse)failure {
    NSLog(@"%s", sel_getName(_cmd));
    [self asyncRequestWithSuccess:success failure:failure response:@{@"userinfo" : @"userinfo"}];
}

- (void)asyncRequestWithSuccess:(SuccessResponse)success failure:(FailureResponse)failure response:(NSDictionary *)response {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        if (arc4random() % 100 != 0) {
            if (success) {
                success(response);
            }
        } else {
            if (failure) {
                failure(nil);
            }
        }
    });
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NetworkManager (RAC)

- (void)forwardInvocation:(NSInvocation *)reactiveMethodInvocation {

    NSString *reactiveSelectorName = NSStringFromSelector([reactiveMethodInvocation selector]);
    SEL originalSelector = [self findOriginalSelectorForRACSelector:[reactiveMethodInvocation selector]];

    NSArray *paramsArray = [reactiveSelectorName componentsSeparatedByString:@":"];
    int paramsCount = [paramsArray count] - 1;

    NSInvocation *originalMethodInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:originalSelector]];
    originalMethodInvocation.target = self;
    originalMethodInvocation.selector = originalSelector;

    // Passing all params to the original method invocation
    int paramsOffset = 2;
    for (int i = 0; i < paramsCount; ++i) {
        id arg;
        [reactiveMethodInvocation getArgument:&arg atIndex:i + paramsOffset];
        [originalMethodInvocation setArgument:&arg atIndex:i + paramsOffset];
    }

    int successCallbackParamIndex = paramsOffset + paramsCount;
    int errorCallbackParamIndex = paramsOffset + paramsCount + 1;

    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        SuccessResponse successBlock = ^(id res) {
            [subscriber sendNext:res];
            [subscriber sendCompleted];
        };
        FailureResponse failureResponse = ^(NSError *error) {
            [subscriber sendError:error];
        };
        [originalMethodInvocation setArgument:&successBlock atIndex:successCallbackParamIndex];
        [originalMethodInvocation setArgument:&failureResponse atIndex:errorCallbackParamIndex];

        [originalMethodInvocation invoke];

//        id<Cancelable> cancelable;
//        [originalMethodInvocation getReturnValue:&cancelable];
//
//        return [RACDisposable disposableWithBlock:^{
//            [cancelable cancel];
//        }];
        return nil;

    }] setNameWithFormat:@"RACified %@", NSStringFromSelector(originalSelector)];

    [reactiveMethodInvocation setReturnValue:&signal];

}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {

    NSMethodSignature *superResult = [super methodSignatureForSelector:aSelector];
    if (superResult) {
        return superResult;
    }

    SEL originalSelectorForRACSelector = [self findOriginalSelectorForRACSelector:aSelector];
    if (!originalSelectorForRACSelector) {
        return nil;
    }

    NSArray *paramsArray = [NSStringFromSelector(originalSelectorForRACSelector) componentsSeparatedByString:@":"];
    int paramsCount = [paramsArray count] - 1;
    if (paramsCount == 0) {
        return [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }

    NSMutableString *obcjTypesString = [NSMutableString string];
    [obcjTypesString appendString:@"@@"];
    for (int i = 0; i < paramsCount; ++i) {
        [obcjTypesString appendString:@":@"];
    }
    return [NSMethodSignature signatureWithObjCTypes:[obcjTypesString cStringUsingEncoding:NSUTF8StringEncoding]];

}


- (SEL)findOriginalSelectorForRACSelector:(SEL)pSelector {
    NSString *selectorName = NSStringFromSelector(pSelector);

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([self class], &methodCount);
    @try {
        for (unsigned int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            SEL aSelector = method_getName(method);
            NSString *existingSelector = NSStringFromSelector(aSelector);
            if ([existingSelector hasPrefix:selectorName]) {
                return aSelector;
            }
        }
    }
    @finally {
        free(methods);
    }
    return nil;
}

@end

#pragma clang diagnostic pop