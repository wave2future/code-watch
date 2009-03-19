//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "GitHub.h"
#import "GitHubApi.h"
#import "GitHubApiRequest.h"
#import "GitHubApiParser.h"

#import "UserInfo.h"
#import "RepoInfo.h"
#import "CommitInfo.h"

#import "NSString+NSDataAdditions.h"
#import "NSError+InstantiationAdditions.h"

@interface GitHub (Private)
- (NSString *)baseApiUrl;
- (NSInvocation *)invocationForRequest:(GitHubApiRequest *)request;
- (void)setInvocation:(NSInvocation *)invocation
           forRequest:(GitHubApiRequest *)request;
- (void)removeInvocationForRequest:(GitHubApiRequest *)request;
+ (NSValue *)keyForRequest:(GitHubApiRequest *)request;
+ (GitHubApiRequest *)requestFromKey:(NSValue *)key;
+ (NSDictionary *)extractUserDetails:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractRepoKeys:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractRepoDetails:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractCommitKeys:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractCommitDetails:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractRepos:(NSDictionary *)gitHubInfo;
+ (NSArray *)extractCommitDetails:(NSDictionary *)gitHubInfo;
- (void)setDelegate:(id<GitHubDelegate>)aDelegate;
- (void)setBaseUrl:(NSURL *)url;
- (void)setApi:(GitHubApi *)anApi;
- (void)setParser:(GitHubApiParser *)aParser;
@end

@implementation GitHub

@synthesize delegate, baseUrl, apiFormat, apiVersion;

- (void)dealloc
{
    [baseUrl release];
    [api release];
    [parser release];
    [requests release];
    [super dealloc];
}

#pragma mark Initialization

- (id)initWithBaseUrl:(NSURL *)url
               format:(GitHubApiFormat)format
              version:(GitHubApiVersion)version
             delegate:(id<GitHubDelegate>)aDelegate
{
    if (self = [super init]) {
        [self setDelegate:aDelegate];
        [self setBaseUrl:url];
        [self setApi:[[[GitHubApi alloc] initWithDelegate:self] autorelease]];
        [self setParser:[GitHubApiParser parserWithApiFormat:format]];

        apiFormat = format;
        apiVersion = version;

        requests = [[NSMutableDictionary alloc] init];
    }

    return self;
}

#pragma mark Working with repositories

- (void)fetchInfoForUsername:(NSString *)username
{
    [self fetchInfoForUsername:username token:nil];
}

- (void)fetchInfoForUsername:(NSString *)username token:(NSString *)token
{
    NSURL * url =
        [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
            [self baseApiUrl], username]];
    GitHubApiRequest * req;

    if (token) {
        NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
            username, @"login", token, @"token", nil];
        req = [[GitHubApiRequest alloc] initWithBaseUrl:url arguments:args];
    } else
        req = [[GitHubApiRequest alloc] initWithBaseUrl:url];

    SEL sel = @selector(handleUserInfoResponse:toRequest:username:token:);
    NSMethodSignature * sig = [self methodSignatureForSelector:sel];
    NSInvocation * inv = [NSInvocation invocationWithMethodSignature:sig];

    [inv setTarget:self];
    [inv setSelector:sel];
    [inv setArgument:&username atIndex:4];
    [inv setArgument:&token atIndex:5];
    [inv retainArguments];

    [self setInvocation:inv forRequest:req];

    [api sendRequest:req];
}

- (void)fetchInfoForRepo:(NSString *)repo
                username:(NSString *)username
                   token:(NSString *)token
{
    NSURL * url = [NSURL URLWithString:
        [NSString stringWithFormat:@"%@/%@/%@/commits/master",
        [self baseApiUrl], username, repo]];
    GitHubApiRequest * req;

    if (token) {
        NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
            username, @"login", token, @"token", nil];
        req = [[GitHubApiRequest alloc] initWithBaseUrl:url arguments:args];
    } else
        req = [[GitHubApiRequest alloc] initWithBaseUrl:url];

    SEL sel = @selector(handleRepoResponse:toRequest:username:token:repo:);
    NSMethodSignature * sig = [self methodSignatureForSelector:sel];
    NSInvocation * inv = [NSInvocation invocationWithMethodSignature:sig];

    [inv setTarget:self];
    [inv setSelector:sel];
    [inv setArgument:&username atIndex:4];
    [inv setArgument:&token atIndex:5];
    [inv setArgument:&repo atIndex:6];
    [inv retainArguments];

    [self setInvocation:inv forRequest:req];

    [api sendRequest:req];
}

