#include <stdio.h>
#include <math.h>
#include <iostream>
#import "UIKit/UIKit.h"
#import "Xelahot/Utils/XelaUtils.h"
#import "Menu/Menu.h"
#import "Menu/Page.h"
#import "Menu/MenuItem.h"
#import "Menu/ToggleItem.h"
#import "Menu/PageItem.h"
#import "Menu/SliderItem.h"
#import "Menu/TextfieldItem.h"
#import "Menu/InvokeItem.h"
#import "Utils/Utils.h"
#import "Utils/Memory.h"
#import "Constants.h"

#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

static Menu *menu;
static NSString *currentProccessBundleId = nil;
static bool searchPatternInProgress = false;
static bool readMemoryInProgress = false;
static int *refToMyTestAllocatedObjectOnHeap = NULL;

static void invokeClearConsole() {
	UITextView *menuTextViewConsoleRef = [menu getMenuTextViewConsoleRef];
	menuTextViewConsoleRef.text = @"";
	[menuTextViewConsoleRef scrollRangeToVisible:NSMakeRange(0, 0)];
}

static void invokeReadMemory() {
    if (searchPatternInProgress || readMemoryInProgress) {
        consoleLog(@"Error: ", @"A reading is already in progress.");
        return;
    }
    
    readMemoryInProgress = true;
	int size = getSizeToReadIfValid([menu getTextfieldValue:@"Size to read in bytes"]);
	
	if (size == -1) {
		consoleLog(@"Error: ", @"The number of bytes you typed is not a valid number. It must be between 1 and 2147483647 inclusively.");
        readMemoryInProgress = false;
		return;
	}
    
    BOOL isStaticAddress = [menu isItemOn:@"Read static address"];
    BOOL isDynamicAddress = [menu isItemOn:@"Read dynamic address"];
    
    if ((isStaticAddress && isDynamicAddress) || (!isStaticAddress && !isDynamicAddress)) {
        consoleLog(@"Error: ", @"Please select either \"Read static address\" or \"Read dynamic address\".");
        readMemoryInProgress = false;
        return;
    }
    
    NSString *addressToReadFrom;
    
    if (isStaticAddress) {
        addressToReadFrom = [menu getTextfieldValue:@"Read static address"];
    } else {
        addressToReadFrom = [menu getTextfieldValue:@"Read dynamic address"];
    }
    
    if (!validHexStringAddress(addressToReadFrom)) {
        readMemoryInProgress = false;
        return;
    }
    
    vm_address_t address = hexStringAddressToAddress(addressToReadFrom);
    
    if (address == -1) {
        readMemoryInProgress = false;
        return;
    }
    if (isStaticAddress) {
        address = staticToDynamicAddress(address);
    }
    
    unsigned char *outputBytes = (unsigned char *)malloc(size);
    
    if (!outputBytes) {
        consoleLog(@"Error: ", @"malloc failed. Maybe there's not enough free heap memory to read that much.");
        readMemoryInProgress = false;
        return;
    }
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    __block bool success = false;
    consoleLog([NSString stringWithFormat:@"Reading memory at 0x%lx...", address]);
    
    // This may take some time and would make the UI lag so it is dispatched to another queue
    dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        success = safe_read_bytes(address, outputBytes, size);
    });

    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if (success) {
            consoleLog(@"Read bytes: ", byteArrayToHexString(outputBytes, size));
            
            if (isStaticAddress) {
                consoleLog(@"Static address: ", [NSString stringWithFormat:@"%@", [addressToReadFrom lowercaseString]]);
            }

            consoleLog(@"Dynamic address: ", [NSString stringWithFormat:@"%p", (unsigned int*)address]);
        }
        
        free(outputBytes);
        readMemoryInProgress = false;
    });
}

