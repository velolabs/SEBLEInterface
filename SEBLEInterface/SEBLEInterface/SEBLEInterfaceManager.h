//
//  SEBLEInterfaceManager.h
//  SEBLEInterface
//
//  Created by Andre Green on 6/14/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;
@import QuartzCore;

@class SEBLEInterfaceMangager;

@protocol SEBLEInterfaceManagerDelegate <NSObject>

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager didUpdateDeviceValues:(NSDictionary *)values;
- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManger discoveredPeriphealWithInfo:(NSDictionary *)info;
- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager connectedPeripheralNamed:(NSString *)peripheralName;


@end

@interface SEBLEInterfaceMangager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak) id<SEBLEInterfaceManagerDelegate>delegate;

+ (id)manager;
- (void)addDeviceWithUDID:(NSString *)UDID;
- (void)removeDeviceWithUDID:(NSString *)UDID;
- (BOOL)writeToDeviveWithUDID:(NSString *)UDID data:(u_int8_t)data;

// remove me...just for testing
- (void)runTests;
@end
