//
//  DLImageView.m
//

#import "DLImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DLImageView

- (id) initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame])
    {
        self.frame = frame;
        [self setupDefaults];
        [self drawRect:self.frame];
    }
    return self;
}

- (void) setBGColorWithRed:(float) thisRed green:(float) thisGreen blue:(float) thisBlue alpha:(float) thisAlpha
{
	bgColorRed = thisRed;
	bgColorGreen = thisGreen;
	bgColorBlue = thisBlue;
	bgAlpha = thisAlpha;
	
	return;
}

- (void) setupDefaults
{
	self.backgroundColor = [UIColor blackColor];
	showShadow = NO;
	bgColorRed = 1.0;
	bgColorGreen = 1.0;
	bgColorBlue = 1.0;
	bgAlpha = 0.5;
}

- (void)awakeFromNib;
{
	[super awakeFromNib];
	[self setupDefaults];

    [self drawRect:self.frame];
    CALayer * layer = [self layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:10.0];
    return;
}

void CGContextAddRoundedRect (CGContextRef c, CGRect rect, int corner_radius, float red, float green, float blue, float alpha) {  
    int x_left = rect.origin.x;  
    int x_left_center = rect.origin.x + corner_radius;  
    int x_right_center = rect.origin.x + rect.size.width - corner_radius;  
    int x_right = rect.origin.x + rect.size.width;  
    int y_top = rect.origin.y;  
    int y_top_center = rect.origin.y + corner_radius;  
    int y_bottom_center = rect.origin.y + rect.size.height - corner_radius;  
    int y_bottom = rect.origin.y + rect.size.height;  
	
	/* Color Function */
	// Drawing lines with an RGB based color 
	// CGContextSetRGBFillColor(c, 0.0, 0.0, 0.0, 1.0); 
	CGContextSetRGBFillColor(c, red, green, blue, alpha); 
	// CGContextSetRGBFillColor(c, 0.03, 0.08, 0.28, 0.4); 

	// Red:0.03 green:0.08 blue:0.28 alpha:0.4
	
    /* Begin! */  
    CGContextBeginPath(c);  
    CGContextMoveToPoint(c, x_left, y_top_center);  
	
    /* First corner */  
    CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);  
    CGContextAddLineToPoint(c, x_right_center, y_top);  
	
    /* Second corner */  
    CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);  
    CGContextAddLineToPoint(c, x_right, y_bottom_center);  
	
    /* Third corner */  
    CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);  
    CGContextAddLineToPoint(c, x_left_center, y_bottom);  
	
    /* Fourth corner */  
    CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);  
    CGContextAddLineToPoint(c, x_left, y_top_center);  

	/* Done */  
    CGContextClosePath(c);  
	
	/* fill the rectangle */
	CGContextFillPath(c);
	
}  

- (void) turnOffShadow
{
	showShadow = NO;
	return;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
	// CGFloat xOffset = 5;
	// CGFloat yOffset = 5;
	// CGFloat shadowBlurRadius = 2;
	
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    /*
	if( showShadow == YES )
	{
	   UIColor *shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2];
	   CGContextSetShadowWithColor(context, CGSizeMake((xOffset + shadowBlurRadius), -(yOffset + shadowBlurRadius)), shadowBlurRadius, shadowColor.CGColor);
	}
	*/
	CGContextAddRoundedRect(context, self.frame, 10, bgColorRed, bgColorGreen, bgColorBlue, bgAlpha);
	
}

@end
