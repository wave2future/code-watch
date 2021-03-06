//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserDisplayMgrFactory.h"
#import "RecentActivityDisplayMgr.h"
#import "UserViewController.h"
#import "NetworkAwareViewController.h"
#import "UIUserDisplayMgr.h"
#import "NewsFeedViewController.h"
#import "UIRecentActivityDisplayMgr.h"
#import "GitHubService.h"
#import "GravatarService.h"

@interface UserDisplayMgrFactory (Private)

- (NSObject<RecentActivityDisplayMgr> *)
    createRecentActivityDisplayMgrWithNavigationController:
    (UINavigationController *)navigationController;
- (UserViewController *)createUserViewController;

@end

@implementation UserDisplayMgrFactory

- (void)dealloc
{
    [gitHubServiceFactory release];
    [gravatarServiceFactory release];
    [repoSelectorFactory release];
    [userCache release];
    [repoCache release];
    [avatarCache release];
    [newsFeedDisplayMgrFactory release];
    [super dealloc];
}

- (NSObject<UserDisplayMgr> *)
    createUserDisplayMgrWithNavigationContoller:
    (UINavigationController *)navigationController
{
    UserViewController * userViewController = [self createUserViewController];
    userViewController.recentActivityDisplayMgr =
        [self createRecentActivityDisplayMgrWithNavigationController:
        navigationController];
    
    NetworkAwareViewController * networkAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:userViewController] autorelease];
    
    GitHubService * gitHubService = [gitHubServiceFactory createGitHubService];

    GravatarService * gravatarService =
        [gravatarServiceFactory createGravatarService];
    
    NSObject<RepoSelector> * repoSelector =
        [repoSelectorFactory
        createRepoSelectorWithNavigationController:navigationController];

    UIUserDisplayMgr * userDisplayMgr =
        [[[UIUserDisplayMgr alloc]
        initWithNavigationController:navigationController
        networkAwareViewController:networkAwareViewController
        userViewController:userViewController userCacheReader:userCache
        repoCacheReader:repoCache avatarCacheReader:avatarCache
        repoSelector:repoSelector gitHubService:gitHubService
        gravatarService:gravatarService contactCacheSetter:contactCache
        newsFeedDisplayMgrFactory:newsFeedDisplayMgrFactory
        gitHubServiceFactory:gitHubServiceFactory
        userDisplayMgrFactory:self] autorelease];
        
    userViewController.delegate = userDisplayMgr;
    gitHubService.delegate = userDisplayMgr;
    gravatarService.delegate = userDisplayMgr;
    
    return userDisplayMgr;
}

- (NSObject<RecentActivityDisplayMgr> *)
    createRecentActivityDisplayMgrWithNavigationController:
    (UINavigationController *)navigationController
{
    NewsFeedViewController * newsFeedViewController =
        [[[NewsFeedViewController alloc] init] autorelease];

    NetworkAwareViewController * networkAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:newsFeedViewController] autorelease];
        
    GitHubService * gitHubService = [gitHubServiceFactory createGitHubService];
        
    UIRecentActivityDisplayMgr * recentActivityDisplayMgr =
        [[[UIRecentActivityDisplayMgr alloc]
        initWithNavigationController:navigationController
        networkAwareViewController:networkAwareViewController
        newsFeedViewController:newsFeedViewController
        gitHubService:gitHubService] autorelease];
    
    return recentActivityDisplayMgr;
}

- (UserViewController *)createUserViewController
{
    UserViewController * userViewController =
        [[[UserViewController alloc] initWithNibName:@"UserView" bundle:nil]
        autorelease];
    userViewController.contactCacheReader = contactCache;
    userViewController.contactMgr = contactMgr;
    
    return userViewController;
}

@end
