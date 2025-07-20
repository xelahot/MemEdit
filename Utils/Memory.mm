#import "Memory.h"
#import "Utils.h"
#import "UIKit/UIKit.h"
#import <Foundation/Foundation.h>

#include <substrate.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>  
#include <mach-o/getsect.h>
#include <unistd.h>

static vm_size_t pageSize = 0;

/*
This Function checks if the Application has ASLR enabled.
It gets the mach_header of the Image at Index 0.
It then checks for the MH_PIE flag. If it is there, it returns TRUE.
Parameters: nil
Return: Wether it has ASLR or not
*/
bool hasAslr() {
    // Assume ASLR is enabled for now (it almost always is)
    return true;
	
	//TODO: Should find the image of the address, get the mach_header then check if ASLR is enabled for that image?
	/*const struct mach_header *mach;
    mach = _dyld_get_image_header(0);

    if (mach->flags & MH_PIE) {
        //has aslr enabled
        return true;
    } else {
        //has aslr disabled
        return false;
    }*/
}

/*
This function gets the slide. It's the offset when comparing the binary statically vs at runtime.
*/
uintptr_t get_slide(bool logDetails) {
    uintptr_t slide = 0;
	char path[1024];
    uint32_t size = sizeof(path);
		
    if (_NSGetExecutablePath(path, &size) == 0) {
		if (logDetails) {
			consoleLog(@"Name of executable for slide: ", [NSString stringWithFormat:@"%s", (char *)path]);
		}
		
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            if (strcmp(_dyld_get_image_name(i), path) == 0) {
                slide = _dyld_get_image_vmaddr_slide(i);
            }
	    }
    }
	
    return slide;
}

/*
Get the start address of the main executable's __TEXT segment.
*/
uint64_t getStartAddressOfMainExecutableSegmentByName(char *segmentName) {
	uint64_t dynamicStartOfSegment = 0;
	const struct segment_command_64 *command = getsegbyname(segmentName);
    uint64_t staticStartOfSegment = command->vmaddr;
	uintptr_t slide = get_slide(true);
    dynamicStartOfSegment = staticStartOfSegment + slide;
	return dynamicStartOfSegment;
}

/*
Get the size of the main executable's __TEXT segment.
*/
uint64_t getSizeOfMainExecutableTextSegment() {
	const struct segment_command_64 *command = getsegbyname("__TEXT");
	return (uint64_t)(command->vmsize);
}

/*
This Function calculates the address if ASLR is enabled or returns the normal offset.
Parameters: The original offset
Return: Either the offset or the new calculated offset if ASLR is enabled
*/
uintptr_t staticToDynamicAddress(uintptr_t address) {
	if (hasAslr()) {
		uintptr_t slide = get_slide(false);
        return (slide + address);
    } else {
        return address;
    }
}

