#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "Xelahot/Utils/XelaUtils.h"
#import "Menu.h"
#import "Page.h"
#import "ToggleItem.h"
#import "PageItem.h"
#import "SliderItem.h"
#import "TextfieldItem.h"
#import "InvokeItem.h"

// Create a subclass of UITapGestureRecognizer to be able to pass an argument when trying to change page
@interface MyUITapGestureRecognizer : UITapGestureRecognizer
@property (nonatomic) int number;
@property (nonatomic) NSString *text;
@property (nonatomic) void (*ptr)();
@end

@implementation MyUITapGestureRecognizer: UITapGestureRecognizer
@end

// Create a subclass of UISlider to be able to pass info when the value is changed
@interface MyUISlider : UISlider
@property (nonatomic) int number;
@property (nonatomic) NSString *customText;
@end

@implementation MyUISlider: UISlider
@end

@implementation Menu {
	UIWindow *mainWindow;
	NSUserDefaults *userDefaults;
	UIButton *menuButton;
	CGPoint latestMenuButtonPosition;
	CGPoint latestMenuPosition;
	UIButton *menuHeader;
	UIView *menuHeaderBar;
	CAShapeLayer *menuHeaderBarLayer;
	UILabel *menuTitle;
	UIButton *menuBackButton;
	UIButton *menuCloseButton;
	UIScrollView *menuScrollView;
	UITextView *menuTextViewConsole;
	UILabel *scrollViewConsoleLabel;
	UIButton *menuToggleConsoleButton;
	CGFloat menuScrollViewContentHeight;
	CGFloat menuScrollViewConsoleHeight;
	UIView *menuTopBorder;
	UIView *menuBottomBorder;
	UIView *menuLeftBorder;
	UIView *menuRightBorder;
	UIView *menuHeaderBottomBorder;
    UIView *menuExtraPortraitBottomBorder;
    UIImage *rightArrowImage;
    UIImage *downArrowImage;
    UIImage *upArrowImage;
    UIImage *leftArrowImage;
    UIImage *closeMenuImage;
    UIImage *openMenuImage;
    UIImage *sliderImage;
}

static Menu *singletonMenu = nil;

// Menu elements sizes
float menuHeaderHeight = 40;
float menuScrollViewWidth = 220;
float menuScrollViewHeight = 225;
float menuWidthPortrait = menuScrollViewWidth;
float menuWidthLandscapeConsoleClosed = menuScrollViewWidth + menuHeaderHeight;
float menuWidthLandscapeConsoleOpenned = menuScrollViewWidth * 2;
float menuHeightPortraitConsoleClosed = menuHeaderHeight * 2 + menuScrollViewHeight;
float menuHeightPortraitConsoleOpenned = menuScrollViewHeight * 2 + menuHeaderHeight;
float menuHeightLandscape = menuHeaderHeight + menuScrollViewHeight;
float menuHeaderWidthPortrait = menuWidthPortrait;
float menuHeaderWidthLandscapeConsoleClosed = menuWidthLandscapeConsoleClosed;
float menuHeaderWidthLandscapeConsoleOpenned = menuWidthLandscapeConsoleOpenned;
float menuHeaderTitleWidth = menuScrollViewWidth;
float menuHeaderTitleHeight = menuHeaderHeight;
float menuHeaderBarWidthPortrait = menuWidthPortrait / 2;
float menuHeaderBarWidthLandscapeConsoleClosed = menuWidthLandscapeConsoleClosed / 2;
float menuHeaderBarWidthLandscapeConsoleOpenned = menuWidthLandscapeConsoleOpenned / 2;
float menuHeaderBarHeight = 2;
float menuConsoleWidth = menuScrollViewWidth;
float menuConsoleHeight = menuScrollViewHeight;
float menuTopBorderHeight = 2.5;
float menuTopBorderWidthPortrait = menuScrollViewWidth;
float menuTopBorderWidthLandscapeConsoleClosed = menuWidthLandscapeConsoleClosed;
float menuTopBorderWidthLandscapeConsoleOpenned = menuWidthLandscapeConsoleOpenned;
float menuHeaderBottomBorderHeight = 0.5;
float menuHeaderBottomBorderWidthPortrait = menuScrollViewWidth;
float menuHeaderBottomBorderWidthLandscapeConsoleClosed = menuWidthLandscapeConsoleClosed;
float menuHeaderBottomBorderWidthLandscapeConsoleOpenned = menuWidthLandscapeConsoleOpenned;
float menuExtraPortraitBottomBorderHeight = menuHeaderBottomBorderHeight;
float menuExtraPortraitBottomBorderWidth = menuScrollViewWidth;
float menuBottomBorderHeight = menuTopBorderHeight;
float menuBottomBorderWidthPortrait = menuScrollViewWidth;
float menuBottomBorderWidthLandscapeConsoleClosed = menuWidthLandscapeConsoleClosed;
float menuBottomBorderWidthLandscapeConsoleOpenned = menuWidthLandscapeConsoleOpenned;
float menuLeftBorderWidth = menuTopBorderHeight;
float menuLeftBorderHeightPortraitConsoleClosed = menuHeightPortraitConsoleClosed + 2 * menuTopBorderHeight;
float menuLeftBorderHeightPortraitConsoleOpenned = menuHeightPortraitConsoleOpenned + 2 * menuTopBorderHeight;
float menuLeftBorderHeightLandscape = menuHeightLandscape + 2 * menuTopBorderHeight;
float menuRightBorderWidth = menuTopBorderHeight;
float menuRightBorderHeightPortraitConsoleClosed = menuHeightPortraitConsoleClosed + 2 * menuTopBorderHeight;
float menuRightBorderHeightPortraitConsoleOpenned = menuHeightPortraitConsoleOpenned + 2 * menuTopBorderHeight;
float menuRightBorderHeightLandscape = menuHeightLandscape + 2 * menuTopBorderHeight;

@synthesize Pages = _Pages;
@synthesize CurrentPage = _CurrentPage;
@synthesize MenuItems = _MenuItems; // That's a dictionnary that stores a key/value pair of all MenuItems. That way I can find a specific item by name without looping all of them.
@synthesize ScrollViewRef = _ScrollViewRef; // That's a property of the menu that will have a getter to access the menu's scrollView at anytime so I can retrieve UI elements easily from outside this class.
@synthesize ConsoleOpennedState = _ConsoleOpennedState;
@synthesize IsProcessInPortrait = _IsOrientationInPortrait;

+ (id)singletonMenu {
    if (!singletonMenu) {
        singletonMenu = [[Menu alloc] initMenu];
    }
	
    return singletonMenu;
}

- (void)setPages:(NSMutableArray<Page *> *)pPages {
	_Pages = pPages;
}

- (NSMutableArray<Page *> *)Pages {
	return _Pages;
}

- (void)setCurrentPage:(int)pCurrentPage {
	_CurrentPage = pCurrentPage;
}

- (int)CurrentPage {
	return _CurrentPage;
}

- (bool)ConsoleOpennedState {
	return _ConsoleOpennedState;
}

- (bool)IsOrientationInPortrait {
    return _IsOrientationInPortrait;
}

- (void)setMenuItems:(NSMutableDictionary *)pMenuItems {
	_MenuItems = pMenuItems;
}

- (NSMutableDictionary *)MenuItems {
	return _MenuItems;
}

- (UIScrollView *)ScrollViewRef {
	return _ScrollViewRef;
}

- (UILabel *)getScrollViewConsoleLabelRef {
	return scrollViewConsoleLabel;
}

- (UITextView *)getMenuTextViewConsoleRef {
	return menuTextViewConsole;
}

- (void)showDescription:(MyUITapGestureRecognizer *)tap {
	showPopup(@"Description :", tap.text);
}