static void invokeWriteMemory() {
	NSString *bytesToBeWritten = [[menu getTextfieldValue:@"Bytes to be written"] lowercaseString];
	int size = getSizeOfBytesIfValid(bytesToBeWritten);
	
	if (size == -1) {
		consoleLog(@"Error: ", @"The bytes you typed are not in the expected format. They must be like: 01 AB 0F AA F8 or like 01 ab 0f aa f8. No extra space at the end. It must also be between 1 and 2147483647 bytes inclusively.");
		return;
	}
    
    NSMutableData *bytes = bytesStringToDataObject(bytesToBeWritten);
    NSString *addressToWriteTo;
    bool isStaticAddress = [menu isItemOn:@"Write to static address"] && ![menu isItemOn:@"Write to dynamic address"];
    bool isDynamicAddress = [menu isItemOn:@"Write to dynamic address"] && ![menu isItemOn:@"Write to static address"];
    
	if (isStaticAddress) {
        addressToWriteTo = [menu getTextfieldValue:@"Write to static address"];
	} else if (isDynamicAddress) {
		addressToWriteTo = [menu getTextfieldValue:@"Write to dynamic address"];
	} else {
		consoleLog(@"Error: ", @"Please only select static or dynamic write.");
        return;
	}
    
    if (!validHexStringAddress(addressToWriteTo)) {
        return;
    }
    
    vm_address_t address = hexStringAddressToAddress(addressToWriteTo);
    
    if (address == -1) {
        return;
    }
    if (isStaticAddress) {
        address = staticToDynamicAddress(address);
    }

    if (safe_write_bytes(address, bytes)) {
        if (isStaticAddress) {
            consoleLog(@"Static address: ", [NSString stringWithFormat:@"%@", [addressToWriteTo lowercaseString]]);
        }

        consoleLog(@"Dynamic address: ", [NSString stringWithFormat:@"%p", (unsigned int *)address]);
        consoleLog(@"Bytes written: ", bytesToBeWritten);
    }
}

static void invokeGetSlide() {
    uintptr_t slide = get_slide(true);
    consoleLog(@"Slide: ", [NSString stringWithFormat:@"%p", (void *)slide]);
}

static void invokeGetStartOfMainExecTextSegItem() {
	uint64_t dynamicStartOfTextSegment = getStartAddressOfMainExecutableSegmentByName((char *)"__TEXT");
	consoleLog(@"Start of the main executable's __TEXT segment: ", [NSString stringWithFormat:@"%p", (void *)(uintptr_t)dynamicStartOfTextSegment]);
}

static void invokeGetSizeOfMainExecTextSegItem() {
	uint64_t size = getSizeOfMainExecutableTextSegment();
	consoleLog(@"Size of the main executable's __TEXT segment: ", [NSString stringWithFormat:@"%" PRIu64 @"%@", size, @" bytes"]);
}

static void invokeGetStartOfMainExecDataSegItem() {
    uint64_t dynamicStartOfDataSegment = getStartAddressOfMainExecutableSegmentByName((char *)"__DATA");
    consoleLog(@"Start of the main executable's __DATA segment: ", [NSString stringWithFormat:@"%p", (void *)(uintptr_t)dynamicStartOfDataSegment]);
}

