#import "Utils.h"
#import "../Menu/Menu.h"
#import "UIKit/UIKit.h"

#include <string.h>
#include <inttypes.h>
#include <stdbool.h>
#include <iostream>

void consoleLog(NSString *prefix) {
    consoleLog(prefix, @"");
}

void consoleLog(NSString *prefix, NSString *message) {
    void (^consoleLogBlock)(void) = ^{
        Menu *menu = [Menu singletonMenu];
        UITextView *menuTextViewConsoleRef = [menu getMenuTextViewConsoleRef];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            UIColor *prefixColor = [UIColor colorWithRed:0.0 green:235 / 255.0 blue:0.0 alpha:1.0];
            NSString *fixedMessage = message;
            
            if ([fixedMessage isEqualToString:@""]) {
                prefixColor = [UIColor colorWithRed:235 / 255.0 green:235 / 255.0 blue:0.0 alpha:1.0];
            }
            
            NSString *newText = [NSString stringWithFormat:@"%@%@%@", prefix, fixedMessage, @"\n"];
            NSAttributedString *newTextAttributed = [[NSMutableAttributedString alloc] initWithString: newText];
            NSUInteger prefixLength = prefix.length;
            NSUInteger fixedMessageLength = fixedMessage.length;
            
            // Set the prefix color
            if ([prefix isEqualToString:@"Error: "]) {
                [(NSMutableAttributedString *)newTextAttributed addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:235 / 255.0 green:0.0 blue:0.0 alpha:1.0] range:NSMakeRange(0, prefixLength)];
            } else {
                [(NSMutableAttributedString *)newTextAttributed addAttribute:NSForegroundColorAttributeName value:prefixColor range:NSMakeRange(0, prefixLength)];
            }
            
            // Set the rest of the new text to white
            [(NSMutableAttributedString *)newTextAttributed addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(prefixLength, fixedMessageLength)];
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                NSMutableAttributedString *currentConsoleText = [[NSMutableAttributedString alloc] initWithAttributedString:menuTextViewConsoleRef.attributedText];
                [currentConsoleText appendAttributedString: newTextAttributed];
                menuTextViewConsoleRef.attributedText = currentConsoleText;
                scrollConsoleOutputToBottom();
            });
        });
    };
    
    if ([NSThread isMainThread]) {
        consoleLogBlock();
    } else {
        // This prevents crashes when consoleLog is called simultaneously on different queues
        dispatch_async(dispatch_get_main_queue(), consoleLogBlock);
    }
}

void scrollConsoleOutputToBottom() {
	Menu *menu = [Menu singletonMenu];
	UITextView *menuTextViewConsoleRef = [menu getMenuTextViewConsoleRef];

	if (menuTextViewConsoleRef.text.length > 0 ) {
		NSRange bottom = NSMakeRange(menuTextViewConsoleRef.text.length - 1, 1);
        
        [UIView animateWithDuration:0.25 animations:^ {
            [menuTextViewConsoleRef scrollRangeToVisible:bottom];
        }];
	}
}

void scrollConsoleOutputToTop() {
    Menu* menu = [Menu singletonMenu];
    UITextView *menuTextViewConsoleRef = [menu getMenuTextViewConsoleRef];

    if(menuTextViewConsoleRef.text.length > 0 ) {
        NSRange top = NSMakeRange(0, 0);
        [UIView animateWithDuration:0.25 animations:^ {
            [menuTextViewConsoleRef scrollRangeToVisible:top];
        }];
    }
}

/*
Converts a byte array to a hex string.
*/	
NSString *byteArrayToHexString(unsigned char *byteArray, const int sizeInBytes) {
    // Preallocate otherwise it needs to constantly reallocate in the loop.
    NSMutableString *byteArrayAsHexString = [[NSMutableString alloc] initWithCapacity:(sizeInBytes * 3)];
    
    for (int i = 0; i < sizeInBytes; i++) {
        [byteArrayAsHexString appendFormat:@"%02x ", byteArray[i]];
    }

    // If too large for console output, it crashes. So only show 10000 first bytes. Find other way so show result (maybe save in a file).
    if (sizeInBytes > 10000) {
        byteArrayAsHexString = [[byteArrayAsHexString substringToIndex:10000 * 3] mutableCopy];
        [byteArrayAsHexString appendString:@"..."];
        consoleLog(@"Only the first 10000 bytes are shown in the console because the size is too big.");
    }
    
    return byteArrayAsHexString;
}

/*
Returns the size of bytes desired to read if it's a valid integer.
*/
int getSizeToReadIfValid(NSString *sizeAsString) {
	NSScanner *scanner = [NSScanner scannerWithString:sizeAsString];
	int result;
	BOOL success = [scanner scanInt:&result];
	
    if (success && [scanner isAtEnd]) {
        if (result > 0 && result <= 2147483647) {
            return result;
        }
	}
	
	return -1;
}