- (id)itemWithName:(NSString *)itemName {
	for (Page *currentPage in self.Pages) {
		for (MenuItem *currentItem in currentPage.Items) {
            if ([currentItem.Title isEqualToString:itemName]) {
                return currentItem;
            }
		}
	}
	   
	return NULL;
}

- (BOOL)isItemOn:(NSString *)itemName {
	id currentItem = [self.MenuItems objectForKey:itemName];

	if ([currentItem isKindOfClass:[ToggleItem class]]) {
		ToggleItem *myItem = currentItem;
        
		if ([myItem.Title isEqualToString:itemName]) {
            if (myItem.IsOn) {
                return YES;
            } else {
                return NO;
            }
		}
	} else if ([currentItem isKindOfClass:[SliderItem class]]) {
		SliderItem *myItem = currentItem;
		
		if ([myItem.Title isEqualToString:itemName]) {
            if (myItem.IsOn) {
                return YES;
            } else {
                return NO;
            }
		}
	} else if ([currentItem isKindOfClass:[TextfieldItem class]]) {
		TextfieldItem *myItem = currentItem;
		
		if ([myItem.Title isEqualToString:itemName]) {
            if (myItem.IsOn) {
                return YES;
            } else {
                return NO;
            }
		}
	}

	return NO;
}

- (float)getSliderValue:(NSString *)itemName {
	id currentItem = [self.MenuItems objectForKey:itemName];

	if ([currentItem isKindOfClass:[SliderItem class]]) {
		SliderItem *myItem = currentItem;
		
		if ([myItem.Title isEqualToString:itemName]) {
			return myItem.DefaultValue;
		}
	}
   
    return 0.0f;
}

- (NSString *)getTextfieldValue:(NSString *)itemName {
	id currentItem = [self.MenuItems objectForKey:itemName];

	if ([currentItem isKindOfClass:[TextfieldItem class]]) {
		TextfieldItem *myItem = currentItem;
		
		if ([myItem.Title isEqualToString:itemName]) {
			return myItem.DefaultValue;
		}
	}
   
	return @"";
}

- (void)toggleItemOnOff:(MyUITapGestureRecognizer *)tap {
	int itemIndexInScrollView = tap.number;
	UIButton *itemViewRef = [menuScrollView.subviews objectAtIndex: itemIndexInScrollView];
	NSString *itemTitle = tap.text;
	id menuItem = [self itemWithName:itemTitle];

	if([menuItem isKindOfClass:[ToggleItem class]]) {
		NSString *keyIO = [itemTitle stringByAppendingString:@"_IsOn"];
        ToggleItem *myToggleItem = menuItem;
		[userDefaults setObject:[NSNumber numberWithBool:!myToggleItem.IsOn] forKey:keyIO];

		if (!myToggleItem.IsOn) {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
			}];
		} else {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor clearColor];
			}];
		}

		myToggleItem.IsOn = !myToggleItem.IsOn;
	} else if ([menuItem isKindOfClass:[SliderItem class]]) {
		// Prevent toggling on/off when the tapped region is also where the slider is
		CGPoint p = [tap locationInView:itemViewRef];
        
        if (p.y > 30 && p.x < itemViewRef.bounds.size.width / 3 * 2) {
            return;
        }
		
		NSString *keyIO = [itemTitle stringByAppendingString:@"_IsOn"];
        SliderItem *mySliderItem = menuItem;
        [userDefaults setObject:[NSNumber numberWithBool:!mySliderItem.IsOn] forKey:keyIO];
		
		// Change the background color
		if (!mySliderItem.IsOn) {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
			}];
		} else {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor clearColor];
			}];
		}
		
		mySliderItem.IsOn = !mySliderItem.IsOn;
	} else if ([menuItem isKindOfClass:[TextfieldItem class]]) {
		NSString *keyIO = [itemTitle stringByAppendingString:@"_IsOn"];
        TextfieldItem *myTextfieldItem = menuItem;
		[userDefaults setObject:[NSNumber numberWithBool:!myTextfieldItem.IsOn] forKey:keyIO];

		if (!myTextfieldItem.IsOn) {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
			}];
		} else {
			[UIView animateWithDuration:0.25 animations:^ {
				itemViewRef.backgroundColor = [UIColor clearColor];
			}];
		}

		myTextfieldItem.IsOn = !myTextfieldItem.IsOn;
	}
}

- (void)addToggleItem:(NSString *)title_ 
		description:(NSString *)description_ isOn:(BOOL)isOn_ {
	float toggleItemHeight = 40;
	UIButton *myItem = [[UIButton alloc] initWithFrame:CGRectMake(0, menuScrollViewHeight, menuScrollView.bounds.size.width, toggleItemHeight)];
	
    if (!isOn_) {
        myItem.backgroundColor = [UIColor clearColor];
    } else {
        myItem.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
    }
	
	myItem.layer.borderWidth = 0.5f;
	myItem.layer.borderColor = [UIColor whiteColor].CGColor;
	UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, myItem.bounds.size.width - 35, toggleItemHeight)];
	myLabel.text = title_;
	myLabel.textColor = [UIColor whiteColor];
	myLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	myLabel.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: myLabel];

	// Add description button
	UIButton *descriptionButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	descriptionButton.frame = CGRectMake(myItem.bounds.size.width - 30, 12.5, 15, 15);
	descriptionButton.tintColor = [UIColor whiteColor];
	[myItem addSubview: descriptionButton];

	// Add description touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(showDescription:)];
	tapGestureRecognizer.text = description_;
	[descriptionButton addGestureRecognizer: tapGestureRecognizer];

	[menuScrollView addSubview: myItem];

    menuScrollViewContentHeight += toggleItemHeight;
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, menuScrollViewContentHeight);

	// Add touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer2 = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleItemOnOff:)];
	tapGestureRecognizer2.text = title_;
	tapGestureRecognizer2.number = [menuScrollView.subviews indexOfObject: myItem];
	[myItem addGestureRecognizer: tapGestureRecognizer2];
}

- (void)InvokeFunction:(MyUITapGestureRecognizer *)tap {
	int itemIndexInScrollView = tap.number;
	UIButton *itemViewRef = [menuScrollView.subviews objectAtIndex: itemIndexInScrollView];

	[UIView animateWithDuration:0.125 animations:^ {
		itemViewRef.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
	}];
	[UIView animateWithDuration:0.125 animations:^ {
		itemViewRef.backgroundColor = [UIColor clearColor];
	}];

	//Invoke the function
	tap.ptr();
}

- (void)addInvokeItem:(NSString *)title_ 
		description:(NSString *)description_ functionPtr:(void (*)())functionPtr_ {
	float invokeItemHeight = 40;
	UIButton *myItem = [[UIButton alloc] initWithFrame:CGRectMake(0, menuScrollViewContentHeight, menuScrollView.bounds.size.width, invokeItemHeight)];
	myItem.backgroundColor = [UIColor clearColor];
	myItem.layer.borderWidth = 0.5f;
	myItem.layer.borderColor = [UIColor whiteColor].CGColor;

	UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, myItem.bounds.size.width - 35, invokeItemHeight)];
	myLabel.text = title_;
	myLabel.textColor = [UIColor whiteColor];
	myLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	myLabel.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: myLabel];

	// Add description button
	UIButton *descriptionButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	descriptionButton.frame = CGRectMake(myItem.bounds.size.width - 30, 12.5, 15, 15);
	descriptionButton.tintColor = [UIColor whiteColor];
	[myItem addSubview: descriptionButton];

	// Add description touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(showDescription:)];
	tapGestureRecognizer.text = description_;
	[descriptionButton addGestureRecognizer: tapGestureRecognizer];

	[menuScrollView addSubview: myItem];

    menuScrollViewContentHeight += invokeItemHeight;
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, menuScrollViewContentHeight);

	// Add touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer2 = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(InvokeFunction:)];
	tapGestureRecognizer2.ptr = functionPtr_;
	tapGestureRecognizer2.number = [menuScrollView.subviews indexOfObject: myItem];
	[myItem addGestureRecognizer: tapGestureRecognizer2];
}

