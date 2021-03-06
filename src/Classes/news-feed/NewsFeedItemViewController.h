//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewsFeedItemViewControllerDelegate.h"
#import "RepoSelector.h"

@class RssItem;

@interface NewsFeedItemViewController : UITableViewController
{
    NSObject<NewsFeedItemViewControllerDelegate> * delegate;

    NSObject<RepoSelector> * repoSelector;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * authorLabel;
    IBOutlet UILabel * descriptionLabel;
    IBOutlet UILabel * timestampLabel;
    IBOutlet UILabel * subjectLabel;
    IBOutlet UIImageView * avatarImageView;

    RssItem * rssItem;
    UIImage * avatar;
}

@property (nonatomic, retain) NSObject<NewsFeedItemViewControllerDelegate> *
    delegate;
@property (nonatomic, retain) NSObject<RepoSelector> * repoSelector;
@property (nonatomic, copy, readonly) RssItem * rssItem;

#pragma mark Updating the display

- (void)updateWithRssItem:(RssItem *)item;
- (void)updateWithAvatar:(UIImage *)anAvatar;
- (void)scrollToTop;

@end