/*
Converts a kern_return_t to a readable string. Maybe use mach_error_string(kr) from mach/mach.h instead.
*/
NSString *kernelErrorAsString(kern_return_t error) {
    NSString *errorAsString;
    
    switch (error) {
        case KERN_INVALID_ADDRESS:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_ADDRESS (%d): %@", error, @"Specified address is not currently valid."];
            break;
        case KERN_PROTECTION_FAILURE:
            errorAsString = [NSString stringWithFormat:@"KERN_PROTECTION_FAILURE (%d): %@", error, @"Specified memory is valid, but does not permit the required forms of access."];
            break;
        case KERN_NO_SPACE:
            errorAsString = [NSString stringWithFormat:@"KERN_NO_SPACE (%d): %@", error, @"The address range specified is already in use, or no address range of the size specified could be found."];
            break;
        case KERN_INVALID_ARGUMENT:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_ARGUMENT (%d): %@", error, @"The function requested was not applicable to this type of argument, or an argument is invalid."];
            break;
        case KERN_FAILURE:
            errorAsString = [NSString stringWithFormat:@"KERN_FAILURE (%d): %@", error, @"The function could not be performed.  A catch-all."];
            break;
        case KERN_RESOURCE_SHORTAGE:
            errorAsString = [NSString stringWithFormat:@"KERN_RESOURCE_SHORTAGE (%d): %@", error, @"A system resource could not be allocated to fulfill this request.  This failure may not be permanent."];
            break;
        case KERN_NOT_RECEIVER:
            errorAsString = [NSString stringWithFormat:@"KERN_NOT_RECEIVER (%d): %@", error, @"The task in question does not hold receive rights for the port argument."];
            break;
        case KERN_NO_ACCESS:
            errorAsString = [NSString stringWithFormat:@"KERN_NO_ACCESS (%d): %@", error, @"Bogus access restriction."];
            break;
        case KERN_MEMORY_FAILURE:
            errorAsString = [NSString stringWithFormat:@"KERN_MEMORY_FAILURE (%d): %@", error, @"During a page fault, the target address refers to a memory object that has been destroyed. This failure is permanent."];
            break;
        case KERN_MEMORY_ERROR:
            errorAsString = [NSString stringWithFormat:@"KERN_MEMORY_ERROR (%d): %@", error, @"During a page fault, the memory object indicated that the data could not be returned.  This failure may be temporary; future attempts to access this same data may succeed, as defined by the memory object."];
            break;
        case KERN_ALREADY_IN_SET:
            errorAsString = [NSString stringWithFormat:@"KERN_ALREADY_IN_SET (%d): %@", error, @"The receive right is already a member of the portset."];
            break;
        case KERN_NOT_IN_SET:
            errorAsString = [NSString stringWithFormat:@"KERN_NOT_IN_SET (%d): %@", error, @"The receive right is not a member of a port set."];
            break;
        case KERN_NAME_EXISTS:
            errorAsString = [NSString stringWithFormat:@"KERN_NAME_EXISTS (%d): %@", error, @"The name already denotes a right in the task."];
            break;
        case KERN_ABORTED:
            errorAsString = [NSString stringWithFormat:@"KERN_ABORTED (%d): %@", error, @"The operation was aborted.  Ipc code will catch this and reflect it as a message error."];
            break;
        case KERN_INVALID_NAME:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_NAME (%d): %@", error, @"The name doesn't denote a right in the task."];
            break;
        case KERN_INVALID_TASK:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_TASK (%d): %@", error, @"Target task isn't an active task."];
            break;
        case KERN_INVALID_RIGHT:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_RIGHT (%d): %@", error, @"The name denotes a right, but not an appropriate right."];
            break;
        case KERN_INVALID_VALUE:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_VALUE (%d): %@", error, @"A blatant range error."];
            break;
        case KERN_UREFS_OVERFLOW:
            errorAsString = [NSString stringWithFormat:@"KERN_UREFS_OVERFLOW (%d): %@", error, @"Operation would overflow limit on user-references."];
            break;
        case KERN_INVALID_CAPABILITY:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_CAPABILITY (%d): %@", error, @"The supplied (port) capability is improper."];
            break;
        case KERN_RIGHT_EXISTS:
            errorAsString = [NSString stringWithFormat:@"KERN_RIGHT_EXISTS (%d): %@", error, @"The task already has send or receive rights for the port under another name."];
            break;
        case KERN_INVALID_HOST:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_HOST (%d): %@", error, @"Target host isn't actually a host."];
            break;
        case KERN_MEMORY_PRESENT:
            errorAsString = [NSString stringWithFormat:@"KERN_MEMORY_PRESENT (%d): %@", error, @"An attempt was made to supply \"precious\" data for memory that is already present in a memory object."];
            break;
        case KERN_MEMORY_DATA_MOVED:
            errorAsString = [NSString stringWithFormat:@"KERN_MEMORY_DATA_MOVED (%d): %@", error, @"A page was requested of a memory manager via memory_object_data_request for an object using a MEMORY_OBJECT_COPY_CALL strategy, with the VM_PROT_WANTS_COPY flag being used to specify that the page desired is for a copy of the object, and the memory manager has detected the page was pushed into a copy of the object while the kernel was walking the shadow chain from the copy to the object. This error code is delivered via memory_object_data_error and is handled by the kernel (it forces the kernel to restart the fault). It will not be seen by users."];
            break;
        case KERN_MEMORY_RESTART_COPY:
            errorAsString = [NSString stringWithFormat:@"KERN_MEMORY_RESTART_COPY (%d): %@", error, @"A strategic copy was attempted of an object upon which a quicker copy is now possible. The caller should retry the copy using vm_object_copy_quickly. This error code is seen only by the kernel."];
            break;
        case KERN_INVALID_PROCESSOR_SET:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_PROCESSOR_SET (%d): %@", error, @"An argument applied to assert processor set privilege was not a processor set control port."];
            break;
        case KERN_POLICY_LIMIT:
            errorAsString = [NSString stringWithFormat:@"KERN_POLICY_LIMIT (%d): %@", error, @"The specified scheduling attributes exceed the thread's limits."];
            break;
        case KERN_INVALID_POLICY:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_POLICY (%d): %@", error, @"The specified scheduling policy is not currently enabled for the processor set."];
            break;
        case KERN_INVALID_OBJECT:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_OBJECT (%d): %@", error, @"The external memory manager failed to initialize the memory object."];
            break;
        case KERN_ALREADY_WAITING:
            errorAsString = [NSString stringWithFormat:@"KERN_ALREADY_WAITING (%d): %@", error, @"A thread is attempting to wait for an event for which there is already a waiting thread."];
            break;
        case KERN_DEFAULT_SET:
            errorAsString = [NSString stringWithFormat:@"KERN_DEFAULT_SET (%d): %@", error, @"An attempt was made to destroy the default processor set."];
            break;
        case KERN_EXCEPTION_PROTECTED:
            errorAsString = [NSString stringWithFormat:@"KERN_EXCEPTION_PROTECTED (%d): %@", error, @"An attempt was made to fetch an exception port that is protected, or to abort a thread while processing a protected exception."];
            break;
        case KERN_INVALID_LEDGER:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_LEDGER (%d): %@", error, @"A ledger was required but not supplied."];
            break;
        case KERN_INVALID_MEMORY_CONTROL:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_MEMORY_CONTROL (%d): %@", error, @"The port was not a memory cache control port."];
            break;
        case KERN_INVALID_SECURITY:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_SECURITY (%d): %@", error, @"An argument supplied to assert security privilege was not a host security port."];
            break;
        case KERN_NOT_DEPRESSED:
            errorAsString = [NSString stringWithFormat:@"KERN_NOT_DEPRESSED (%d): %@", error, @"thread_depress_abort was called on a thread which was not currently depressed."];
            break;
        case KERN_TERMINATED:
            errorAsString = [NSString stringWithFormat:@"KERN_TERMINATED (%d): %@", error, @"Object has been terminated and is no longer available."];
            break;
        case KERN_LOCK_SET_DESTROYED:
            errorAsString = [NSString stringWithFormat:@"KERN_LOCK_SET_DESTROYED (%d): %@", error, @"Lock set has been destroyed and is no longer available."];
            break;
        case KERN_LOCK_UNSTABLE:
            errorAsString = [NSString stringWithFormat:@"KERN_LOCK_UNSTABLE (%d): %@", error, @"The thread holding the lock terminated before releasing the lock"];
            break;
        case KERN_LOCK_OWNED:
            errorAsString = [NSString stringWithFormat:@"KERN_LOCK_OWNED (%d): %@", error, @"The lock is already owned by another thread"];
            break;
        case KERN_LOCK_OWNED_SELF:
            errorAsString = [NSString stringWithFormat:@"KERN_LOCK_OWNED_SELF (%d): %@", error, @"The lock is already owned by the calling thread"];
            break;
        case KERN_SEMAPHORE_DESTROYED:
            errorAsString = [NSString stringWithFormat:@"KERN_SEMAPHORE_DESTROYED (%d): %@", error, @"Semaphore has been destroyed and is no longer available."];
            break;
        case KERN_RPC_SERVER_TERMINATED:
            errorAsString = [NSString stringWithFormat:@"KERN_RPC_SERVER_TERMINATED (%d): %@", error, @"Return from RPC indicating the target server was terminated before it successfully replied."];
            break;
        case KERN_RPC_TERMINATE_ORPHAN:
            errorAsString = [NSString stringWithFormat:@"KERN_RPC_TERMINATE_ORPHAN (%d): %@", error, @"Terminate an orphaned activation."];
            break;
        case KERN_RPC_CONTINUE_ORPHAN:
            errorAsString = [NSString stringWithFormat:@"KERN_RPC_CONTINUE_ORPHAN (%d): %@", error, @"Allow an orphaned activation to continue executing."];
            break;
        case KERN_NOT_SUPPORTED:
            errorAsString = [NSString stringWithFormat:@"KERN_NOT_SUPPORTED (%d): %@", error, @"Empty thread activation (No thread linked to it)"];
            break;
        case KERN_NODE_DOWN:
            errorAsString = [NSString stringWithFormat:@"KERN_NODE_DOWN (%d): %@", error, @"Remote node down or inaccessible."];
            break;
        case KERN_NOT_WAITING:
            errorAsString = [NSString stringWithFormat:@"KERN_NOT_WAITING (%d): %@", error, @"A signalled thread was not actually waiting."];
            break;
        case KERN_OPERATION_TIMED_OUT:
            errorAsString = [NSString stringWithFormat:@"KERN_OPERATION_TIMED_OUT (%d): %@", error, @"Some thread-oriented operation (semaphore_wait) timed out"];
            break;
        case KERN_CODESIGN_ERROR:
            errorAsString = [NSString stringWithFormat:@"KERN_CODESIGN_ERROR (%d): %@", error, @"During a page fault, indicates that the page was rejected as a result of a signature check."];
            break;
        case KERN_POLICY_STATIC:
            errorAsString = [NSString stringWithFormat:@"KERN_POLICY_STATIC (%d): %@", error, @"The requested property cannot be changed at this time."];
            break;
        case KERN_INSUFFICIENT_BUFFER_SIZE:
            errorAsString = [NSString stringWithFormat:@"KERN_INSUFFICIENT_BUFFER_SIZE (%d): %@", error, @"The provided buffer is of insufficient size for the requested data."];
            break;
        case KERN_DENIED:
            errorAsString = [NSString stringWithFormat:@"KERN_DENIED (%d): %@", error, @"Denied by security policy"];
            break;
        case KERN_MISSING_KC:
            errorAsString = [NSString stringWithFormat:@"KERN_MISSING_KC (%d): %@", error, @"The KC on which the function is operating is missing."];
            break;
        case KERN_INVALID_KC:
            errorAsString = [NSString stringWithFormat:@"KERN_INVALID_KC (%d): %@", error, @"The KC on which the function is operating is invalid."];
            break;
        case KERN_RETURN_MAX:
            errorAsString = [NSString stringWithFormat:@"KERN_RETURN_MAX (%d): %@", error, @"Maximum return value allowable."];
            break;
        default:
            errorAsString = [NSString stringWithFormat:@"Unknown kern_return_t (%d).", error];
    }
    
    return errorAsString;
}