- (void)pageClicked:(MyUITapGestureRecognizer *)tap {
	[self loadPage: tap.number];
}

- (void)addPageItem:(NSString *)title_ targetPage:(NSUInteger)targetPage_ {
	float pageItemHeight = 40;
	UIButton *myItem = [[UIButton alloc] initWithFrame:CGRectMake(0, menuScrollViewContentHeight, menuScrollView.bounds.size.width, pageItemHeight)];
	myItem.backgroundColor = [UIColor clearColor];
	myItem.layer.borderWidth = 0.5f;
	myItem.layer.borderColor = [UIColor whiteColor].CGColor;

	// Title
	UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, myItem.bounds.size.width - 35, pageItemHeight)];
	myLabel.text = title_;
	myLabel.textColor = [UIColor whiteColor];
	myLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	myLabel.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: myLabel];

	// Right arrow image
	UIImageView *imageView = [[UIImageView alloc] initWithImage:rightArrowImage];
	imageView.frame = CGRectMake(myItem.bounds.size.width - 30, 10, 20, 20);
	imageView.backgroundColor = [UIColor clearColor];

	[myItem addSubview: imageView];
	[menuScrollView addSubview: myItem];

    menuScrollViewContentHeight += pageItemHeight;
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, menuScrollViewContentHeight);

	//Add touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(pageClicked:)];
	tapGestureRecognizer.number = targetPage_;
	[myItem addGestureRecognizer:tapGestureRecognizer];
}

- (void)menuSliderValueChanged:(MyUISlider *)slider_ {
	NSString *title = slider_.customText;
	int itemViewIndex = slider_.number;

	// Get the menu item views references
	UIButton *itemViewRef = [menuScrollView.subviews objectAtIndex: itemViewIndex];
	MyUISlider *sliderViewRef = [itemViewRef.subviews objectAtIndex: 2];
	UILabel *sliderLabel = [itemViewRef.subviews objectAtIndex: 3];

	// Get the SliderItem ref. from title
	SliderItem *sliderItem = [self itemWithName:title];

	// Assign the new UI value on the instance property
	sliderItem.DefaultValue = sliderViewRef.value;

	//Set/replace the userDefaults DefaultValue for that item
	NSString *keyDefault = [title stringByAppendingString:@"_DefaultValue"]; //.Title + "_DefaultValue"
	[userDefaults setObject:[NSNumber numberWithFloat:sliderItem.DefaultValue] forKey:keyDefault];

	// Update the value on the UI elements
	dispatch_async(dispatch_get_main_queue(), ^{
        // Update the label text with that new value depending on the .IsFloating proprety
        if (sliderItem.IsFloating) {
            sliderLabel.text = [NSString stringWithFormat:@"%.2f", sliderViewRef.value];
        } else {
            sliderLabel.text = [NSString stringWithFormat:@"%.0f", sliderViewRef.value];
        }

        sliderViewRef.value = sliderItem.DefaultValue;
	});
}

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
	UIGraphicsBeginImageContext(size);
	[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();    
	UIGraphicsEndImageContext();
	return destImage;
}

- (void)addSliderItem:(NSString *)title_ 
		description:(NSString *)description_ isOn:(BOOL)isOn_ isFloating:(BOOL)isFloating_ defaultValue:(float)defaultValue_ minValue:(float)minValue_ maxValue:(float)maxValue_ {
	float sliderItemHeight = 60;
	UIButton *myItem = [[UIButton alloc] initWithFrame:CGRectMake(0, menuScrollViewContentHeight, menuScrollView.bounds.size.width, sliderItemHeight)];
	
    if (!isOn_) {
        myItem.backgroundColor = [UIColor clearColor];
    } else {
        myItem.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
    }
    
	myItem.layer.borderWidth = 0.5f;
	myItem.layer.borderColor = [UIColor whiteColor].CGColor;

	UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, myItem.bounds.size.width - 35, 35)];
	myLabel.text = title_;
	myLabel.textColor = [UIColor whiteColor];
	myLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	myLabel.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: myLabel];

	UIButton *descriptionButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	descriptionButton.frame = CGRectMake(myItem.bounds.size.width - 30, 7.5, 15, 15);
	descriptionButton.tintColor = [UIColor whiteColor];
	[myItem addSubview: descriptionButton];

	// Add description touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(showDescription:)];
	tapGestureRecognizer.text = description_;
	[descriptionButton addGestureRecognizer: tapGestureRecognizer];

	MyUISlider *menuSlider = [[MyUISlider alloc]initWithFrame:CGRectMake(10, 30, self.bounds.size.width / 2 + 10, 20)];
	menuSlider.minimumTrackTintColor = [UIColor whiteColor];
	menuSlider.maximumTrackTintColor = [UIColor whiteColor];
    
	UIImage* sliderImageResized = [self imageWithImage:sliderImage convertToSize:CGSizeMake(20, 20)];
	[menuSlider setThumbImage: sliderImageResized forState: UIControlStateNormal];
	[menuSlider setThumbImage: sliderImageResized forState: UIControlStateSelected];
	[menuSlider setThumbImage: sliderImageResized forState: UIControlStateHighlighted];

	dispatch_async(dispatch_get_main_queue(), ^{
        menuSlider.value = defaultValue_;
	});
    
	menuSlider.minimumValue = minValue_;
	menuSlider.maximumValue = maxValue_;
	menuSlider.continuous = true;

	[myItem addSubview: menuSlider];

	UILabel *menuSliderValue = [[UILabel alloc]initWithFrame:CGRectMake(10 + menuSlider.bounds.size.width + 10, 30, self.bounds.size.width - menuSlider.bounds.size.width - 20, 20)];

	dispatch_async(dispatch_get_main_queue(), ^{
        if (isFloating_) {
            menuSliderValue.text = [NSString stringWithFormat:@"%.2f", menuSlider.value];
        } else {
			menuSliderValue.text = [NSString stringWithFormat:@"%.0f", menuSlider.value];
		}
	});

	menuSliderValue.textColor = [UIColor whiteColor];
	menuSliderValue.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	menuSliderValue.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: menuSliderValue];
	[menuScrollView addSubview: myItem];

    menuScrollViewContentHeight += sliderItemHeight;
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, menuScrollViewContentHeight);

	// Add on/off event listener
	MyUITapGestureRecognizer *tapGestureRecognizer2 = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleItemOnOff:)];
	tapGestureRecognizer2.text = title_;
	tapGestureRecognizer2.number = [menuScrollView.subviews indexOfObject: myItem];
	[myItem addGestureRecognizer: tapGestureRecognizer2];

	// Add slider value changed event
	menuSlider.number = [menuScrollView.subviews indexOfObject: myItem];
	menuSlider.customText = title_;
	[menuSlider addTarget:self action:@selector(menuSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)addTextfieldItem:(NSString *)title_ 
		description:(NSString *)description_ isOn:(BOOL)isOn_ defaultValue:(NSString *)defaultValue_ {   
	float textfieldItemHeight = 60;
	UIButton *myItem = [[UIButton alloc] initWithFrame:CGRectMake(0, menuScrollViewContentHeight, menuScrollView.bounds.size.width, textfieldItemHeight)];
    if (!isOn_) {
        myItem.backgroundColor = [UIColor clearColor];
    } else {
        myItem.backgroundColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75];
    }
    
	myItem.layer.borderWidth = 0.5f;
	myItem.layer.borderColor = [UIColor whiteColor].CGColor;

	UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, myItem.bounds.size.width - 35, 35)];
	myLabel.text = title_;
	myLabel.textColor = [UIColor whiteColor];
	myLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:15];
	myLabel.textAlignment = NSTextAlignmentLeft;

	[myItem addSubview: myLabel];

	UIButton *descriptionButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	descriptionButton.frame = CGRectMake(myItem.bounds.size.width - 30, 7.5, 15, 15);
	descriptionButton.tintColor = [UIColor whiteColor];
	[myItem addSubview: descriptionButton];

	// Add description touch event listener
	MyUITapGestureRecognizer *tapGestureRecognizer = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(showDescription:)];
	tapGestureRecognizer.text = description_;
	[descriptionButton addGestureRecognizer: tapGestureRecognizer];

	// Container to add padding to the textfield
	UIView *textfieldContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 30, myItem.bounds.size.width - 10, 20)];
	textfieldContainer.backgroundColor = [UIColor clearColor];
	[myItem addSubview: textfieldContainer];

	// Add borders to the container
	UIView *containerBotBorder = [[UIView alloc] initWithFrame:CGRectMake(10, 50, _ScrollViewRef.bounds.size.width - 50, 0.5)];
	containerBotBorder.backgroundColor = [UIColor whiteColor];
	[myItem addSubview: containerBotBorder];
	UIView *containerLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(9.5, 30, 0.5, 20)];
	containerLeftBorder.backgroundColor = [UIColor whiteColor];
	[myItem addSubview: containerLeftBorder];

	UITextField *myTextfield = [[UITextField alloc]initWithFrame:CGRectMake(5, 5, self.bounds.size.width - 50 - 5, 20 - 5)];
	myTextfield.delegate = self; //needed to close the keyboard
	myTextfield.textColor = [UIColor whiteColor];
	myTextfield.textAlignment = NSTextAlignmentLeft;
	myTextfield.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:14];
	myTextfield.backgroundColor = [UIColor clearColor];
	myTextfield.text = defaultValue_;

	// Add padding to the textfield text
	/*UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 30)];
	myTextfield.leftView = paddingView;
	myTextfield.leftViewMode = UITextFieldViewModeAlways;*/

	[textfieldContainer addSubview: myTextfield];
	[menuScrollView addSubview: myItem];
	myTextfield.tag = [menuScrollView.subviews indexOfObject: myItem];

    menuScrollViewContentHeight += textfieldItemHeight;
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, menuScrollViewContentHeight);

	// Add on/off event listener
	MyUITapGestureRecognizer *tapGestureRecognizer2 = [[MyUITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleItemOnOff:)];
	tapGestureRecognizer2.text = title_;
	tapGestureRecognizer2.number = [menuScrollView.subviews indexOfObject: myItem];
	[myItem addGestureRecognizer: tapGestureRecognizer2];
}