static void invokeSearchPattern() {
    if (searchPatternInProgress || readMemoryInProgress) {
        consoleLog(@"Error: ", @"A search is already in progress.");
        return;
    }
    
    searchPatternInProgress = true;
    NSString *bytesToSearch = [[menu getTextfieldValue:@"Bytes pattern to search"] lowercaseString];
    int size = getSizeOfBytesIfValid(bytesToSearch);
    
    if (size == -1) {
        consoleLog(@"Error: ", @"The bytes you typed are not in the expected format. They must be like: 01 AB 0F AA F8 or like 01 ab 0f aa f8. No extra space at the end.");
        searchPatternInProgress = false;
        return;
    }
    
    uint64_t sizeOfTextSegment = getSizeOfMainExecutableTextSegment();
    unsigned char *outputBytes = (unsigned char *)malloc((int)sizeOfTextSegment);
    
    if (size > (int)sizeOfTextSegment) {
        consoleLog(@"Error: ", @"You are trying to read more bytes than the text segment contains.");
        searchPatternInProgress = false;
        return;
    }
    if (!outputBytes) {
        consoleLog(@"Error: ", @"malloc failed. Maybe there's not enough free heap memory to read that much.");
        searchPatternInProgress = false;
        return;
    }
    
    NSArray *arrayOfBytesToSearch = [bytesToSearch componentsSeparatedByString:@" "];
    NSMutableArray<NSNumber *> *arrayOfBytesToSearchAsHex = [NSMutableArray array];
    
    for (NSString *byteString in arrayOfBytesToSearch) {
        unsigned int byte;
        sscanf([byteString UTF8String], "%x", &byte);
        [arrayOfBytesToSearchAsHex addObject:@(byte)];
    }

    uint64_t dynamicStartOfTextSegment = getStartAddressOfMainExecutableSegmentByName((char *)"__TEXT");
    unsigned char *startPointer = (unsigned char *)dynamicStartOfTextSegment;
    NSMutableArray *patternMatches = [[NSMutableArray alloc] init];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    consoleLog(@"Searching ...");
    
    // This may take some time and would make the UI lag so it is dispatched to another queue
    dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (safe_read_bytes((vm_address_t)startPointer, outputBytes, (int)sizeOfTextSegment)) {
            int i = 0;
            int offset = 0;
            int bytePatternIndex = 0;
            
            for (i = 0; i <= (int)(sizeOfTextSegment) - size; i++) {
                if (outputBytes[i] == [arrayOfBytesToSearchAsHex[bytePatternIndex] unsignedCharValue]) {
                    bytePatternIndex++;
                    
                    if (bytePatternIndex == arrayOfBytesToSearchAsHex.count) {
                        offset = i;
                        [patternMatches addObject:[NSNumber numberWithInt:offset]];
                        bytePatternIndex = 0;
                    }
                } else {
                    bytePatternIndex = 0;
                }
            }
        }
	});

	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        consoleLog(@"Searched bytes: ", bytesToSearch);
        int matchesCount = [patternMatches count];

        if (matchesCount > 0) {
            consoleLog([NSString stringWithFormat:@"Found %d match(es)", matchesCount]);
            
            for (int j = 0; j < matchesCount; j++) {
                int currentOffset = [[patternMatches objectAtIndex:j] intValue];
                vm_address_t address = (vm_address_t)(dynamicStartOfTextSegment + currentOffset - size + 1);
                consoleLog([NSString stringWithFormat:@"Match %d at: ", j + 1], [NSString stringWithFormat:@"%p", (unsigned int *)address]);
            }
        } else {
            consoleLog(@"Error: ", @"No match");
        }
        
        free(outputBytes);
		searchPatternInProgress = false;
	});
}

void addOrSubtractInputsItem(bool subtraction) {
    NSString *inputA = [[menu getTextfieldValue:@"Input A"] lowercaseString];
    NSString *inputB = [[menu getTextfieldValue:@"Input B"] lowercaseString];
    long inputAasLong = 0;
    long inputBasLong = 0;
    
    if ([menu isItemOn:@"Input A"]) {
        // Decimal
        if (!validLongStringValideForHexConversion(inputA, &inputAasLong)) {
            return;
        }
    } else {
        // Hex
        if (!validHexStringAddress(inputA)) {
            return;
        }
        
        try {
            const char *cStr = [inputA UTF8String];
            int base = (cStr[0] == '0' && (cStr[1] == 'x' || cStr[1] == 'X')) ? 0 : 16;
            inputAasLong = std::stol((char *)[inputA UTF8String], 0, base);
        } catch (const std::invalid_argument & e) {
            consoleLog(@"Error: ", @"One or both of the inputs are invalid. Make sure they specify a valid address format like 0x123456789.");
            return;
        } catch (const std::out_of_range & e) {
            consoleLog(@"Error: ", @"One or both of the inputs are too big. Make sure they are not larger than a long.");
            return;
        }
    }
    if ([menu isItemOn:@"Input B"]) {
        // Decimal
        if (!validLongStringValideForHexConversion(inputB, &inputBasLong)) {
            return;
        }
    } else {
        // Hex
        if (!validHexStringAddress(inputB)) {
            return;
        }
        
        try {
            const char *cStr = [inputB UTF8String];
            int base = (cStr[0] == '0' && (cStr[1] == 'x' || cStr[1] == 'X')) ? 0 : 16;
            inputBasLong = std::stol((char *)[inputB UTF8String], 0, base);
        } catch (const std::invalid_argument & e) {
            consoleLog(@"Error: ", @"One or both of the inputs are invalid. Make sure they specify a valid address format like 0x123456789.");
            return;
        } catch (const std::out_of_range & e) {
            consoleLog(@"Error: ", @"One or both of the inputs are too big. Make sure they are not larger than a long.");
            return;
        }
    }

    long long result = 0;
    NSString *symbol;
    
    if (subtraction) {
        if (inputAasLong < inputBasLong) {
            consoleLog(@"Error: ", @"\"Input A\"'s value must be larger than input B' value.");
            return;
        }
        
        result = inputAasLong - inputBasLong;
        symbol = @"-";
    } else {
        result = inputAasLong + inputBasLong;
        symbol = @"+";
    }

    char resultAsHexString[12];
    snprintf(resultAsHexString, 12, "%llx", result);
    consoleLog([NSString stringWithFormat:@"%ld %@ %ld = ", inputAasLong, symbol, inputBasLong], [NSString stringWithFormat:@"%lld (decimal)", result]);
    consoleLog([NSString stringWithFormat:@"0x%lx %@ 0x%lx = ", inputAasLong, symbol, inputBasLong], [NSString stringWithFormat:@"0x%s (hexadecimal)", resultAsHexString]);
}

