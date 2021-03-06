//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GitHubServiceDelegate.h"
#import "GitHubDelegate.h"
#import "LogInStateReader.h"
#import "LogInStateSetter.h"
#import "UserCacheSetter.h"
#import "UserCacheReader.h"
#import "RepoCacheSetter.h"
#import "RepoCacheReader.h"
#import "CommitCacheSetter.h"
#import "CommitCacheReader.h"
#import "ConfigReader.h"
#import "LogInState.h"
#import "UserCache.h"
#import "RepoCache.h"
#import "CommitCache.h"
#import "UserNetworkCache.h"

@class GitHub;

@interface GitHubService : NSObject <GitHubDelegate>
{
    IBOutlet id<GitHubServiceDelegate> delegate;

    IBOutlet NSObject<ConfigReader> * configReader;

    IBOutlet NSObject<LogInStateReader> * logInStateReader;
    IBOutlet NSObject<LogInStateSetter> * logInStateSetter;
    IBOutlet NSObject<UserCacheSetter> * userCacheSetter;
    IBOutlet NSObject<UserCacheReader> * userCacheReader;
    IBOutlet NSObject<RepoCacheSetter> * repoCacheSetter;
    IBOutlet NSObject<RepoCacheReader> * repoCacheReader;
    IBOutlet NSObject<CommitCacheSetter> * commitCacheSetter;
    IBOutlet NSObject<CommitCacheReader> * commitCacheReader;
    IBOutlet NSObject<UserNetworkCacheSetter> * userNetworkCacheSetter;

    NSString * usernameForLogInAttempt;

    GitHub * gitHub;
}

@property (nonatomic, retain) <GitHubServiceDelegate> delegate;

#pragma mark Initialization

- (id)initWithConfigReader:(NSObject<ConfigReader> *)aConfigReader
    logInState:(LogInState *)logInState
    userCache:(UserCache*)userCache repoCache:(RepoCache *)repoCache
    commitCache:(CommitCache *)commitCache
    userNetworkCache:(UserNetworkCache *)userNetworkCache;

#pragma mark Logging in

//
// Only one log in attempt is permitted at a time.
//

- (void)logIn:(NSString *)username;
- (void)logIn:(NSString *)username token:(NSString *)token;

#pragma mark Fetching user info

- (void)fetchInfoForUsername:(NSString *)username;

#pragma mark Fetching repository information

- (void)fetchInfoForRepo:(NSString *)repo username:(NSString *)username;

#pragma mark Fetching commit information

- (void)fetchInfoForCommit:(NSString *)commitKey
                      repo:(NSString *)repo
                  username:(NSString *)username;

#pragma mark Fetching followers

- (void)fetchFollowingForUsername:(NSString *)username;
- (void)fetchFollowersForUsername:(NSString *)username;

- (void)followUsername:(NSString *)followee;
- (void)unfollowUsername:(NSString *)followee;

#pragma mark Searching GitHub

- (void)searchUsers:(NSString *)searchString;
- (void)searchRepos:(NSString *)searchString;

@end