// Native method that happens when we clicked the "return" key on the keyboard and the keyboard goes away. ***The arg1 must end with a '_' for the keyboard to close with resignFirstResponder
- (BOOL)textFieldShouldReturn:(UITextField *)textfieldRef_ {
	int itemIndexInScrollView = textfieldRef_.tag; // Get the item index in the scrollView (might be problematic if it does that on every keyboard in the app because there won't be any TextfieldItem or .tag)

	// Get the item title
	UIButton *itemViewRef = [menuScrollView.subviews objectAtIndex: itemIndexInScrollView];
	UILabel *itemLabelRef = [itemViewRef.subviews objectAtIndex: 0];
	NSString *itemTitle = itemLabelRef.text;

	// Get the TextfieldItem ref. to set the .DefaultValue
	TextfieldItem *textfieldItem = [self itemWithName:itemTitle];
	textfieldItem.DefaultValue = textfieldRef_.text;

	// Set/replace the userDefaults DefaultValue for that item
	NSString *keyDefault = [itemTitle stringByAppendingString:@"_DefaultValue"];
	[userDefaults setObject:textfieldItem.DefaultValue forKey:keyDefault];

	// Returns true by default in the default implementation
	[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

	return true;
}

- (void)addPage:(Page *)page {
	[self.Pages addObject:page];
}

- (void)backPage {
	Page *currentPage = [Page pageWithNum:_CurrentPage menuRef:(Menu *)self];
	[self loadPage: currentPage.ParentPage];
}

- (void)closeMenu:(UITapGestureRecognizer *)tap {
	if (tap.state == UIGestureRecognizerStateEnded) {
		[UIView animateWithDuration:0.5 animations:^ {
			self.alpha = 0.0f;
		}];
	}
}

- (void)openMenu:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.5 animations:^ {
            self.alpha = 1.0f;
        }];
    }
}

- (void)updateCurrentPosition {
    latestMenuPosition.x = self.frame.origin.x;
    latestMenuPosition.y = self.frame.origin.y;
}

- (void)updateMenuButtonCurrentPosition {
    latestMenuButtonPosition.x = menuButton.frame.origin.x;
    latestMenuButtonPosition.y = menuButton.frame.origin.y;
}

- (void)makeMenuPortraitConsoleClosed:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center {
    [menuToggleConsoleButton setBackgroundImage: downArrowImage forState:UIControlStateNormal];
    menuTextViewConsole.alpha = 0.0;
    
    [UIView animateWithDuration:animationDuration animations:^ {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, menuWidthPortrait, menuHeightPortraitConsoleClosed);
        menuHeader.frame = CGRectMake(menuHeader.frame.origin.x, menuHeader.frame.origin.y, menuHeaderWidthPortrait, menuHeaderHeight);
        menuTextViewConsole.frame = CGRectMake(menuScrollView.bounds.size.width, menuHeader.self.bounds.size.height, menuConsoleWidth, menuConsoleHeight);
        menuToggleConsoleButton.frame = CGRectMake(self.bounds.size.width / 2 - 10, menuHeightPortraitConsoleClosed - menuHeaderHeight / 2 - 10, 20, 20);
        menuCloseButton.frame = CGRectMake(self.bounds.size.width - 30, 10, 20, 20);
        menuTitle.frame = CGRectMake(0, 0, menuHeaderTitleWidth, menuHeaderTitleHeight);
        menuHeaderBar.frame = CGRectMake(self.bounds.size.width/4, 4, menuHeaderBarWidthPortrait, menuHeaderBarHeight);
        menuHeaderBar.layer.mask = menuHeaderBarLayer;
        menuTopBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderWidthPortrait, menuTopBorderHeight);
        menuLeftBorder.frame = CGRectMake(menuTopBorderHeight * -1, menuTopBorderHeight * -1, menuTopBorderHeight, menuLeftBorderHeightPortraitConsoleClosed);
        menuRightBorder.frame = CGRectMake(self.bounds.size.width, menuTopBorderHeight * -1, menuTopBorderHeight, menuRightBorderHeightPortraitConsoleClosed);
        menuBottomBorder.frame = CGRectMake(0, self.bounds.size.height, menuHeaderBottomBorderWidthPortrait, menuTopBorderHeight);
        menuHeaderBottomBorder.frame = CGRectMake(0, menuHeader.self.bounds.size.height - menuHeaderBottomBorderHeight, menuHeaderBottomBorderWidthPortrait, menuHeaderBottomBorderHeight);
        menuExtraPortraitBottomBorder.alpha = 1;
    } completion: ^(BOOL finished) {
        menuHeaderBarLayer.path = [UIBezierPath bezierPathWithRoundedRect: menuHeaderBar.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){10.0, 10.0}].CGPath;
        
        [UIView animateWithDuration:completionAnimationDuration animations:^ {
            if (center) {
                self.center = mainWindow.center;
                [self updateCurrentPosition];
                menuButton.frame = CGRectMake(mainWindow.frame.size.width - 80, 30, menuButton.bounds.size.width, menuButton.bounds.size.height);
                [self updateMenuButtonCurrentPosition];
            }
        }];
    }];
    
    _IsOrientationInPortrait = true;
    _ConsoleOpennedState = false;
}