#pragma mark GitHubApiDelegate functions

- (void)request:(GitHubApiRequest *)request
    didCompleteWithResponse:(NSData *)response
{
    NSLog(@"Request: '%@' succeeded: received %d bytes in response.", request,
        response.length);

    NSInvocation * invocation = [self invocationForRequest:request];
    [invocation setArgument:&response atIndex:2];
    [invocation setArgument:&request atIndex:3];

    [invocation invoke];

    [self removeInvocationForRequest:request];
}

- (void)request:(GitHubApiRequest *)request
    didFailWithError:(NSError *)error
{
    NSLog(@"Request: '%@' failed: '%@'.", request, error);

    NSInvocation * invocation = [self invocationForRequest:request];
    [invocation setArgument:&error atIndex:2];
    [invocation setArgument:&request atIndex:3];

    [invocation invoke];

    [self removeInvocationForRequest:request];
}

#pragma mark Processing API responses

- (void)handleUserInfoResponse:(id)response
                     toRequest:(GitHubApiRequest *)request
                      username:(NSString *)username
                         token:(NSString *)token
{
    if ([response isKindOfClass:[NSError class]]) {
        [delegate failedToFetchInfoForUsername:username error:response];
        return;
    }

    NSDictionary * info = [parser parseResponse:response];
    NSLog(@"Have user info: '%@'.", info);

    if (info == nil) {  // parsing failed
        NSString * desc = NSLocalizedString(@"github.parse.failed.desc", @"");
        NSError * err = [NSError errorWithLocalizedDescription:desc];
        [delegate failedToFetchInfoForUsername:username error:err];
    } else {
        NSDictionary * userDetails = [[self class] extractUserDetails:info];
        NSArray * repoKeys = [[self class] extractRepoKeys:info];
        NSArray * repoDetails = [[self class] extractRepoDetails:info];

        UserInfo * ui =
            [[UserInfo alloc] initWithDetails:userDetails
                                     repoKeys:repoKeys];

        NSMutableDictionary * repoInfos = [NSMutableDictionary dictionary];
        for (NSUInteger i = 0, count = repoKeys.count; i < count; ++i) {
            NSString * repoKey = [repoKeys objectAtIndex:i];
            NSDictionary * details = [repoDetails objectAtIndex:i];

            RepoInfo * repoInfo = [[RepoInfo alloc] initWithDetails:details];
            [repoInfos setObject:repoInfo forKey:repoKey];
            [repoInfo release];
        }

        [delegate userInfo:ui repos:repoInfos fetchedForUsername:username];

        [ui release];
    }
}

- (void)handleRepoResponse:(id)response
                 toRequest:(GitHubApiRequest *)request
                  username:(NSString *)username
                     token:(NSString *)token
                      repo:(NSString *)repo
{
    if ([response isKindOfClass:[NSError class]]) {
        [delegate failedToFetchInfoForRepo:repo
                                  username:username
                                     error:response];
        return;
    }

    NSDictionary * info = [parser parseResponse:response];
    NSLog(@"Have repo info: '%@'", info);

    NSArray * commits = [[self class] extractCommitDetails:info];

    NSMutableArray * commitInfos =
        [NSMutableArray arrayWithCapacity:commits.count];
    for (NSDictionary * commit in commits) {
        CommitInfo * commitInfo = [[CommitInfo alloc] initWithDetails:commit];
        [commitInfos addObject:commitInfo];
        [commitInfo release];
    }

    [delegate commits:commitInfos fetchedForRepo:repo username:username];
}

#pragma mark Functions to help with building API URLs