/*
Converts a vm_prot_t to a readable string.
*/
NSString *vmProtAsString(vm_prot_t prot) {
    NSString *protAsString;
    
    switch (prot) {
        case 0x00:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_NONE"];
            break;
        case 0x01:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_READ"];
            break;
        case 0x02:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_WRITE"];
            break;
        case 0x04:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_EXECUTE"];
            break;
        case 0x05:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_READ | VM_PROT_EXECUTE"];
            break;
        case 0x03:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_DEFAULT a.k.a. (VM_PROT_READ | VM_PROT_WRITE)"];
            break;
        case 0x07:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_ALL a.k.a. (VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE)"];
            break;
        case 0x08:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_NO_CHANGE"];
            break;
        case 0x10:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_COPY a.k.a VM_PROT_WANTS_COPY"];
            break;
        case 0x12:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_WRITE | VM_PROT_COPY"];
            break;
        case 0x17:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_COPY | VM_PROT_WRITE | (VM_PROT_READ | VM_PROT_EXECUTE)"];
            break;
        case 0x20:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_TRUSTED"];
            break;
        case 0x40:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_IS_MASK"];
            break;
        case 0x80:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_STRIP_READ"];
            break;
        case 0x84:
            protAsString = [NSString stringWithFormat:@"0x%02x: %@", prot, @"VM_PROT_EXECUTE_ONLY a.k.a (VM_PROT_EXECUTE | VM_PROT_STRIP_READ)"];
            break;
        default:
            protAsString = [NSString stringWithFormat:@"0x%02x: Unknown vm_prot_t", prot];
    }
    
    return protAsString;
}