- (void)makeMenuPortraitConsoleOpenned:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center {
    [menuToggleConsoleButton setBackgroundImage:upArrowImage forState:UIControlStateNormal];
    
    [UIView animateWithDuration:animationDuration animations:^ {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, menuWidthPortrait, menuHeightPortraitConsoleOpenned);
        menuHeader.frame = CGRectMake(menuHeader.frame.origin.x, menuHeader.frame.origin.y, menuHeaderWidthPortrait, menuHeaderHeight);
        menuTextViewConsole.frame = CGRectMake(0, menuHeaderHeight + menuScrollViewHeight, menuConsoleWidth, menuConsoleHeight);
        menuToggleConsoleButton.frame = CGRectMake(self.bounds.size.width / 2 - 10, menuHeightPortraitConsoleOpenned - menuHeaderHeight / 2 - 10, 20, 20);
        menuCloseButton.frame = CGRectMake(self.bounds.size.width - 30, 10, 20, 20);
        menuTitle.frame = CGRectMake(0, 0, menuHeaderTitleWidth, menuHeaderTitleHeight);
        menuHeaderBar.frame = CGRectMake(self.bounds.size.width/4, 4, menuHeaderBarWidthPortrait, menuHeaderBarHeight);
        menuHeaderBarLayer.path = [UIBezierPath bezierPathWithRoundedRect: menuHeaderBar.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){10.0, 10.0}].CGPath;
        menuHeaderBar.layer.mask = menuHeaderBarLayer;
        menuTopBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderWidthPortrait, menuTopBorderHeight);
        menuLeftBorder.frame = CGRectMake(menuTopBorderHeight * -1, menuTopBorderHeight * -1, menuTopBorderHeight, menuLeftBorderHeightPortraitConsoleOpenned);
        menuRightBorder.frame = CGRectMake(self.bounds.size.width, menuTopBorderHeight * -1, menuTopBorderHeight, menuRightBorderHeightPortraitConsoleOpenned);
        menuBottomBorder.frame = CGRectMake(0, menuHeightPortraitConsoleOpenned, menuHeaderBottomBorderWidthPortrait, menuTopBorderHeight);
        menuHeaderBottomBorder.frame = CGRectMake(0, menuHeader.self.bounds.size.height - menuHeaderBottomBorderHeight, menuHeaderBottomBorderWidthPortrait, menuHeaderBottomBorderHeight);
        menuExtraPortraitBottomBorder.alpha = 1;
    } completion: ^(BOOL finished) {
        [UIView animateWithDuration:completionAnimationDuration animations:^ {
            menuTextViewConsole.alpha = 1.0;
            
            if (center) {
                self.center = mainWindow.center;
                [self updateCurrentPosition];
                menuButton.frame = CGRectMake(mainWindow.frame.size.width - 80, 30, menuButton.bounds.size.width, menuButton.bounds.size.height);
                [self updateMenuButtonCurrentPosition];
            }
        }];
    }];
    
    _IsOrientationInPortrait = true;
    _ConsoleOpennedState = true;
}

- (void)makeMenuLandscapeConsoleClosed:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center {
    [menuToggleConsoleButton setBackgroundImage:rightArrowImage forState:UIControlStateNormal];
    menuTextViewConsole.alpha = 0.0;
    
    [UIView animateWithDuration:animationDuration animations:^ {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, menuWidthLandscapeConsoleClosed, menuHeightLandscape);
        menuHeader.frame = CGRectMake(menuHeader.frame.origin.x, menuHeader.frame.origin.y, menuHeaderWidthLandscapeConsoleClosed, menuHeaderHeight);
        menuTextViewConsole.frame = CGRectMake(menuScrollView.bounds.size.width, menuHeader.self.bounds.size.height, menuConsoleWidth, menuConsoleHeight);
        menuToggleConsoleButton.frame = CGRectMake(self.bounds.size.width - 30, menuHeader.bounds.size.height + menuScrollView.bounds.size.height / 2 - 10, 20, 20);
        menuCloseButton.frame = CGRectMake(self.bounds.size.width - 30, 10, 20, 20);
        menuTitle.frame = CGRectMake(menuHeaderHeight / 2, 0, menuHeaderTitleWidth, menuHeaderTitleHeight);
        menuHeaderBar.frame = CGRectMake(self.bounds.size.width/4, 4, menuHeaderBarWidthLandscapeConsoleClosed, menuHeaderBarHeight);
        menuHeaderBar.layer.mask = menuHeaderBarLayer;
        menuTopBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderWidthLandscapeConsoleClosed, menuTopBorderHeight);
        menuLeftBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderHeight, menuLeftBorderHeightLandscape);
        menuRightBorder.frame = CGRectMake(self.bounds.size.width, menuTopBorderHeight * -1, menuTopBorderHeight, menuRightBorderHeightLandscape);
        menuBottomBorder.frame = CGRectMake(0, self.bounds.size.height, menuBottomBorderWidthLandscapeConsoleClosed, menuTopBorderHeight);
        menuHeaderBottomBorder.frame = CGRectMake(0, menuHeader.self.bounds.size.height - menuHeaderBottomBorderHeight / 2, menuHeaderBottomBorderWidthLandscapeConsoleClosed, menuHeaderBottomBorderHeight);
        menuExtraPortraitBottomBorder.alpha = 0.0;
    } completion: ^(BOOL finished) {
        menuHeaderBarLayer.path = [UIBezierPath bezierPathWithRoundedRect: menuHeaderBar.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){10.0, 10.0}].CGPath;
        
        [UIView animateWithDuration:completionAnimationDuration animations:^ {
            if (center) {
                self.center = mainWindow.center;
                [self updateCurrentPosition];
                menuButton.frame = CGRectMake(mainWindow.frame.size.width - 65, 15, menuButton.bounds.size.width, menuButton.bounds.size.height);
                [self updateMenuButtonCurrentPosition];
            }
        }];
    }];
    
    _IsOrientationInPortrait = false;
    _ConsoleOpennedState = false;
}

- (void)makeMenuLandscapeConsoleOpenned:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center {
    [menuToggleConsoleButton setBackgroundImage:leftArrowImage forState:UIControlStateNormal];
    
    [UIView animateWithDuration:animationDuration animations:^ {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, menuWidthLandscapeConsoleOpenned, menuHeightLandscape);
        menuHeader.frame = CGRectMake(menuHeader.frame.origin.x, menuHeader.frame.origin.y, menuHeaderWidthLandscapeConsoleOpenned, menuHeaderHeight);
        menuTextViewConsole.frame = CGRectMake(menuScrollView.bounds.size.width, menuHeader.self.bounds.size.height, menuConsoleWidth, menuConsoleHeight);
        menuToggleConsoleButton.frame = CGRectMake(self.bounds.size.width - 30, menuHeader.bounds.size.height + menuScrollView.bounds.size.height / 2 - 10, 20, 20);
        menuCloseButton.frame = CGRectMake(self.bounds.size.width - 30, 10, 20, 20);
        menuTitle.frame = CGRectMake(menuWidthLandscapeConsoleOpenned / 4, 0, menuHeaderTitleWidth, menuHeaderTitleHeight);
        menuHeaderBar.frame = CGRectMake(self.bounds.size.width/4, 4, menuHeaderBarWidthLandscapeConsoleOpenned, menuHeaderBarHeight);
        menuHeaderBarLayer.path = [UIBezierPath bezierPathWithRoundedRect: menuHeaderBar.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){10.0, 10.0}].CGPath;
        menuHeaderBar.layer.mask = menuHeaderBarLayer;
        menuTopBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderWidthLandscapeConsoleOpenned, menuTopBorderHeight);
        menuLeftBorder.frame = CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderHeight, menuLeftBorderHeightLandscape);
        menuRightBorder.frame = CGRectMake(self.bounds.size.width, menuTopBorderHeight * -1, menuTopBorderHeight, menuRightBorderHeightLandscape);
        menuBottomBorder.frame = CGRectMake(0, self.bounds.size.height, menuBottomBorderWidthLandscapeConsoleOpenned, menuTopBorderHeight);
        menuHeaderBottomBorder.frame = CGRectMake(0, menuHeader.self.bounds.size.height - menuHeaderBottomBorderHeight / 2, menuHeaderBottomBorderWidthLandscapeConsoleOpenned, menuHeaderBottomBorderHeight);
        menuExtraPortraitBottomBorder.alpha = 0.0;
    } completion: ^(BOOL finished) {
        [UIView animateWithDuration:completionAnimationDuration animations:^ {
            menuTextViewConsole.alpha = 1.0;
            
            if (center) {
                self.center = mainWindow.center;
                [self updateCurrentPosition];
                menuButton.frame = CGRectMake(mainWindow.frame.size.width - 65, 15, menuButton.bounds.size.width, menuButton.bounds.size.height);
                [self updateMenuButtonCurrentPosition];
            }
        }];
    }];
    
    _IsOrientationInPortrait = false;
    _ConsoleOpennedState = true;
}

