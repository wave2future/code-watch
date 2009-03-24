//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoDataViewController.h"
#import "NetworkAwareViewControllerDelegate.h"

enum UpdatingState
{
    kConnectedAndUpdating,
    kConnectedAndNotUpdating,
    kDisconnected
};

@interface NetworkAwareViewController : UIViewController
{
    IBOutlet NSObject<NetworkAwareViewControllerDelegate> * delegate;
    
    IBOutlet UIViewController * targetViewController;
    NoDataViewController * noDataViewController;
    
    NSInteger updatingState;
    BOOL cachedDataAvailable;
    
    NSString * updatingText;
    NSString * loadingText;
    NSString * noConnectionText;
    
    UIView * updatingView;
}

- (void)setUpdatingState:(NSInteger)state;
- (void)setCachedDataAvailable:(BOOL)available;

- (void)setUpdatingText:(NSString *)text;
- (void)setLoadingText:(NSString *)text;
- (void)setNoConnectionText:(NSString *)text;

@end