- (NSString *)baseApiUrl
{
    //
    // GitHub API URL format is:
    //     http://github.com/api/version/format/username/
    //

    NSString * responseFormat;
    switch (apiFormat) {
        case JsonGitHubApiFormat:
            responseFormat = @"json";
            break;
        default:
            NSAssert1(0, @"Unknown GitHub API response format: %d.", apiFormat);
            break;
    }

    NSString * version;
    switch (apiVersion) {
        case GitHubApiVersion1:
            version = @"v1";
            break;
        default:
            NSAssert1(0, @"Unknown GitHub version: %d.", apiVersion);
            break;
    }

    return [NSString stringWithFormat:@"%@%@/%@",
        baseUrl, version, responseFormat];
}

#pragma mark Tracking requests

- (NSInvocation *)invocationForRequest:(GitHubApiRequest *)request
{
    NSValue * key = [[self class] keyForRequest:request];
    return [requests objectForKey:key];
}

- (void)setInvocation:(NSInvocation *)invocation
           forRequest:(GitHubApiRequest *)request
{
    NSValue * key = [[self class] keyForRequest:request];
    [requests setObject:invocation forKey:key];
}

- (void)removeInvocationForRequest:(GitHubApiRequest *)request
{
    NSValue * key = [[self class] keyForRequest:request];
    [requests removeObjectForKey:key];

    [request autorelease];
}

+ (NSValue *)keyForRequest:(GitHubApiRequest *)request
{
    return [NSValue valueWithNonretainedObject:request];
}

+ (GitHubApiRequest *)requestFromKey:(NSValue *)key
{
    return [key nonretainedObjectValue];
}

+ (NSDictionary *)extractUserDetails:(NSDictionary *)gitHubInfo
{
    NSMutableDictionary * info =
        [[[gitHubInfo objectForKey:@"user"] mutableCopy] autorelease];

    [info removeObjectForKey:@"login"];
    [info removeObjectForKey:@"repositories"];

    return info;
}

+ (NSArray *)extractRepoKeys:(NSDictionary *)gitHubInfo
{
    NSArray * repos =
        [[gitHubInfo objectForKey:@"user"] objectForKey:@"repositories"];
    NSMutableArray * repoNames =
        [NSMutableArray arrayWithCapacity:repos.count];
    for (NSDictionary * repo in repos)
        [repoNames addObject:[repo objectForKey:@"name"]];

    return repoNames;
}

+ (NSArray *)extractRepoDetails:(NSDictionary *)gitHubInfo
{
    NSArray * repos =
        [[gitHubInfo objectForKey:@"user"] objectForKey:@"repositories"];

    NSMutableArray * repoDetails =
        [NSMutableArray arrayWithCapacity:repos.count];
    for (NSDictionary * repo in repos) {
        NSMutableDictionary * mrepo = [[repo mutableCopy] autorelease];
        [mrepo removeObjectForKey:@"name"];
        [repoDetails addObject:mrepo];
    }

    return repoDetails;
}

+ (NSArray *)extractCommitKeys:(NSDictionary *)gitHubInfo
{
    NSArray * commits = [gitHubInfo objectForKey:@"commits"];

    NSMutableArray * commitKeys =
        [NSMutableArray arrayWithCapacity:commits.count];
    for (NSDictionary * commit in commits) {
        NSString * key = [commit objectForKey:@"id"];
        [commitKeys addObject:key];
    }

    return commitKeys;
}

+ (NSArray *)extractCommitDetails:(NSDictionary *)gitHubInfo
{
    NSArray * commits = [gitHubInfo objectForKey:@"commits"];

    NSMutableArray * commitDetails =
        [NSMutableArray arrayWithCapacity:commits.count];
    for (NSDictionary * commit in commits) {
        NSMutableDictionary * mcommit = [[commit mutableCopy] autorelease];
        [mcommit removeObjectForKey:@"id"];
        [commitDetails addObject:mcommit];
    }

    return commitDetails;
}

#pragma mark Accessors

- (void)setDelegate:(id<GitHubDelegate>)aDelegate
{
    // We don't retain our delegate. We don't own it and expect its
    // lifetime to span the use of this class.
    delegate = aDelegate;
}

- (void)setBaseUrl:(NSURL *)url
{
    [url retain];
    [baseUrl release];
    baseUrl = url;
}

- (void)setApi:(GitHubApi *)anApi
{
    [anApi retain];
    [api release];
    api = anApi;
}

- (void)setParser:(GitHubApiParser *)aParser
{
    [aParser retain];
    [parser release];
    parser = aParser;
}

@end
