#import "Utils.h"
#import "UIKit/UIKit.h"
#import <Foundation/Foundation.h>

#include <substrate.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>  
#include <mach-o/getsect.h>

typedef struct {
    vm_address_t address;
    vm_prot_t originalProtection;
} RegionProtectionBackup;

@interface Memory : NSObject
@end

bool hasASLR();
uintptr_t get_slide(bool logDetails);
uint64_t getStartAddressOfMainExecutableSegmentByName(char *segmentName);
uint64_t getSizeOfMainExecutableTextSegment();
uintptr_t staticToDynamicAddress(uintptr_t address);
bool addressAndSizeFitInProcessRegion(void *ptr, int size);
bool readMemory(vm_address_t address, unsigned char *output, const int sizeInBytes);
bool safe_write_bytes(vm_address_t address, NSMutableData *data);
void initialize_page_size();
bool prepare_memory_access(vm_address_t rangeStart, int size, vm_prot_t requiredProtection, RegionProtectionBackup *backups, int *backupCount);
void restore_memory_protections(RegionProtectionBackup *backups, int backupsCount);
bool safe_write_bytes(vm_address_t address, NSString *bytesToWrite);
bool safe_read_bytes(vm_address_t address, unsigned char *buffer, int size);
