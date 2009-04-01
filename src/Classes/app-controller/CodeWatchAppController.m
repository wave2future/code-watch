//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "CodeWatchAppController.h"
#import "UserDisplayMgr.h"
#import "NetworkAwareViewController.h"
#import "UserViewController.h"
#import "FavoriteUsersDisplayMgr.h"
#import "RepoDisplayMgr.h"
#import "RepoViewController.h"
#import "UIRecentActivityDisplayMgr.h"
#import "CommitDisplayMgr.h"
#import "CommitViewController.h"
#import "FavoriteReposDisplayMgr.h"

@interface CodeWatchAppController (Private)

- (void)loadStateFromPersistenceStores;

- (void)createAndInitFavoriteUsersDisplayMgr;
- (void)createAndInitFavoriteReposDisplayMgr;

@end

@implementation CodeWatchAppController

- (void)dealloc
{
    [configReader release];
    [logInMgr release];
    [logInState release];
    [logInPersistenceStore release];
    
    [userCachePersistenceStore release];
    [newsFeedPersistenceStore release];
    [repoCachePersistenceStore release];
    [commitCachePersistenceStore release];

    [favoriteUsersPersistenceStore release];
    [favoriteUsersViewController release];
    [favoriteUsersNavController release];
    [favoriteUsersState release];
    
    [favoriteReposPersistenceStore release];
    [favoriteReposViewController release];
    [favoriteReposState release];
    [favoriteReposNavController release];
    
    [gitHubServiceFactory release];

    [userDisplayMgrFactory release];
    [repoSelectorFactory release];
    
    [super dealloc];
}

- (void)start
{
    [self loadStateFromPersistenceStores];

    [self createAndInitFavoriteUsersDisplayMgr];
    [self createAndInitFavoriteReposDisplayMgr];

    if ([logInState prompt])
        [logInMgr collectCredentials:self];
    else
        [logInMgr init];
}

- (void)persistState
{
    [logInPersistenceStore save];
    [userCachePersistenceStore save];
    [newsFeedPersistenceStore save];
    [repoCachePersistenceStore save];
    [commitCachePersistenceStore save];
    [favoriteUsersPersistenceStore save];
    [favoriteReposPersistenceStore save];
}

- (void)loadStateFromPersistenceStores
{
    [logInPersistenceStore load];
    [userCachePersistenceStore load];
    [newsFeedPersistenceStore load];
    [repoCachePersistenceStore load];
    [commitCachePersistenceStore load];
    [favoriteUsersPersistenceStore load];
    [favoriteReposPersistenceStore load];
}

#pragma mark Initialization methods

- (void)createAndInitFavoriteUsersDisplayMgr
{
    NSObject<UserDisplayMgr> * userDisplayMgr =
        [userDisplayMgrFactory
        createUserDisplayMgrWithNavigationContoller:favoriteUsersNavController];

    FavoriteUsersDisplayMgr * favoriteUsersDisplayMgr =
        [[FavoriteUsersDisplayMgr alloc]
        initWithViewController:favoriteUsersViewController
        stateReader:favoriteUsersState
        stateSetter:favoriteUsersState
        userDisplayMgr:userDisplayMgr];

    favoriteUsersViewController.delegate = favoriteUsersDisplayMgr;
}

- (void)createAndInitFavoriteReposDisplayMgr
{
    NSObject<RepoSelector> * repoSelector =
        [repoSelectorFactory
        createRepoSelectorWithNavigationController:favoriteReposNavController];
    FavoriteReposDisplayMgr * favoriteReposDisplayMgr =
        [[FavoriteReposDisplayMgr alloc]
        initWithViewController:favoriteReposViewController
        stateReader:favoriteReposState
        stateSetter:favoriteReposState
        repoSelector:repoSelector];
    
    favoriteReposViewController.delegate = favoriteReposDisplayMgr;
}

@end
