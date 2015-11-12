//
//  AppDelegate.m
//  reactiveness
//
//  Created by Paul Taykalo on 11/11/15.
//  Copyright © 2015 Paul Taykalo. All rights reserved.
//

#import "AppDelegate.h"
#import "NetworkManager.h"

@interface AppDelegate ()

@property(nonatomic, strong) NetworkManager *networkManager;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.networkManager = [NetworkManager new];

    [self performUltraImportantWork];
    [self performUltraImportantWorkWithPromises];
    return YES;
}

- (void)performUltraImportantWork {
    [self.networkManager loginUserWithEmail:@"email" password:@"password" success:^(NSDictionary *responseDictionary) {
        [self.networkManager getUserInfoWithSuccess:^(NSDictionary *resp2) {
            if (resp2[@"invalid"]) {
                [self.networkManager logoutUserWithSuccess:^(NSDictionary *loggedOut) {
                    [self handleSuccess:loggedOut];
                } failure:^(NSError *error) {
                    [self handleError:error];
                }];
            } else {
                [self handleSuccess:resp2];
            }
        }  failure:^(NSError *error) {
            [self handleError:error];
        }];
    } failure:^(NSError *error) {
        [self handleError:error];
    }];
}


- (void)performUltraImportantWorkWithPromises {
    // Login user
    [[[[self.networkManager loginUserWithEmail:@"email" password:@"password"]

        // Get user info
        flattenMap:^RACStream *(id value) {
            return [self.networkManager getUserInfo];
        }]

        // Logout user if invalid or return logged in user
        flattenMap:^RACStream *(NSDictionary *resp2) {
            if (resp2[@"invalid"]) {
                return [self.networkManager logoutUser];
            } else {
                return [RACSignal return:resp2];
            }
        }]

        // Handle successful result
        subscribeNext:^(id x) {
            [self handleSuccess:x];
        } error:^(NSError *error) {
        [self handleError:error];
    }];
}


#pragma mark - Examle methods

- (void)handleSuccess:(NSDictionary *)dictionary {
    NSLog(@"Success!");
}


- (void)handleError:(NSError *)error {
    NSLog(@"Error!");
}


@end