static void invokeAddInputsItem() {
    addOrSubtractInputsItem(false);
}

static void invokeSubtractInputsItem() {
    addOrSubtractInputsItem(true);
}

static void invokeHexDecConvertorItem() {
    NSString *inputB = [[menu getTextfieldValue:@"Input B"] lowercaseString];
    
    if ([menu isItemOn:@"Input B"]) {
        // Decimal
        long myLong = 0;
        
        if (validLongStringValideForHexConversion(inputB, &myLong)) {
            consoleLog(@"Decimal: ", inputB);
            consoleLog(@"Hexadecimal: ", [NSString stringWithFormat:@"0x%llx", inputB.longLongValue]);
        }
    } else if (validHexStringAddress(inputB)) {
        // Hexadecimal
        const char *cStr = [inputB UTF8String];
        // Pick the right base depending on if the 0x prefix is present to prevent a crash in stoull
        int base = (cStr[0] == '0' && (cStr[1] == 'x' || cStr[1] == 'X')) ? 0 : 16;
        consoleLog(@"Hexadecimal: ", inputB);
        consoleLog(@"Decimal: ", [NSString stringWithFormat:@"%llu", std::stoull((char *)[inputB UTF8String], 0, base)]);
    }
}

static void invokeAllocatedObjectOnHeapItem() {
    if (refToMyTestAllocatedObjectOnHeap != NULL) {
        consoleLog(@"Test address on the heap: ", [NSString stringWithFormat:@"0x%lx", (vm_address_t)refToMyTestAllocatedObjectOnHeap]);
        return;
    }
    
    int *myPointer = (int *)malloc(sizeof(int) * 4);
    
    if (!myPointer) {
        consoleLog(@"Error: ", @"Unable to allocate memory in the heap. malloc error.");
        return;
    }
    
    myPointer[0] = 1;
    myPointer[1] = 2;
    myPointer[2] = 3;
    myPointer[3] = 4;
    refToMyTestAllocatedObjectOnHeap = myPointer;
    consoleLog(@"Test address on the heap: ", [NSString stringWithFormat:@"0x%lx", (vm_address_t)refToMyTestAllocatedObjectOnHeap]);
    consoleLog(@"Initialized with bytes: ", @"01 00 00 00 02 00 00 00 03 00 00 00 04 00 00 00");
}

