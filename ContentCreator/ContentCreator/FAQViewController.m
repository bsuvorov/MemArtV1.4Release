//
//  FAQViewController.m
//  MemArt
//
//  Created by Aashish Patel on 7/12/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import "FAQViewController.h"

@interface FAQViewController()
@property (weak, nonatomic) IBOutlet UIWebView *faqWebView;
@property (weak, nonatomic) IBOutlet UIButton *btnWebViewDone;

@end


@implementation FAQViewController
@synthesize faqWebView;
@synthesize btnWebViewDone;
@synthesize delegate = _delegate;

- (void) viewDidLoad
{
    
    NSURL * thisURL = [NSURL URLWithString:@"http://memart.dearlena.com/faq/faq.html"];
    
    [faqWebView loadRequest:[[NSURLRequest alloc] initWithURL:thisURL]];
    return;
}

- (void)viewDidUnload {
    [self setFaqWebView:nil];
    [self setBtnWebViewDone:nil];
    [super viewDidUnload];
}

- (IBAction) cancelPressed:(UIButton *) sender
{
    [self.delegate cancelPressed];
}

@end
