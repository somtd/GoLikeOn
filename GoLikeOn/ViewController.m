//
//  ViewController.m
//  GoLikeOn
//
//  Created by SOMTD on 2013/08/16.
//  Copyright (c) 2013年 SOMTD. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    IBOutlet UIButton *likeButton;
    IBOutlet UIButton *facebookButton;
    IBOutlet UILabel *facebookAccount;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkAccounts];
    [self setupButtons];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)setupButtons {
    facebookButton.enabled = NO;
    likeButton.enabled     = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)checkAccounts {
    __block __weak ViewController *weakSelf = self;
    ACAccountType *accountType;
	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"YOUR_FACABOOK_APP_ID", ACFacebookAppIdKey,
                                 [NSArray arrayWithObjects:@"public_actions", @"publish_stream", nil], ACFacebookPermissionsKey,
                                 ACFacebookAudienceFriends, ACFacebookAudienceKey,
                                 nil];
        [accountStore
         requestAccessToAccountsWithType:accountType
         options:options
         completion:^(BOOL granted, NSError *error) {
             NSLog(@"error:%@",[error description]);
             NSArray *accountArray = [accountStore accountsWithAccountType:accountType];
             NSLog(@"accounts:%@",accountArray);
             for (ACAccount *account in accountArray) {
                 NSString *text = [NSString stringWithFormat:@"%@",[account username]];
                 [weakSelf performSelectorOnMainThread:@selector(showFacebookAccount:)
                                            withObject:text
                                         waitUntilDone:YES];
             }
         }];
    }
}

- (void)showFacebookAccount:(NSString *)text {
    NSString *string = text;
    [facebookAccount setText:string];
    facebookButton.enabled = YES;
    likeButton.enabled     = YES;
}

- (IBAction)onLikeButton:(id)sender {
    NSDictionary *information = @{@"url":@"http://somtd.hatenablog.com"};
    [self postStreakWithInfomation:information];
}

- (void)postStreakWithInfomation:(NSDictionary *)information {
    
    NSString *postString = [information objectForKey:@"message"];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        NSDictionary *optionsToRead  = @{ ACFacebookAppIdKey: @"YOUR_FACABOOK_APP_ID",
                                          ACFacebookPermissionsKey: @[@"basic_info"],
                                          };
        NSDictionary *optionsToWrite = @{ ACFacebookAppIdKey: @"YOUR_FACABOOK_APP_ID",
                                          ACFacebookPermissionsKey: @[@"publish_stream"],
                                          ACFacebookAudienceKey : ACFacebookAudienceFriends,
                                          };
        
        [accountStore requestAccessToAccountsWithType:accountType options:optionsToRead completion:^(BOOL granted, NSError *error) {
            [accountStore requestAccessToAccountsWithType:accountType options:optionsToWrite completion:^(BOOL granted, NSError *error) {
                
                NSArray *accountArray = [accountStore accountsWithAccountType:accountType];
                for (ACAccount *account in accountArray) {
                    
                    NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/og.likes", [[account valueForKey:@"properties"] valueForKey:@"uid"]] ;
                    NSURL *url = [NSURL URLWithString:urlString];
                    NSDictionary *params = [NSDictionary dictionaryWithObject:information[@"url"] forKey:@"object"];
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                            requestMethod:SLRequestMethodPOST
                                                                      URL:url
                                                               parameters:params];
                    [request setAccount:account];
                    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        NSLog(@"responseData=%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                    }];
                }
            }];
        }];
    }
}
@end