void initMenu() {
    if (menu != nil) {
        return;
    }
    
    // Temporarily redirect logs to the app's documents folder. Useful for debugging.
    //NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [allPaths objectAtIndex:0];
    //freopen([[documentsDirectory stringByAppendingPathComponent:@"LogsMemEdit.txt"] UTF8String], "w", stderr);
    //NSLog(@"[MemEdit] %@\n", @"NSLog test");
    
    // Create the menu
    menu = [[Menu alloc] initMenu];

    // Items titles must be unique for now. Also, the constructors with parameters should be used instead.
	Page *rootPage = [[Page alloc] initWithPageNumber: 1 parentPage: 1];

	InvokeItem *clearConsoleInvokeItem = [[InvokeItem alloc] init];
	clearConsoleInvokeItem.Title = @"Clear console output";
	clearConsoleInvokeItem.Description = @"This clears the console output.";
	clearConsoleInvokeItem.FunctionPtr = &invokeClearConsole;

    InvokeItem *scrollToTopOfConsoleInvokeItem = [[InvokeItem alloc] init];
    scrollToTopOfConsoleInvokeItem.Title = @"Scroll to top of console";
    scrollToTopOfConsoleInvokeItem.Description = @"This scrolls to the top of the console output.";
    scrollToTopOfConsoleInvokeItem.FunctionPtr = &scrollConsoleOutputToTop;
    
    InvokeItem *scrollToBottomOfConsoleInvokeItem = [[InvokeItem alloc] init];
    scrollToBottomOfConsoleInvokeItem.Title = @"Scroll to bottom of console";
    scrollToBottomOfConsoleInvokeItem.Description = @"This scrolls to the bottom of the console output.";
    scrollToBottomOfConsoleInvokeItem.FunctionPtr = &scrollConsoleOutputToBottom;
    
	// Read memory page
	PageItem *readMemoryPageItem = [[PageItem alloc] init];
	readMemoryPageItem.Title = @"Read memory";
	readMemoryPageItem.TargetPage = 2;
    
    TextfieldItem *sizeToReadInBytesItem = [[TextfieldItem alloc] init];
    sizeToReadInBytesItem.Title = @"Size to read in bytes";
    sizeToReadInBytesItem.Description = @"This is the number of bytes that will be read from memory.";
    sizeToReadInBytesItem.IsOn = NO;
    sizeToReadInBytesItem.DefaultValue = @"4";
    
    TextfieldItem *readStaticAddressItem = [[TextfieldItem alloc] init];
    readStaticAddressItem.Title = @"Read static address";
    readStaticAddressItem.Description = @"An address from a given dumped binary. Format must be either 0x12345ABCD or 0x12345abcd.";
    readStaticAddressItem.IsOn = NO;
    readStaticAddressItem.DefaultValue = @"0x000000000";
    
    TextfieldItem *readDynamicAddressItem = [[TextfieldItem alloc] init];
    readDynamicAddressItem.Title = @"Read dynamic address";
    readDynamicAddressItem.Description = @"An address from memory. Format must be either 0x12345ABCD or 0x12345abcd.";
    readDynamicAddressItem.IsOn = NO;
    readDynamicAddressItem.DefaultValue = @"0x000000000";
    
    InvokeItem *readMemoryItem = [[InvokeItem alloc] init];
    readMemoryItem.Title = @"Read memory";
    readMemoryItem.Description = @"Reads the desired amount of bytes from memory.";
    readMemoryItem.FunctionPtr = &invokeReadMemory;

    TextfieldItem *bytesToSearchItem = [[TextfieldItem alloc] init];
    bytesToSearchItem.Title = @"Bytes pattern to search";
    bytesToSearchItem.Description = @"This represents the bytes that will be searched through memory (the __TEXT segment of the main executable). Format must be 12 34 56 AA or 12 34 56 aa.";
    bytesToSearchItem.IsOn = NO;
    bytesToSearchItem.DefaultValue = @"12 34 56 78 90";
    
    InvokeItem *searchPatternItem = [[InvokeItem alloc] init];
    searchPatternItem.Title = @"Search bytes in __TEXT";
    searchPatternItem.Description = @"Shows all matches of bytes pattern found in the __TEXT segment.";
    searchPatternItem.FunctionPtr = &invokeSearchPattern;

    Page *readMemoryPage = [[Page alloc] initWithPageNumber: 2 parentPage: 1];
    [readMemoryPage addItem: sizeToReadInBytesItem];
    [readMemoryPage addItem: readStaticAddressItem];
    [readMemoryPage addItem: readDynamicAddressItem];
    [readMemoryPage addItem: readMemoryItem];
    [readMemoryPage addItem: bytesToSearchItem];
    [readMemoryPage addItem: searchPatternItem];
    [menu addPage: readMemoryPage];
	
	// Write to memory page
	PageItem *writeToMemoryPageItem = [[PageItem alloc] init];
	writeToMemoryPageItem.Title = @"Write to memory";
	writeToMemoryPageItem.TargetPage = 3;

    TextfieldItem *writeToStaticAddressItem = [[TextfieldItem alloc] init];
    writeToStaticAddressItem.Title = @"Write to static address";
    writeToStaticAddressItem.Description = @"An address from a given dumped binary. Format must be either 0x1000ABCDE or 0x1000abcde.";
    writeToStaticAddressItem.IsOn = NO;
    writeToStaticAddressItem.DefaultValue = @"0x000000000";
    
    TextfieldItem *writeToDynamicAddressItem = [[TextfieldItem alloc] init];
    writeToDynamicAddressItem.Title = @"Write to dynamic address";
    writeToDynamicAddressItem.Description = @"An address. Format must be either 0x1000ABCDE or 0x1000abcde.";
    writeToDynamicAddressItem.IsOn = NO;
    writeToDynamicAddressItem.DefaultValue = @"0x000000000";
    
    TextfieldItem *bytesToBeWrittenItem = [[TextfieldItem alloc] init];
    bytesToBeWrittenItem.Title = @"Bytes to be written";
    bytesToBeWrittenItem.Description = @"This represents the bytes that will be written to memory. Format must be either 12 34 56 FF or 12 34 56 ff.";
    bytesToBeWrittenItem.IsOn = NO;
    bytesToBeWrittenItem.DefaultValue = @"00 00 00 00";
    
    InvokeItem *writeToMemoryItem = [[InvokeItem alloc] init];
    writeToMemoryItem.Title = @"Write to memory";
    writeToMemoryItem.Description = @"Writes those bytes to memory.";
    writeToMemoryItem.FunctionPtr = &invokeWriteMemory;

    Page *writeToMemoryPage = [[Page alloc] initWithPageNumber: 3 parentPage: 1];
    [writeToMemoryPage addItem: writeToStaticAddressItem];
    [writeToMemoryPage addItem: writeToDynamicAddressItem];
    [writeToMemoryPage addItem: bytesToBeWrittenItem];
    [writeToMemoryPage addItem: writeToMemoryItem];
    [menu addPage: writeToMemoryPage];

	// Tools page
	PageItem *toolsPageItem = [[PageItem alloc] init];
	toolsPageItem.Title = @"Tools";
	toolsPageItem.TargetPage = 4;

    InvokeItem *getSlideItem = [[InvokeItem alloc] init];
    getSlideItem.Title = @"Get VM slide";
    getSlideItem.Description = @"This shows you the virtual memory slide so you can defeat ASLR and convert static addresses to dynamic addresses and vice versa";
    getSlideItem.FunctionPtr = &invokeGetSlide;
    
    InvokeItem *getStartOfMainExecTextSegItem = [[InvokeItem alloc] init];
    getStartOfMainExecTextSegItem.Title = @"Get start of __TEXT";
    getStartOfMainExecTextSegItem.Description = @"This shows you start address of the main executable __TEXT segment.";
    getStartOfMainExecTextSegItem.FunctionPtr = &invokeGetStartOfMainExecTextSegItem;
    
    InvokeItem *getSizeOfMainExecTextSegItem = [[InvokeItem alloc] init];
    getSizeOfMainExecTextSegItem.Title = @"Get size of __TEXT";
    getSizeOfMainExecTextSegItem.Description = @"This shows you size of the main executable __TEXT segment.";
    getSizeOfMainExecTextSegItem.FunctionPtr = &invokeGetSizeOfMainExecTextSegItem;

    InvokeItem *getStartOfMainExecDataSegItem = [[InvokeItem alloc] init];
    getStartOfMainExecDataSegItem.Title = @"Get start of __DATA";
    getStartOfMainExecDataSegItem.Description = @"This shows you start address of the main executable __DATA segment.";
    getStartOfMainExecDataSegItem.FunctionPtr = &invokeGetStartOfMainExecDataSegItem;

    TextfieldItem *inputOneForCalcultaorItem = [[TextfieldItem alloc] init];
    inputOneForCalcultaorItem.Title = @"Input A";
    inputOneForCalcultaorItem.Description = @"This is a text input used for the offset calculator feature. If the value is in decimal, enable this. Otherwise, it'll be treated as an hexadecimal value if valid.";
    inputOneForCalcultaorItem.IsOn = NO;
    inputOneForCalcultaorItem.DefaultValue = @"0x000000000";
    
    TextfieldItem *inputTwoForCalcultaorItem = [[TextfieldItem alloc] init];
    inputTwoForCalcultaorItem.Title = @"Input B";
    inputTwoForCalcultaorItem.Description = @"This is a text input used for the offset calculator and the hex/dec convertor features. If the value is in decimal, enable this. Otherwise, it'll be treated as an hexadecimal value if valid.";
    inputTwoForCalcultaorItem.IsOn = NO;
    inputTwoForCalcultaorItem.DefaultValue = @"0x000000000";

    InvokeItem *addInputsItem = [[InvokeItem alloc] init];
    addInputsItem.Title = @"Add input A and B";
    addInputsItem.Description = @"This does \"Input A\" + \"Input B\". Enable the desired text input item if the entered value is currently in decimal. Otherwise, it'll be treated as an hexadecimal value if valid.";
    addInputsItem.FunctionPtr = &invokeAddInputsItem;

    InvokeItem *subtractInputsItem = [[InvokeItem alloc] init];
    subtractInputsItem.Title = @"Subtract input B from A";
    subtractInputsItem.Description = @"This does \"Input A\" - \"Input B\". Enable the desired text input item if the entered value is currently in decimal. Otherwise, it'll be treated as an hexadecimal value if valid.";
    subtractInputsItem.FunctionPtr = &invokeSubtractInputsItem;

    InvokeItem *hexDecConvertorItem = [[InvokeItem alloc] init];
    hexDecConvertorItem.Title = @"Convert input B (hex/dec)";
    hexDecConvertorItem.Description = @"This converts the value in \"Input B\" from hexadecimal to decimal or the opposite. Enable the Input B item if the entered value is currently in decimal. Otherwise, it'll be treated as an hexadecimal value if valid.";
    hexDecConvertorItem.FunctionPtr = &invokeHexDecConvertorItem;

    InvokeItem *invokeTestAllocatedObjectOnHeapItem = [[InvokeItem alloc] init];
    invokeTestAllocatedObjectOnHeapItem.Title = @"Test memory on heap";
    invokeTestAllocatedObjectOnHeapItem.Description = @"This allocates memory on the heap (a pointer to 4 int side by side) and shows the address.";
    invokeTestAllocatedObjectOnHeapItem.FunctionPtr = &invokeAllocatedObjectOnHeapItem;

    Page *toolsPage = [[Page alloc] initWithPageNumber:4 parentPage: 1];
    [toolsPage addItem: getSlideItem];
    [toolsPage addItem: getStartOfMainExecTextSegItem];
    [toolsPage addItem: getSizeOfMainExecTextSegItem];
    [toolsPage addItem: getStartOfMainExecDataSegItem];
    [toolsPage addItem: inputOneForCalcultaorItem];
    [toolsPage addItem: inputTwoForCalcultaorItem];
    [toolsPage addItem: addInputsItem];
    [toolsPage addItem: subtractInputsItem];
    [toolsPage addItem: hexDecConvertorItem];
    [toolsPage addItem: invokeTestAllocatedObjectOnHeapItem];
    [menu addPage: toolsPage];

	// Root page
    [rootPage addItem: clearConsoleInvokeItem];
    [rootPage addItem: scrollToTopOfConsoleInvokeItem];
    [rootPage addItem: scrollToBottomOfConsoleInvokeItem];
    [rootPage addItem: readMemoryPageItem];
    [rootPage addItem: writeToMemoryPageItem];
    [rootPage addItem: toolsPageItem];
	[menu addPage: rootPage];

	[menu setUserDefaultsAndDict];
	[menu loadPage: 1]; // This is not an index
}

