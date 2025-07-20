#include <iostream>
#include "MemEditPrefRootListController.h"
#import <Preferences/PSListController.h> // We're overriding this controller
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "Xelahot/Utils/XelaUtils.h"
#import "../Constants.h"

@implementation MemEditPrefRootListController
- (void)doRespring {
    NSString *notifRespringFormatted = [NSString stringWithFormat:notifRespring, tweakName];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)notifRespringFormatted, NULL, NULL, TRUE);
}

- (void)openWebsite {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://xelahot.github.io"] options:@{} completionHandler:nil];
}

- (void)openDiscordServer {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.discord.com/invite/zRgjUnq"] options:@{} completionHandler:nil];
}

- (void)openFacebookPage {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/Xelahot-103452548078705/"] options:@{} completionHandler:nil];
}

- (void)openInstagram {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.instagram.com/xelahot_extensions/"] options:@{} completionHandler:nil];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *spec;

        //Adds a space
        spec = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];

        //Adds respring button
        spec = [PSSpecifier preferenceSpecifierNamed:@"Respring" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        [spec setButtonAction:@selector(doRespring)];
        [spec setProperty:@YES forKey:@"enabled"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Enable/disable injection"
			target:self
			set:Nil
			get:@selector(readPreferenceValue:)
			detail:Nil
			cell:PSGroupCell
			edit:Nil
		];
		[specifiers addObject:spec];
        
		// Useful: https://theapplewiki.com/wiki/Dev:Preferences_specifier_plist
		spec = [PSSpecifier preferenceSpecifierNamed:@"Installed applications"
			target:self
			set:Nil
			get:@selector(readPreferenceValue:)
			detail:NSClassFromString(@"InstalledApplicationsController")
			cell:PSLinkCell
			edit:Nil
		];
		[specifiers addObject:spec];

		spec = [PSSpecifier preferenceSpecifierNamed:@"Other"
			target:self
			set:Nil
			get:@selector(readPreferenceValue:)
			detail:Nil
			cell:PSGroupCell
			edit:Nil
		];
        [specifiers addObject:spec];
		
        spec = [PSSpecifier preferenceSpecifierNamed:@"https://xelahot.github.io" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        [spec setButtonAction:@selector(openWebsite)];
        [spec setProperty:@YES forKey:@"enabled"];
		[specifiers addObject:spec];
		
        spec = [PSSpecifier preferenceSpecifierNamed:@"Discord" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        [spec setButtonAction:@selector(openDiscordServer)];
        [spec setProperty:@YES forKey:@"enabled"];
		[specifiers addObject:spec];
		
        spec = [PSSpecifier preferenceSpecifierNamed:@"Facebook" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        [spec setButtonAction:@selector(openFacebookPage)];
        [spec setProperty:@YES forKey:@"enabled"];
		[specifiers addObject:spec];
		
        spec = [PSSpecifier preferenceSpecifierNamed:@"Instagram" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        [spec setButtonAction:@selector(openInstagram)];
        [spec setProperty:@YES forKey:@"enabled"];
		[specifiers addObject:spec];
		
		// Maybe add a footer later on?
		/*<dict>
			<key>cell</key>
			<string>PSGroupCell</string>
			<key>footerText</key>
			<string>©Xelahot - 2025</string>
		</dict>*/
		
		// Set class variable to the dictionary we created (that's what'll show in the prefBundle)
		_specifiers = [specifiers copy];
	}

	return _specifiers;
}
@end














