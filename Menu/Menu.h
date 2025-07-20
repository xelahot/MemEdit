#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "Xelahot/Utils/XelaUtils.h"
#import "Page.h"

@interface Menu : UIView <UITextFieldDelegate>
@property (nonatomic, strong) NSMutableArray<Page *> *Pages;
@property (nonatomic, assign) int CurrentPage;
@property (nonatomic, assign) bool ConsoleOpennedState;
@property (nonatomic, assign) bool IsProcessInPortrait;
@property (nonatomic, strong) NSMutableDictionary *MenuItems;
@property (nonatomic) UIScrollView *ScrollViewRef;

+ (id)singletonMenu;
- (void)createOtherMenuImagesByRotatingExistingImages;
- (BOOL)createImagesFromPath:(NSString *)pathOfImages;
- (void)createMenuImagesWithEmbeddedImages;
- (void)createMenuImages;
- (void)addToggleItem:(NSString *)title_
		description:(NSString *)description_ isOn:(BOOL)isOn_;
- (void)addPageItem:(NSString *)title_ targetPage:(NSUInteger)targetPage_;
- (void)addSliderItem:(NSString *)title_ 
		description:(NSString *)description_ isOn:(BOOL)isOn_ isFloating:(BOOL)isFloating_ defaultValue:(float)defaultValue_ minValue:(float)minValue_ maxValue:(float)maxValue_;
- (BOOL)isItemOn:(NSString *)itemName;
- (float)getSliderValue:(NSString *)itemName;
- (NSString *)getTextfieldValue:(NSString *)itemName;
- (void)addPage:(Page *)page;
- (void)loadPage:(int)pageNumber;
- (void)backPage;
- (void)updateCurrentPosition;
- (void)updateMenuButtonCurrentPosition;
- (void)makeMenuPortraitConsoleClosed:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center;
- (void)makeMenuPortraitConsoleOpenned:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center;
- (void)makeMenuLandscapeConsoleClosed:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center;
- (void)makeMenuLandscapeConsoleOpenned:(float)animationDuration completionAnimationDuration:(float)completionAnimationDuration center:(BOOL)center;
- (void) orientationChanged:(NSNotification *)notification;
- (id)initMenu;
- (id)itemWithName:(NSString *)itemName;
- (void)setUserDefaultsAndDict;
- (UILabel *)getScrollViewConsoleLabelRef;
- (UITextView *)getMenuTextViewConsoleRef;
- (UIButton *)getMenuButtRef;
@end