void initialize_page_size() {
    if (pageSize == 0) {
        host_page_size(mach_host_self(), &pageSize);
    }
}

bool prepare_memory_access(vm_address_t rangeStart, int size, vm_prot_t requiredProtection, RegionProtectionBackup *backups, int *backupCount) {
    *backupCount = 0;
    vm_address_t rangeEnd = rangeStart + size;
    vm_address_t currentAddress = rangeStart;
    natural_t depth = 0;

    // Iterate regions of contiguous pages (pages with the same protections next to each other)
    while (currentAddress < rangeEnd) {
        vm_address_t regionStart = currentAddress;
        vm_size_t regionSize = 0;
        vm_region_submap_info_data_64_t regionInfo;
        mach_msg_type_number_t infoCount = VM_REGION_SUBMAP_INFO_COUNT_64;

        kern_return_t kr = vm_region_recurse_64(
            mach_task_self(),
            (vm_address_t *)&regionStart,
            (vm_size_t *)&regionSize,
            &depth, // Unused
            (vm_region_info_t)&regionInfo,
            &infoCount
        );

        if (kr != KERN_SUCCESS) {
            consoleLog(@"Error: ", [NSString stringWithFormat:@"vm_region_recurse_64 failed for region at 0x%lx. %@", currentAddress, kernelErrorAsString(kr)]);
            return false;
        }

        if (regionStart > currentAddress) {
            consoleLog(@"Error: ", [NSString stringWithFormat:@"The provided address is invalid or the size goes outside your process. Problematic region is from 0x%lx to 0x%lx. ", currentAddress, regionStart]);
            return false;
        }
        
        vm_address_t regionEnd = regionStart + regionSize;
        vm_address_t pageAddress = currentAddress;
        //consoleLog([NSString stringWithFormat:@"Scanning a region from 0x%lx to 0x%lx. Current protections: 0x%x.", regionStart, regionEnd, regionInfo.protection]);

        // Iterate page-by-page within this region (protections are handled per page even though vm_protect can handle regions)
        while (pageAddress < regionEnd && pageAddress < rangeEnd) {
            //consoleLog([NSString stringWithFormat:@"Scanning a region's page at 0x%lx. Current protections: 0x%x.", pageAddress, regionInfo.protection]);
            vm_prot_t currentProt = regionInfo.protection;
            vm_prot_t maxProt = regionInfo.max_protection;
            
            // This only keeps bits that are present in both currentProt and requiredProtection. So if if the requiredProtections are not already there, we should add them
            if ((currentProt & requiredProtection) != requiredProtection) {
                consoleLog([NSString stringWithFormat:@"Insufficient protections for page at 0x%lx.", pageAddress]);
                consoleLog([NSString stringWithFormat:@"Required protections are: %@.", vmProtAsString(requiredProtection)]);
                consoleLog([NSString stringWithFormat:@"Current protections are: %@.", vmProtAsString(currentProt)]);
                consoleLog([NSString stringWithFormat:@"Maximum protections are: %@", vmProtAsString(maxProt)]);
                backups[*backupCount].address = pageAddress;
                backups[*backupCount].originalProtection = currentProt;
                (*backupCount)++;
                
                kern_return_t protKr = vm_protect(
                    mach_task_self(),
                    pageAddress,
                    pageSize,
                    false,
                    currentProt | requiredProtection
                );

                if (protKr != KERN_SUCCESS) {
                    consoleLog(@"Error: ", [NSString stringWithFormat:@"vm_protect failed. %@", kernelErrorAsString(protKr)]);
                    return false;
                }

                consoleLog([NSString stringWithFormat:@"New protections are: %@", vmProtAsString(currentProt | requiredProtection)]);
            } else {
                //consoleLog([NSString stringWithFormat:@"Protections for page at 0x%lx already correct. Current protections are: %@.", pageAddress, vmProtAsString(currentProt)]);
            }

            // Move to the next page
            pageAddress += pageSize;
        }

        // Move to the next region
        currentAddress = regionEnd;
    }
    
    return true;
}