- (void)orientationChanged:(NSNotification *)notification {
    UIDevice *device = notification.object;
    
    if (device.orientation) {
        UIDeviceOrientation currentOrientation = device.orientation;
        
        // Ignore these orientations: unknown, face up or face down
        if (!UIDeviceOrientationIsValidInterfaceOrientation(currentOrientation)) {
            return;
        }
        
        BOOL isDeviceOrientationPortrait = UIDeviceOrientationIsPortrait(currentOrientation);
        UIWindowScene *windowScene = mainWindow.windowScene;
        UIInterfaceOrientation interfaceOrientation = windowScene.interfaceOrientation;
        BOOL isInterfaceOrientationPortrait = UIInterfaceOrientationIsPortrait(interfaceOrientation);
        BOOL orientationChangedBy90 = NO;
        
        if (isDeviceOrientationPortrait && isInterfaceOrientationPortrait) {
            if (!_IsOrientationInPortrait) {
                orientationChangedBy90 = YES;
            }
            if (_ConsoleOpennedState) {
                [self makeMenuPortraitConsoleOpenned:0.5 completionAnimationDuration:0.25 center:orientationChangedBy90];
            } else {
                [self makeMenuPortraitConsoleClosed:0.5 completionAnimationDuration:0.25 center:orientationChangedBy90];
            }
        } else if (!isDeviceOrientationPortrait && !isInterfaceOrientationPortrait) {
            if (_IsOrientationInPortrait) {
                orientationChangedBy90 = YES;
            }
            if (_ConsoleOpennedState) {
                [self makeMenuLandscapeConsoleOpenned:0.5 completionAnimationDuration:0.25 center:orientationChangedBy90];
            } else {
                [self makeMenuLandscapeConsoleClosed:0.5 completionAnimationDuration:0.25 center:orientationChangedBy90];
            }
        }
    }
}

