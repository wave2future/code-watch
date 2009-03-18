//
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogInMgr.h"
#import "LogInViewControllerDelegate.h"
#import "LogInStateSetter.h"
#import "LogInStateReader.h"
#import "GitHubServiceDelegate.h"
#import "UserCacheSetter.h"

@class GitHubService;
@class LogInViewController;
@class LogInHelpViewController;

@interface UILogInMgr :
    NSObject <LogInMgr, LogInViewControllerDelegate, GitHubServiceDelegate>
{
    IBOutlet UIViewController * rootViewController;

    UINavigationController * navigationController;
    LogInViewController * logInViewController;
    LogInHelpViewController * logInHelpViewController;
    
    IBOutlet UIBarButtonItem * homeBarButtonItem;
    IBOutlet UIBarButtonItem * userBarButtonItem;
    IBOutlet UITabBarItem * userTabBarItem;

    IBOutlet GitHubService * gitHub;
    IBOutlet NSObject<LogInStateSetter> * logInStateSetter;
    IBOutlet NSObject<LogInStateReader> * logInStateReader;
    IBOutlet NSObject<UserCacheSetter> * userCacheSetter;

    BOOL connecting;
}

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) LogInViewController * logInViewController;
@property (nonatomic, retain) LogInHelpViewController * logInHelpViewController;
@property (nonatomic, retain) GitHubService * gitHub;
@property (nonatomic, retain) NSObject<LogInStateSetter> * logInStateSetter;

// Neede re-definition to work in interface builder
- (IBAction)collectCredentials:(id)sender;

@end