void receiveTweakPrefFileForTweakInjectionDecision(NSNotification *notifContent) {
    NSDictionary *dict = notifContent.userInfo;
    NSMutableDictionary *tweakPrefFileDict = [dict objectForKey:@"tweakPrefFileDict"];

    // If you want to always inject into a specific bundleId, you can add "|| [currentProccessBundleId isEqual:@"com.myGroupId.myArtifactId"]" to this condition.
    if ([[tweakPrefFileDict objectForKey:currentProccessBundleId] boolValue] == YES ) {
        copyLibraryBundleToAppDataDirectory();
        initMenu();
    }
}

static void didFinishLaunching(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    currentProccessBundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([currentProccessBundleId isEqual:@"com.apple.springboard"]) {
        NSString *notifRespringFormatted = [NSString stringWithFormat:notifRespring, tweakName];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, (__bridge CFStringRef)notifRespringFormatted, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        NSString *notifGetInstalledAppsAndAppsToInjectFormatted = [NSString stringWithFormat:notifGetInstalledAppsAndAppsToInject, tweakName];
        [[NSDistributedNotificationCenter defaultCenter] addObserverForName:notifGetInstalledAppsAndAppsToInjectFormatted
            object:nil
            queue:nil
            usingBlock:^(NSNotification *notifContent) {
                getInstalledAppsAndAppsToInject(notifContent);
            }
        ];
        
        NSString *notifUpdateSwitchValueFormatted = [NSString stringWithFormat:notifUpdateSwitchValue, tweakName];
        [[NSDistributedNotificationCenter defaultCenter] addObserverForName:notifUpdateSwitchValueFormatted
            object:nil
            queue:nil
            usingBlock:^(NSNotification *notifContent) {
                updateSwitchValue(notifContent);
            }
        ];
        
        NSString *notifGetTweakPrefFileForTweakInjectionDecisionFormatted = [NSString stringWithFormat:notifGetTweakPrefFileForTweakInjectionDecision, tweakName];
        [[NSDistributedNotificationCenter defaultCenter] addObserverForName:notifGetTweakPrefFileForTweakInjectionDecisionFormatted
            object:nil
            queue:nil
            usingBlock:^(NSNotification *notifContent) {
                getTweakPrefFileForTweakInjectionDecision(notifContent);
            }
        ];
    } else {
        NSString *notifReceiveTweakPrefFileForTweakInjectionDecisionFormatted = [NSString stringWithFormat:notifReceiveTweakPrefFileForTweakInjectionDecision, tweakName];
        [[NSDistributedNotificationCenter defaultCenter] addObserverForName:notifReceiveTweakPrefFileForTweakInjectionDecisionFormatted
            object:nil
            queue:nil
            usingBlock:^(NSNotification *notifContent) {
                receiveTweakPrefFileForTweakInjectionDecision(notifContent);
            }
        ];
        
        timer(2) {
            if (![[NSFileManager defaultManager] isReadableFileAtPath:[[NSBundle mainBundle] bundlePath]]) {
                showPopup(dylibName, @"Application main bundle folder is not readable. Impossible to determine if this is a custom IPA. Tweak initialization will stop. Uninstall the tweak and contact the developer for support.");
                return;
            }
            
            bool isCustomIpa = determineIfCustomIpa(dylibName);
            
            if (isCustomIpa) {
                initMenu();
            } else {
                NSMutableDictionary *userInfos = [[NSMutableDictionary alloc] init];
                [userInfos setObject:tweakPrefPlistFile forKey:@"tweakPrefPlistFile"];
                [userInfos setObject:tweakName forKey:@"tweakName"];
                
                NSString *notifGetTweakPrefFileForTweakInjectionDecisionFormatted = [NSString stringWithFormat:notifGetTweakPrefFileForTweakInjectionDecision, tweakName];
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:notifGetTweakPrefFileForTweakInjectionDecisionFormatted object:nil userInfo:userInfos];
            }
        });
    }
}

%ctor {
	// Listens if any proccess using UIKit finished launching
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, &didFinishLaunching, (CFStringRef)UIApplicationDidFinishLaunchingNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
