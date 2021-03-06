//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SearchViewController.h"
#import "UIColor+CodeWatchColors.h"

static const CGFloat IPHONE_WIDTH = 320;

@interface SearchViewController (Private)

- (void)refreshView;
- (void)updateNonZeroSearchResults;

+ (CGRect)defaultFrame;
+ (CGRect)transitionFrame;
+ (CGRect)searchFrame;

@end

@implementation SearchViewController

@synthesize delegate;
@synthesize searchResults;

- (void)dealloc
{
    [delegate release];
    [tableView release];
    [searchBar release];
    [activityIndicator release];
    [loadingLabel release];
    [searchService release];
    [searchResults release];
    [nonZeroSearchResults release];
    [title release];
    [super dealloc];
}

- (id)initWithSearchService:(NSObject<SearchService> *)aSearchService
{
    if (self = [super init]) {
        searchService = [aSearchService retain];
        self.searchResults = [[NSMutableDictionary dictionary] retain];
        nonZeroSearchResults = [[NSMutableDictionary dictionary] retain];
    }

    return self;
}

#pragma mark UIViewController implementation

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor codeWatchBackgroundColor];
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    self.navigationController.navigationBarHidden = YES;
    
    title = [self.navigationItem.title retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.title = @"";
    NSIndexPath * selectedRow = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:selectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.navigationController.navigationBarHidden = YES;
    searchBar.hidden = NO;
    tableView.frame = [[self class] defaultFrame];
    
    // this is a hack to fix an occasional bug exhibited on the device where the
    // selected cell isn't deselected
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    searchBar.hidden = YES;
    self.navigationController.navigationBarHidden = NO;

    // in case search field active
    tableView.frame = [[self class] transitionFrame];

    [searchBar resignFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.navigationItem.title = title;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    NSInteger numNonZeroResultSets = [[nonZeroSearchResults allKeys] count];
    
    return numNonZeroResultSets > 0 ? numNonZeroResultSets : 1;
}

- (NSInteger)tableView:(UITableView *)aTableView
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows;
    
    NSArray * nonZeroSearchResultKeys = [nonZeroSearchResults allKeys];
    if ([nonZeroSearchResultKeys count] > 0) {
        NSString * key = [nonZeroSearchResultKeys objectAtIndex:section];
        numRows = [[nonZeroSearchResults objectForKey:key] count];
    } else
        numRows = 0;
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell * cell =
        [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
    if (cell == nil)
        cell =
            [[[UITableViewCell alloc] initWithFrame:CGRectZero
            reuseIdentifier:CellIdentifier] autorelease];
            
    NSArray * nonZeroSearchResultKeys = [nonZeroSearchResults allKeys];
    NSString * key =
        [nonZeroSearchResultKeys objectAtIndex:indexPath.section];
    NSArray * results = [nonZeroSearchResults objectForKey:key];
    cell.text = [[results objectAtIndex:indexPath.row] description];
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)aTableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [searchBar resignFirstResponder];

    NSArray * nonZeroSearchResultKeys = [nonZeroSearchResults allKeys];
    NSString * section =
        [nonZeroSearchResultKeys objectAtIndex:indexPath.section];
    NSArray * results = [nonZeroSearchResults objectForKey:section];
    NSObject * selection = [results objectAtIndex:indexPath.row];
    
    [delegate processSelection:selection fromSection:section];
}

- (NSString *)tableView:(UITableView *)aTableView
    titleForHeaderInSection:(NSInteger)section
{
    NSArray * nonZeroSearchResultKeys = [nonZeroSearchResults allKeys];

    return [nonZeroSearchResultKeys count] > 0 ?
        [nonZeroSearchResultKeys objectAtIndex:section] : nil;
}

#pragma mark UISearchBarDelegate implementation

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    searchText = [searchText lowercaseString];
    NSLog(@"Searching service for '%@'...", searchText);
    [searchService searchForText:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [searchBar resignFirstResponder];
    self.searchResults = [NSDictionary dictionary];
    [self refreshView];
    canceled = YES;
    searchBar.text = @"";
    
    self.view.frame = [[self class] transitionFrame];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [searchBar resignFirstResponder];
    self.searchResults = [NSDictionary dictionary];
    [self refreshView];
    loadingLabel.hidden = NO;
    [activityIndicator startAnimating];
    [searchService searchForText:[searchBar.text lowercaseString]];
    
    self.view.frame = [[self class] transitionFrame];    
    tableView.frame = [[self class] defaultFrame];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    canceled = NO;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:tableView cache:YES];

    tableView.frame = [[self class] searchFrame];

    [UIView commitAnimations];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    tableView.frame = [[self class] defaultFrame];
    [tableView reloadData];
}

#pragma mark SearchServiceDelegate implementation

- (void)processSearchResults:(NSDictionary *)results
    withSearchText:(NSString *)text
    fromSearchService:(NSObject<SearchService> *)searchService
{
    NSLog(@"Received search '%@' results: %@", text, results);
    if (!canceled && ![text caseInsensitiveCompare:searchBar.text]) {
        loadingLabel.hidden = YES;
        [activityIndicator stopAnimating];
        self.searchResults = results;
        [self refreshView];
    }
}

#pragma mark Helper methods

- (void)refreshView
{
    [self updateNonZeroSearchResults];
    tableView.hidden = [[nonZeroSearchResults allKeys] count] == 0;
    [tableView reloadData];
}

- (void)updateNonZeroSearchResults
{
    [nonZeroSearchResults removeAllObjects];
    for (NSString * category in [self.searchResults allKeys]) {
        NSArray * results = [self.searchResults objectForKey:category];
        if ([results count] > 0)
            [nonZeroSearchResults setObject:results forKey:category];
    }
}

#pragma mark Table view frames

+ (CGRect)defaultFrame
{
    return CGRectMake(0, 44, IPHONE_WIDTH, 367);
}

+ (CGRect)transitionFrame
{
    return CGRectMake(0, 0, IPHONE_WIDTH, 411);
}

+ (CGRect)searchFrame
{
    return CGRectMake(0, 44, IPHONE_WIDTH, 201);
}

@end