- (void)toggleConsole:(UITapGestureRecognizer *)tap {
    if (tap.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (_IsOrientationInPortrait) {
        if (_ConsoleOpennedState) {
            [self makeMenuPortraitConsoleClosed:0.5 completionAnimationDuration:0.25 center:NO];
        } else {
            [self makeMenuPortraitConsoleOpenned:0.5 completionAnimationDuration:0.25 center:NO];
        }
    } else {
        if (_ConsoleOpennedState) {
            [self makeMenuLandscapeConsoleClosed:0.5 completionAnimationDuration:0.25 center:NO];
        } else {
            [self makeMenuLandscapeConsoleOpenned:0.5 completionAnimationDuration:0.25 center:NO];
        }
    }
}

- (void)loadPage:(int)pageNumber {
	if (_CurrentPage == 1) {
		[UIView animateWithDuration:0.5 animations:^ {
			menuBackButton.alpha = 1.0f;
		}];
	}

    _CurrentPage = pageNumber;

	if (pageNumber == 1) {
		menuBackButton.alpha = 0.0f;
	}
   
	Page *myPage = [Page pageWithNum:pageNumber menuRef:(Menu *)self];
	NSMutableArray *pageItems = myPage.Items;

	// Hide the scrollView
	[UIView animateWithDuration:0.25 animations:^ {
		menuScrollView.alpha = 0.0f;
	}];

	// Before loading the page, clear the scrollView items
	[menuScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	menuScrollView.contentSize = CGSizeMake(menuScrollView.bounds.size.width, 0);
    menuScrollViewContentHeight = 0;

	for (id currentItem in pageItems) {
		if ([currentItem isKindOfClass:[ToggleItem class]]) {
			ToggleItem *myToggleItem = currentItem;
			[self addToggleItem:(NSString *)myToggleItem.Title
			description:(NSString *)myToggleItem.Description isOn:(BOOL)myToggleItem.IsOn];
		} else if ([currentItem isKindOfClass:[PageItem class]]) {
			PageItem *myPageItem = currentItem;
			[self addPageItem:(NSString *)myPageItem.Title
			targetPage:(NSUInteger) myPageItem.TargetPage];
		} else if ([currentItem isKindOfClass:[SliderItem class]]) {
			SliderItem *mySliderItem = currentItem;
			[self addSliderItem:(NSString *)mySliderItem.Title description:(NSString *)mySliderItem.Description isOn:(BOOL)mySliderItem.IsOn isFloating:(BOOL)mySliderItem.IsFloating defaultValue:(float)mySliderItem.DefaultValue minValue:(float)mySliderItem.MinValue maxValue:(float)mySliderItem.MaxValue];
		} else if ([currentItem isKindOfClass:[TextfieldItem class]]) {
			TextfieldItem *myTextfieldItem = currentItem;
			[self addTextfieldItem:(NSString *)myTextfieldItem.Title description:(NSString *)myTextfieldItem.Description isOn:(BOOL)myTextfieldItem.IsOn defaultValue:(NSString *)myTextfieldItem.DefaultValue];
		}
		
		if ([currentItem isKindOfClass:[InvokeItem class]]) {
			InvokeItem *myInvokeItem = currentItem;
			[self addInvokeItem:(NSString *)myInvokeItem.Title
			description:(NSString *)myInvokeItem.Description functionPtr:(void (*)())myInvokeItem.FunctionPtr];
		}
	}

	[UIView animateWithDuration:0.25 animations:^ {
		menuScrollView.alpha = 1.0f;
	}];
}

- (void)moveMenu:(UIPanGestureRecognizer *)gesture {
	CGPoint newPosition = [gesture translationInView:self.superview];
	self.frame = CGRectMake(latestMenuPosition.x + newPosition.x, latestMenuPosition.y + newPosition.y, self.frame.size.width, self.frame.size.height);

	if (gesture.state == UIGestureRecognizerStateEnded) {
		// All fingers are lifted. Save position
		latestMenuPosition.x = latestMenuPosition.x + newPosition.x;
		latestMenuPosition.y = latestMenuPosition.y + newPosition.y;
	}
}

- (void)moveMenuButton:(UIPanGestureRecognizer *)gesture {
	CGPoint newPosition = [gesture translationInView:menuButton.superview];
	menuButton.frame = CGRectMake(latestMenuButtonPosition.x + newPosition.x, latestMenuButtonPosition.y + newPosition.y, menuButton.frame.size.width, menuButton.frame.size.height);

	if (gesture.state == UIGestureRecognizerStateEnded) {
		// All fingers are lifted. Save position
		latestMenuButtonPosition.x = latestMenuButtonPosition.x + newPosition.x;
		latestMenuButtonPosition.y = latestMenuButtonPosition.y + newPosition.y;
	}
}

// This is a native method that gets called whenever I touch a UIView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	latestMenuPosition = CGPointMake(self.frame.origin.x, self.frame.origin.y);
	latestMenuButtonPosition = CGPointMake(menuButton.frame.origin.x, menuButton.frame.origin.y);

	// Invoke the original implementation
	[super touchesBegan:touches withEvent:event];
}

- (void)setUserDefaultsAndDict {
	for (Page *currentPage in self.Pages) {
		int count = [currentPage.Items count];

		for (int i = 0; i < count; i++) {
			id currentItem = [currentPage.Items objectAtIndex:i];

			// Only these 3 types of items have values that can be saved by the users
			if ([currentItem isKindOfClass:[ToggleItem class]]) {
				ToggleItem *myItem = currentItem;
				[self.MenuItems setObject:myItem forKey:myItem.Title];
				NSString *keyIsOn = [myItem.Title stringByAppendingString:@"_IsOn"];
				id objectForKeyIsOn = [userDefaults objectForKey:keyIsOn];
                
                if (objectForKeyIsOn != nil) {
                    myItem.IsOn = [(NSNumber *)objectForKeyIsOn boolValue];
                }
			} else if ([currentItem isKindOfClass:[SliderItem class]]) {
				SliderItem *myItem = currentItem;
				[self.MenuItems setObject:myItem forKey:myItem.Title];
				NSString *keyIsOn = [myItem.Title stringByAppendingString:@"_IsOn"];
				id objectForKeyIsOn = [userDefaults objectForKey:keyIsOn];
                
                if (objectForKeyIsOn != nil) {
                    myItem.IsOn = [(NSNumber *)objectForKeyIsOn boolValue];
                }

				NSString *keyDefault = [myItem.Title stringByAppendingString:@"_DefaultValue"];
				id objectForKeyDefault = [userDefaults objectForKey:keyDefault];
				
                if (objectForKeyDefault != nil) {
                    myItem.DefaultValue = [(NSNumber *)objectForKeyDefault floatValue];
                }

				NSString *keyMaxValue = [myItem.Title stringByAppendingString:@"_MaxValue"];
				id objectForKeyMaxValue = [userDefaults objectForKey:keyMaxValue];
				
                if (objectForKeyMaxValue != nil) {
                    myItem.MaxValue = [(NSNumber *)objectForKeyMaxValue floatValue];
                }
			} else if ([currentItem isKindOfClass:[TextfieldItem class]]) {
				TextfieldItem *myItem = currentItem;
				[self.MenuItems setObject:myItem forKey:myItem.Title];
                NSString *keyIsOn = [myItem.Title stringByAppendingString:@"_IsOn"];
				id objectForKeyIsOn = [userDefaults objectForKey:keyIsOn];
				
                if (objectForKeyIsOn != nil) {
                    myItem.IsOn = [(NSNumber *)objectForKeyIsOn boolValue];
                }

				NSString *keyDefault = [myItem.Title stringByAppendingString:@"_DefaultValue"];
				id objectForKeyDefault = [userDefaults objectForKey:keyDefault];
				
                if (objectForKeyDefault != nil) {
                    myItem.DefaultValue = (NSString *)objectForKeyDefault;
                }
			}
		}
	}
}

- (UIButton *)getMenuButtRef {
	return menuButton;
}

- (void)createOtherMenuImagesByRotatingExistingImages {
    leftArrowImage = rotatedImage(rightArrowImage, 180);
    downArrowImage = rotatedImage(rightArrowImage, 90);
    upArrowImage = rotatedImage(rightArrowImage, 270);
}

- (BOOL)createImagesFromPath:(NSString *)pathOfImages {
    closeMenuImage = [UIImage imageWithContentsOfFile:[pathOfImages stringByAppendingString:@"/closeMenu.png"]];
    openMenuImage = [UIImage imageWithContentsOfFile:[pathOfImages stringByAppendingString:@"/openMenu.png"]];
    sliderImage = [UIImage imageWithContentsOfFile:[pathOfImages stringByAppendingString:@"/slider.png"]];
    rightArrowImage = [UIImage imageWithContentsOfFile:[pathOfImages stringByAppendingString:@"/rightArrow.png"]];
    
    if (closeMenuImage == nil || openMenuImage == nil || sliderImage == nil || rightArrowImage == nil) {
        showPopup(@"Error", [@"Unable to create images from path: " stringByAppendingPathComponent:pathOfImages]);
        return false;
    }
    
    [self createOtherMenuImagesByRotatingExistingImages];
    return true;
}

- (void)createMenuImagesWithEmbeddedImages {
    NSData *imageData;
    
    imageData = [[NSData alloc] initWithBase64EncodedString:closeMenuImageBase64 options:0];
    closeMenuImage = [UIImage imageWithData:imageData];
    imageData = [[NSData alloc] initWithBase64EncodedString:openMenuImageBase64 options:0];
    openMenuImage = [UIImage imageWithData:imageData];
    imageData = [[NSData alloc] initWithBase64EncodedString:sliderImageBase64 options:0];
    sliderImage = [UIImage imageWithData:imageData];
    imageData = [[NSData alloc] initWithBase64EncodedString:rightArrowImageBase64 options:0];
    rightArrowImage = [UIImage imageWithData:imageData];
    
    [self createOtherMenuImagesByRotatingExistingImages];
}

- (void)createMenuImages {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoriesOfCurrentApp = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *appDataOfCurrentApp = [directoriesOfCurrentApp objectAtIndex:0];
    NSString *appDataOfCurrentAppLibraryBundleImages = [appDataOfCurrentApp stringByAppendingPathComponent:@"/libXelahot.bundle/images"];
    NSString *appBundlePathLibraryBundleImages = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/libXelahot.bundle/images"];
    
    if ([fileManager fileExistsAtPath:appDataOfCurrentAppLibraryBundleImages]) {
        // Images from library bundle copied to app' data directory (jailbreak)
        if ([self createImagesFromPath:appDataOfCurrentAppLibraryBundleImages]) {
            return;
        }
    }
    if ([fileManager fileExistsAtPath:appBundlePathLibraryBundleImages]) {
        // Images embedded in IPA
        if ([self createImagesFromPath:appBundlePathLibraryBundleImages]) {
            return;
        }
    }
    
    [self createMenuImagesWithEmbeddedImages];
}

- (id)initMenu {
    if (singletonMenu) {
        return singletonMenu;
    }
    
    // Find the application's window we'll add the menu view to
    mainWindow = findCurrentProcessMainWindow(true);
    // Allocate the dictionnary for the items titles and references
    self.MenuItems = [[NSMutableDictionary alloc] init];
    // Get the app's saved informations (restores the switches states)
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self createMenuImages];
    
    // Initialy, initialize the menu element in portrait mode, console closed
    self = [super initWithFrame:CGRectMake(0, 0, menuWidthPortrait, menuHeightPortraitConsoleClosed)];
    self.center = mainWindow.center;
    self.layer.zPosition = 1;
    self.layer.opacity = 1.0f;
    self.alpha = 0.0f; // Hidden by default
    self.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.75];

    [mainWindow addSubview:self];
    
    // Menu header
    menuHeader = [UIButton buttonWithType:UIButtonTypeCustom];
    menuHeader.frame = CGRectMake(0, 0, menuHeaderWidthPortrait, menuHeaderHeight);
    menuHeader.backgroundColor = [UIColor clearColor];
    
    // Add touch event listener to close menu on double tap
    UITapGestureRecognizer *tapGestureRecognizerMenuH = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeMenu:)];
    tapGestureRecognizerMenuH.numberOfTapsRequired = 2;
    [menuHeader addGestureRecognizer: tapGestureRecognizerMenuH];
    
    // Add touch event listener to move the menu
    UIPanGestureRecognizer *moveMenuRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(moveMenu:)];
    [menuHeader addGestureRecognizer: moveMenuRecognizer];
    
    [self addSubview:menuHeader];
    
    // Menu header grabber bar
    menuHeaderBar = [[UIView alloc]initWithFrame:CGRectMake(self.bounds.size.width / 4, 4, menuHeaderBarWidthPortrait, menuHeaderBarHeight)];
    menuHeaderBar.backgroundColor = [UIColor whiteColor];
    
    // Layer to make the grabber bar rounded
    menuHeaderBarLayer = [CAShapeLayer layer];
    menuHeaderBarLayer.path = [UIBezierPath bezierPathWithRoundedRect: menuHeaderBar.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:(CGSize){10.0, 10.0}].CGPath;
    menuHeaderBar.layer.mask = menuHeaderBarLayer;
    
    [menuHeader addSubview:menuHeaderBar];
    
    // Menu title
    menuTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, menuHeaderTitleWidth, menuHeaderTitleHeight)];
    menuTitle.text = @"MemEdit";
    menuTitle.textColor = [UIColor whiteColor];
    menuTitle.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:17.0f];
    menuTitle.textAlignment = NSTextAlignmentCenter;
    
    [menuHeader addSubview: menuTitle];
    
    // Menu pages back button
    menuBackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    menuBackButton.frame = CGRectMake(10, 10, 20, 20);
    menuBackButton.backgroundColor = [UIColor clearColor];
    menuBackButton.alpha = 0.0f; // Hidden by default
    [menuBackButton setBackgroundImage:leftArrowImage forState:UIControlStateNormal];
    [menuBackButton setTintColor:[UIColor whiteColor]];
    
    UITapGestureRecognizer *tapGestureRecognizerCloseBtn = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(backPage)];
    [menuBackButton addGestureRecognizer: tapGestureRecognizerCloseBtn];
    
    [menuHeader addSubview: menuBackButton];
    
    // Menu close button
    menuCloseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    menuCloseButton.frame = CGRectMake(self.bounds.size.width - 30, 10, 20, 20);
    menuCloseButton.backgroundColor = [UIColor clearColor];
    [menuCloseButton setBackgroundImage:closeMenuImage forState:UIControlStateNormal];
    [menuCloseButton setTintColor:[UIColor whiteColor]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeMenu:)];
    [menuCloseButton addGestureRecognizer:tapGestureRecognizer];
    
    [menuHeader addSubview: menuCloseButton];
    
    // Menu scrollView
    menuScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, menuHeader.self.bounds.size.height, menuScrollViewWidth, menuScrollViewHeight)];
    [self addSubview:menuScrollView];
    [self setScrollViewRef:menuScrollView];
    
    // Console output
    menuTextViewConsole = [[UITextView alloc]initWithFrame:CGRectMake(menuScrollView.bounds.size.width, menuHeader.self.bounds.size.height, menuConsoleWidth, menuConsoleHeight)];
    [menuTextViewConsole setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Light" size:12]];
    menuTextViewConsole.textColor = [UIColor whiteColor];
    menuTextViewConsole.textAlignment = NSTextAlignmentLeft;
    menuTextViewConsole.editable = NO;
    [menuTextViewConsole setScrollEnabled:YES];
    [menuTextViewConsole setUserInteractionEnabled:YES];
    [menuTextViewConsole setBackgroundColor:[UIColor clearColor]];
    menuTextViewConsole.alpha = 0.0;
    
    [self addSubview:menuTextViewConsole];
    _ConsoleOpennedState = false;
    
    menuToggleConsoleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    menuToggleConsoleButton.frame = CGRectMake(self.bounds.size.width / 2 - 10, menuHeightPortraitConsoleClosed - menuHeaderHeight / 2 - 10, 20, 20);
    menuToggleConsoleButton.backgroundColor = [UIColor clearColor];
    
    [menuToggleConsoleButton setBackgroundImage:downArrowImage forState:UIControlStateNormal];
    [menuToggleConsoleButton setTintColor:[UIColor whiteColor]];
    
    UITapGestureRecognizer *tapGestureRecognizerConsole = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleConsole:)];
    [menuToggleConsoleButton addGestureRecognizer:tapGestureRecognizerConsole];
    
    [self addSubview: menuToggleConsoleButton];
    
    // Menu borders
    menuTopBorder = [[UIView alloc]initWithFrame:CGRectMake(0, menuTopBorderHeight * -1, menuTopBorderWidthPortrait, menuTopBorderHeight)];
    menuTopBorder.backgroundColor = [UIColor greenColor];
    [self addSubview:menuTopBorder];
    
    menuLeftBorder = [[UIView alloc]initWithFrame:CGRectMake(menuTopBorderHeight * -1, menuTopBorderHeight * -1, menuTopBorderHeight, menuLeftBorderHeightPortraitConsoleClosed)];
    menuLeftBorder.backgroundColor = [UIColor greenColor];
    [self addSubview: menuLeftBorder];
    
    menuRightBorder = [[UIView alloc]initWithFrame:CGRectMake(self.bounds.size.width, menuTopBorderHeight * -1, menuTopBorderHeight, menuRightBorderHeightPortraitConsoleClosed)];
    menuRightBorder.backgroundColor = [UIColor greenColor];
    [self addSubview: menuRightBorder];
    
    menuBottomBorder = [[UIView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height, menuHeaderBottomBorderWidthPortrait, menuTopBorderHeight)];
    menuBottomBorder.backgroundColor = [UIColor greenColor];
    [self addSubview: menuBottomBorder];
    
    menuHeaderBottomBorder = [[UIView alloc]initWithFrame:CGRectMake(0, menuHeader.self.bounds.size.height - menuHeaderBottomBorderHeight, menuHeaderBottomBorderWidthPortrait, menuHeaderBottomBorderHeight)];
    menuHeaderBottomBorder.backgroundColor = [UIColor greenColor];
    menuHeaderBottomBorder.alpha = 1;
    [menuHeader addSubview: menuHeaderBottomBorder];
    
    menuExtraPortraitBottomBorder = [[UIView alloc]initWithFrame:CGRectMake(0, menuHeaderHeight + menuScrollViewHeight - menuExtraPortraitBottomBorderHeight / 2, menuExtraPortraitBottomBorderWidth, menuExtraPortraitBottomBorderHeight)];
    menuExtraPortraitBottomBorder.backgroundColor = [UIColor greenColor];
    menuExtraPortraitBottomBorder.alpha = 1;
    [self addSubview: menuExtraPortraitBottomBorder];
    
    // Detect current interface orientation
    _IsOrientationInPortrait = true;
    UIWindowScene *windowScene = mainWindow.windowScene;
    UIInterfaceOrientation interfaceOrientation = windowScene.interfaceOrientation;
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        // Show the menu in center of the screen (landscape-wise)
        self.frame = CGRectMake(0, 0, menuWidthLandscapeConsoleClosed, menuHeightLandscape);
        self.center = mainWindow.center;
    
        [self makeMenuLandscapeConsoleClosed:0 completionAnimationDuration:0 center:NO];
    }
    
    [self updateCurrentPosition];
    
    // Menu button
    menuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    float menuButtonX = mainWindow.frame.size.width - 80;
    float menuButtonY = 30;
    
    if (!_IsOrientationInPortrait) {
        menuButtonX = mainWindow.frame.size.width - 65;
        menuButtonY = 15;
    }

    latestMenuButtonPosition.x = menuButtonX;
    latestMenuButtonPosition.y = menuButtonY;
    menuButton.frame = CGRectMake(menuButtonX, menuButtonY, 50, 50);
    [self updateMenuButtonCurrentPosition];
    menuButton.backgroundColor = [UIColor clearColor];
    [menuButton setBackgroundImage:openMenuImage forState:UIControlStateNormal];

    // Add touch events listeners
    UITapGestureRecognizer *tapGestureRecognizerMenuBtn = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openMenu:)];
    [menuButton addGestureRecognizer: tapGestureRecognizerMenuBtn];

    UIPanGestureRecognizer *moveMenuButtonRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(moveMenuButton:)];
    [menuButton addGestureRecognizer: moveMenuButtonRecognizer];

    [mainWindow addSubview:menuButton];
    
	// Create the menu pages list
	_Pages = [[NSMutableArray alloc] init];
	_CurrentPage = 1;

    // Start detecting device orientation events
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
	singletonMenu = self;
	return singletonMenu;
}
@end
