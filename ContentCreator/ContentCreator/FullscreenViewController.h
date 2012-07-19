//
//  FullscreenViewController.h
//  MemArt
//
//  Created by Aashish Patel on 7/11/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol fullscreenProtocols
- (void) fullscreenExit;
@end

@interface FullscreenViewController : UIViewController

@property (nonatomic, weak) id <fullscreenProtocols> fullscreenDelegate;

@end
