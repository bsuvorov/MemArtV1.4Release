//
//  FAQViewController.h
//  MemArt
//
//  Created by Aashish Patel on 7/12/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FAQProtocol
- (void) cancelPressed;
@end

@interface FAQViewController : UIViewController

@property (nonatomic, weak) id <FAQProtocol> delegate;

@end
