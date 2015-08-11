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
@class SEBLEPeripheral;

@protocol SEBLEInterfaceManagerDelegate <NSObject>

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
          updatedPeripheral:(SEBLEPeripheral *)peripheral
      forCharacteristicUUID:(NSString *)characteristicUUID
                   withData:(NSData *)data;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManger
       discoveredPeripheral:(SEBLEPeripheral *)peripheral;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
        connectedPeripheral:(SEBLEPeripheral *)peripheral;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
     disconnectedPeripheral:(SEBLEPeripheral *)peripheral;

- (void)bleInterfaceManagerIsPoweredOn:(SEBLEInterfaceMangager *)interfaceManager;

@end

@interface SEBLEInterfaceMangager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak) id<SEBLEInterfaceManagerDelegate>delegate;

+ (id)manager;
- (void)addPeripheralNamed:(NSString *)name;
- (void)removePeripheralNamed:(NSString *)name;
- (void)writeToPeripheralWithName:(NSString *)peripheralName
                      serviceUUID:(NSString *)serviceUUID
               characteristicUUID:(NSString *)characteristicUUID
                             data:(NSData *)data;
- (void)startScan;
- (void)stopScan;
- (void)powerOn;
- (void)removeNotConnectPeripherals;
- (void)setDeviceNamesToConnectTo:(NSArray *)namesToConnect;
- (void)setServiceToReadFrom:(NSSet *)serviceNames;
- (void)setCharacteristicsToReadFrom:(NSSet *)characteristicsToRead;
- (void)setCharacteristicsToReceiveNotificationsFrom:(NSSet *)notificationsToRecieve;
- (void)readValueForPeripheralNamed:(NSString *)peripheralName
                     forServiceUUID:(NSString *)serviceUUID
              andCharacteristicUUID:(NSString *)characteristicUUID;

// remove me...just for testing
- (void)runTests;
@end
