//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/ABNewPersonViewController.h>
#import "NetworkAwareViewController.h"
#import "UserViewController.h"
#import "UserViewControllerDelegate.h"
#import "UserCacheReader.h"
#import "AvatarCacheReader.h"
#import "LogInStateReader.h"
#import "NetworkAwareViewControllerDelegate.h"
#import "RepoSelector.h"
#import "UserDisplayMgr.h"
#import "ContactCacheSetter.h"
#import "GitHubServiceDelegate.h"
#import "GravatarServiceDelegate.h"

@class GitHubService, GravatarService;

@interface UIUserDisplayMgr :
    NSObject
    <GitHubServiceDelegate, GravatarServiceDelegate,
    UserViewControllerDelegate, UserDisplayMgr>
{
    UINavigationController * navigationController;
    NetworkAwareViewController * networkAwareViewController;
    UserViewController * userViewController;
    
    NSObject<UserCacheReader> * userCacheReader;
    NSObject<RepoSelector> * repoSelector;

    NSObject<AvatarCacheReader> * avatarCacheReader;

    GitHubService * gitHubService;
    GravatarService * gravatarService;
    
    NSObject<ContactCacheSetter> * contactCacheSetter;
    
    NSString * username;
}

- (id)initWithNavigationController:
    (UINavigationController *)navigationController
    networkAwareViewController:
    (NetworkAwareViewController *)aNetworkAwareViewController
    userViewController:
    (UserViewController *)aUserViewController
    userCacheReader:
    (NSObject<UserCacheReader> *)aUserCacheReader
    avatarCacheReader:
    (NSObject<AvatarCacheReader> *)anAvatarCacheReader
    repoSelector:
    (NSObject<RepoSelector> *)aRepoSelector
    gitHubService:
    (GitHubService *)aGitHubService
    gravatarService:
    (GravatarService *)aGravatarService
    contactCacheSetter:
    (NSObject<ContactCacheSetter> *)aContactCacheSetter;
    
- (void)displayUserInfo;
    
@end
