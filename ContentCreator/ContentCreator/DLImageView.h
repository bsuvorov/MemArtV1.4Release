//
//  DLImageView.h
//

#import <UIKit/UIKit.h>

@interface DLImageView : UIView 
{
	BOOL					showShadow;
	float					bgColorRed;
	float					bgColorGreen;
	float					bgColorBlue;
	float					bgAlpha;

}


- (id) initWithFrame:(CGRect)frame;
- (void) turnOffShadow;
- (void) setBGColorWithRed:(float) thisRed green:(float) thisGreen blue:(float) thisBlue alpha:(float) thisAlpha;
- (void) setupDefaults;


@end
