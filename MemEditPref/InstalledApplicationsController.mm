#include <iostream>
#include "InstalledApplicationsController.h"
#import <Preferences/PSListController.h> // We're overriding this controller
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import "Xelahot/Utils/XelaUtils.h"
#import "../Constants.h"

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

BOOL readyToDisplay = false;
id sharedInstance = nil; // Get an instance of the current settings PSListController to be able to reload when ready to display
static NSMutableDictionary *installedAppsDict = nil;
static NSMutableDictionary *appsToInjectDict = nil;

void appsObtained(NSNotification *notifContent) {
    NSDictionary *dict = notifContent.userInfo;
    installedAppsDict = [dict objectForKey:@"installedAppsDict"];
    appsToInjectDict = [dict objectForKey:@"appsToInjectDict"];
    
    if (appsToInjectDict == nil) {
        appsToInjectDict = createNewPrefDictWithAllApps(installedAppsDict);
    }
    
    if (sharedInstance != nil) {
        readyToDisplay = true;
        [sharedInstance reloadSpecifiers];
    }
}
    
@implementation InstalledApplicationsController
- (void)viewDidLoad {
    [super viewDidLoad];
    sharedInstance = self;
    NSString *notifAppsObtainedFormatted = [NSString stringWithFormat:notifAppsObtained, tweakName];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName: notifAppsObtainedFormatted
        object: nil
        queue: nil
        usingBlock: ^(NSNotification *notifContent) {
            appsObtained(notifContent);
        }
    ];
    
    NSMutableDictionary *userInfos = [[NSMutableDictionary alloc] init];
    [userInfos setObject:tweakPrefPlistFile forKey:@"tweakPrefPlistFile"];
    [userInfos setObject:tweakName forKey:@"tweakName"];
    NSString *notifGetInstalledAppsAndAppsToInjectFormatted = [NSString stringWithFormat:notifGetInstalledAppsAndAppsToInject, tweakName];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notifGetInstalledAppsAndAppsToInjectFormatted object:nil userInfo:userInfos];
}

- (NSArray *)specifiers {
    if (!readyToDisplay) {
        _specifiers = nil;
    }
    
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *spec;
        
        NSArray<NSString *> *sortedKeys = [installedAppsDict keysSortedByValueUsingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
            return [name1 compare:name2 options:NSCaseInsensitiveSearch];
        }];
        
        for (NSString *currentAppBundleId in sortedKeys) {
            NSString *currentAppName = [installedAppsDict objectForKey:currentAppBundleId];
        
            spec = [PSSpecifier preferenceSpecifierNamed:currentAppName
                target:self
                set:@selector(setPreferenceValue:specifier:)
                get:@selector(readPreferenceValue:)
                detail:Nil
                cell:PSSwitchCell
                edit:Nil
            ];
            
            [spec setProperty:currentAppBundleId forKey:@"bundleId"];
            [spec setProperty:@YES forKey:@"enabled"]; // Makes the switch interactive
            [specifiers addObject:spec];
        }
        
        // Assign class' variable with the dictionary we've created (that's what'll show in the prefBundle)
        _specifiers = [specifiers copy];
    }

	return _specifiers;
}

// This is what determines the values of the switches on the UI
- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *bundleId = specifier.properties[@"bundleId"];
    return [appsToInjectDict objectForKey:bundleId];
}

// Happens when a switch is pressed/value is changed
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundleId = specifier.properties[@"bundleId"];
    
    // If the property "bundleId" is set only (that means it is one of our switches)
    if (bundleId.length) {
        NSNumber *oldSwitchValue = [appsToInjectDict objectForKey:bundleId];
        NSNumber *newSwitchValue = [NSNumber numberWithBool:![oldSwitchValue boolValue]];
        
        NSMutableDictionary *userInfos = [[NSMutableDictionary alloc] init];
        [userInfos setObject:bundleId forKey:@"bundleId"];
        [userInfos setObject:newSwitchValue forKey:@"newSwitchValue"];
        [userInfos setObject:tweakPrefPlistFile forKey:@"tweakPrefPlistFile"];
        
        NSString *notifUpdateSwitchValueFormatted = [NSString stringWithFormat:notifUpdateSwitchValue, tweakName];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notifUpdateSwitchValueFormatted object:nil userInfo:userInfos];
        
        appsToInjectDict = [appsToInjectDict mutableCopy]; // Need to make a mutable copy because it seems to become immutable again when passed around in notifications.
        [appsToInjectDict setObject:newSwitchValue forKey:bundleId];
    }
}
@end