void restore_memory_protections(RegionProtectionBackup *backups, int backupsCount) {
    if (pageSize == 0) {
        consoleLog(@"Error: ", @"restore_memory_protections called before page size initialized.");
        return;
    }

    for (int i = 0; i < backupsCount; i++) {
        vm_address_t address = backups[i].address;
        vm_prot_t protection = backups[i].originalProtection;
        
        kern_return_t kr = vm_protect(mach_task_self(), address, pageSize, false, protection);
        
        if (kr != KERN_SUCCESS) {
            consoleLog([NSString stringWithFormat:@"Warning: Failed to restore protections for page at 0x%lx. %@", address, kernelErrorAsString(kr)]);
        } else {
            consoleLog([NSString stringWithFormat:@"Restored protections for page at 0x%lx. Restored protections are: %@.", address, vmProtAsString(protection)]);
        }
    }
}

bool safe_write_bytes(vm_address_t address, NSMutableData *data) {
    int size = (int)[data length];
    consoleLog([NSString stringWithFormat:@"Size of data is: %d.", size]);
    initialize_page_size();
    int maxBackups = (size / pageSize) + 4;
    int backupCount = 0;
    RegionProtectionBackup *backups = (RegionProtectionBackup *)malloc(sizeof(RegionProtectionBackup) * maxBackups);
    
    if (!backups) {
        consoleLog(@"Error: ", @"Failed to allocate memory for protection backups.");
        return false;
    }
    
    if (prepare_memory_access(address, size, VM_PROT_WRITE | VM_PROT_COPY, backups, &backupCount)) {
        kern_return_t kr = vm_write(mach_task_self(), address, (vm_offset_t)[data bytes], (vm_size_t)size);
        
        if (kr != KERN_SUCCESS) {
            consoleLog(@"Error: ", [NSString stringWithFormat:@"vm_write failed. %@", kernelErrorAsString(kr)]);
            free(backups);
            return false;
        }
    } else {
        free(backups);
        return false;
    }

    restore_memory_protections(backups, backupCount);
    free(backups);
    return true;
}