/*
Returns the size of the bytes pattern if it's the expected format.
*/
int getSizeOfBytesIfValid(NSString *bytesAsString) {
	NSRange regexRange = [bytesAsString rangeOfString:@"^(?:[0-9a-f]{2}\\s)*[0-9a-f]{2}(?:\\s[0-9a-f]{2})*$" options:NSRegularExpressionSearch];
    int size;
    
    if (regexRange.location == NSNotFound) {
        return -1;
    }
    
    size = (int)[[bytesAsString componentsSeparatedByString:@" "] count];
    
    if (size < 1 || size > 2147483647) {
        return -1;
    }
    
	return size;
}

/*
Makes sure that the input string is a valid address hex string format.
*/
bool validHexStringAddress(NSString *input) {
    if (!input || input.length == 0) {
        consoleLog(@"Error: ", @"The input address is null or empty. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6.");
        return false;
    }
    
    const char *cStr = [input UTF8String];
    int start = 0;
    
    if (input.length >= 2 && cStr[0] == '0' && (cStr[1] == 'x' || cStr[1] == 'X')) {
        start = 2;
        
        if (input.length < 3 || input.length > 18) {
            consoleLog(@"Error: ", @"The input address length is invalid. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6.");
            return false;
        }
    } else {
        if (input.length < 1 || input.length > 16) {
            consoleLog(@"Error: ", @"The input address length is invalid. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6.");
            return false;
        }
    }
    
    for (int i = start; i < input.length; i++) {
        char currentChar = cStr[i];
        bool isHexDigit =
            (currentChar >= '0' && currentChar <= '9') ||
            (currentChar >= 'a' && currentChar <= 'f') ||
            (currentChar >= 'A' && currentChar <= 'F');
        
        if (!isHexDigit) {
            consoleLog(@"Error: ", @"The input address is invalid. It must only contain hexadecimal characters. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6.");
            return false;
        }
    }
    
    return true;
}

/*
Converts a hex string address to a real vm_address_t (unsigned long). It can be used as a pointer to memory.
*/
vm_address_t hexStringAddressToAddress(NSString *inputHexStringAddress) {
    char *inputHexStringAddressUtf8 = (char *)[inputHexStringAddress UTF8String];
    unsigned long result = strtoul(inputHexStringAddressUtf8, NULL, 16);
    
    if (result != 0) {
        // consoleLog(@"My pointer: ", [NSString stringWithFormat:@"0x%lx", result]);
        return (vm_address_t) result;
    }
    
    if (errno == EINVAL) {
        consoleLog(@"Error: ", [NSString stringWithFormat:@"The input address is invalid. A conversion error occurred. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6. errno: %d (EINVAL)", errno]);
    } else if (errno == ERANGE) {
        consoleLog(@"Error: ", [NSString stringWithFormat:@"The input address is invalid. The value provided was out of range for the type unsigned long. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6. errno: %d (ERANGE)", errno]);
    } else {
        consoleLog(@"Error: ", [NSString stringWithFormat:@"The input address is invalid. Unknown error occurred. Make sure it looks like one of these formats: 0x123456789ABCDEF6, 0x123456789abcdef6, 123456789abcdef6. errno: %d", errno]);
    }
    
    return -1;
}

/*
S'assure que le string est un long positif pouvant être converti en hex jusqu'à 0xFFFFFFFFF.
*/
bool validLongStringValideForHexConversion(NSString *input, long *longOut) {
    if (longOut == NULL) {
        consoleLog(@"Error: ", @"The pointer to your long is NULL.");
        return false;
    }
    
    NSRange regexRange = [input rangeOfString:@"^[0-9]+$" options:NSRegularExpressionSearch];

    if (regexRange.location == NSNotFound) {
        consoleLog(@"Error: ", @"The value of the input must be a positive long value. No special characters or spaces. Ex: 68719476735.");
        return false;
    }
    
    try {
        *longOut = std::stol((char *)[input UTF8String], 0, 10);
    } catch (const std::invalid_argument & e) {
        consoleLog(@"Error: ", @"The value of the input must be a positive long value. No special characters or spaces. Ex: 68719476735.");
        return false;
    } catch (const std::out_of_range & e) {
        consoleLog(@"Error: ", @"The value of the input must be a positive long value. Ex: 68719476735.");
        return false;
    }

    return true;
}

/*
Converts astring of bytes separated by spaces to a NSMutableData object.
*/
NSMutableData *bytesStringToDataObject(NSString *validBytesString) {
    NSString *strippedString = [validBytesString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *data = [[NSMutableData alloc] init];
    
    for (int i = 0; i < strippedString.length; i += 2) {
        NSString *byteString = [strippedString substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:byteString];
        unsigned int byteValue;
        
        if ([scanner scanHexInt:&byteValue]) {
            uint8_t byte = (uint8_t)byteValue;
            [data appendBytes:&byte length:1];
        }
    }
    
    return data;
}
