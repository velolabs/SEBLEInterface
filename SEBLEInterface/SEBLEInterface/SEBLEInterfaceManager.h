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

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
                 peripheral:(SEBLEPeripheral *)peripheral
changedUpdateStateForCharacteristic:(NSString *)characteristicUUID;

@end

@interface SEBLEInterfaceMangager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak) id<SEBLEInterfaceManagerDelegate>delegate;

+ (id)sharedManager;
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
- (void)setDeviceNamesToConnectTo:(NSSet *)namesToConnect;
- (void)setDeviceNameFragmentsToConnect:(NSArray *)fragmentsToConnect;
- (void)setServiceToReadFrom:(NSSet *)serviceNames;
- (void)setCharacteristicsToReadFrom:(NSSet *)characteristicsToRead;
- (void)setCharacteristicsToReceiveNotificationsFrom:(NSSet *)notificationsToRecieve;
- (void)setServicesToNotifyWhenTheyAreDiscoverd:(NSSet *)servicesToNotify;
- (void)readValueForPeripheralNamed:(NSString *)peripheralName
                     forServiceUUID:(NSString *)serviceUUID
              andCharacteristicUUID:(NSString *)characteristicUUID;
- (void)updateConnectPeripheralKey:(NSString *)oldKey newKey:(NSString *)newKey;

/*
 * not connected peripheral methods
 */
- (void)setNotConnectedPeripheral:(SEBLEPeripheral *)seblePeripheral forKey:(NSString *)key;
- (void)removeNotConnectPeripheralForKey:(NSString *)key;
- (BOOL)notConnectPeripheralsHasPeripheralForKey:(NSString *)key;

/*
 * connect peripheral methods
 */
- (void)setConnectedPeripheral:(SEBLEPeripheral *)seblePeripheral forKey:(NSString *)key;
- (void)removeConnectPeripheralForKey:(NSString *)key;
- (BOOL)connectPeripheralsHasPeripheralForKey:(NSString *)key;
// remove me...just for testing
- (void)runTests;

@end
