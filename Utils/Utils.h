#import "../Menu/Menu.h"
#import "UIKit/UIKit.h"

#include <string.h>
#include <inttypes.h>
#include <stdbool.h>
#include <iostream>

@interface Utils : NSObject
@end

void consoleLog(NSString *prefix);
void consoleLog(NSString *prefix, NSString *message);
NSString *adjustInputAddressFormat(NSString* inputeAddress);
NSString *byteArrayToHexString(unsigned char *byteArray, const int sizeInBytes);
int getSizeToReadIfValid(NSString *sizeAsString);
int getSizeOfBytesIfValid(NSString *bytesAsString);
bool validHexStringAddress(NSString *input);
vm_address_t hexStringAddressToAddress(NSString *inputHexStringAddress);
bool validLongStringValideForHexConversion(NSString *input, long *longOut);
void scrollConsoleOutputToBottom();
void scrollConsoleOutputToTop();
NSMutableData *bytesStringToDataObject(NSString *validBytesString);