bool safe_read_bytes(vm_address_t address, unsigned char *output, int size) {
    initialize_page_size();
    int maxBackups = (size / pageSize) + 4;
    int backupCount = 0;
    RegionProtectionBackup *backups = (RegionProtectionBackup *)malloc(sizeof(RegionProtectionBackup) * maxBackups);
    mach_port_t task = mach_task_self();
    vm_offset_t vmReadOutMem = 0;
    mach_msg_type_number_t vmReadOutSize = 0;
    
    if (!backups) {
        consoleLog(@"Error: ", @"Failed to allocate memory for protection backups.");
        return false;
    }
    if (prepare_memory_access(address, size, VM_PROT_READ, backups, &backupCount)) {
        kern_return_t kr = vm_read(task, address, (vm_size_t)size, &vmReadOutMem, &vmReadOutSize);
        
        if (kr != KERN_SUCCESS) {
            consoleLog(@"Error: ", [NSString stringWithFormat:@"vm_read failed. %@", kernelErrorAsString(kr)]);
            free(backups);
            return false;
        }
    } else {
        free(backups);
        return false;
    }

    memcpy(output, (void *)(uintptr_t)vmReadOutMem, vmReadOutSize);
    vm_deallocate(task, vmReadOutMem, vmReadOutSize);
    restore_memory_protections(backups, backupCount);
    free(backups);
    return true;
}
