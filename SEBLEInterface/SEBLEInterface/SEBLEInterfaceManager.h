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

- (void)bleInterfaceManagerIsPoweredOn:(SEBLEInterfaceMangager *)interfaceManager;

- (void)bleInterfaceManagerIsPoweredOff:(SEBLEInterfaceMangager *)interfaceManager;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
     updatedPeripheralNamed:(NSString *)peripheralName
      forCharacteristicUUID:(NSString *)characteristicUUID
                   withData:(NSData *)data;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManger
       discoveredPeripheral:(SEBLEPeripheral *)peripheral
       withAdvertisemntData:(NSDictionary *)advertisementData;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
        connectedPeripheralNamed:(NSString *)peripheralName;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager discoveredServicesForPeripheralNamed:(NSString *)peripheralName;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
discoveredCharacteristicsForService:(CBService *)service
         forPeripheralNamed:(NSString *)peripheralName;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
     disconnectedPeripheralNamed:(NSString *)peripheralName;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
             peripheralName:(NSString *)peripheralName
changedUpdateStateForCharacteristic:(NSString *)characteristicUUID;

- (void)bleInterfaceManager:(SEBLEInterfaceMangager *)interfaceManager
wroteValueToPeripheralNamed:(NSString *)peripheralName
                    forUUID:(NSString *)uuid
           withWriteSuccess:(BOOL)success;
@end

@interface SEBLEInterfaceMangager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, weak) id<SEBLEInterfaceManagerDelegate>delegate;

+ (id)sharedManager;
- (void)connectToPeripheralWithKey:(NSString *)key;
- (void)removePeripheralForKey:(NSString *)key;
- (void)removeConnectedPeripheralForKey:(NSString *)key;
- (void)writeToPeripheralWithKey:(NSString *)key
                     serviceUUID:(NSString *)serviceUUID
              characteristicUUID:(NSString *)characteristicUUID
                            data:(NSData *)data;
- (void)readValueForPeripheralWithKey:(NSString *)key
                       forServiceUUID:(NSString *)serviceUUID
                andCharacteristicUUID:(NSString *)characteristicUUID;
- (void)startScan;
- (void)stopScan;
- (BOOL)isCurrentlyScanning;
- (void)powerOn;
- (BOOL)isPowerOn;
- (void)removeNotConnectPeripherals;
- (void)setDeviceNamesToConnectTo:(NSSet *)namesToConnect;
- (void)setDeviceNameFragmentsToConnect:(NSArray *)fragmentsToConnect;
- (void)setServiceToReadFrom:(NSSet *)serviceNames;
- (void)setCharacteristicsToReadFrom:(NSSet *)characteristicsToRead;
- (void)setCharacteristicsToReceiveNotificationsFrom:(NSSet *)notificationsToRecieve;
- (void)setServicesToNotifyWhenTheyAreDiscoverd:(NSSet *)servicesToNotify;

- (void)updateConnectPeripheralKey:(NSString *)oldKey newKey:(NSString *)newKey;
- (void)discoverServicesForPeripheralKey:(NSString *)key;
- (void)discoverCharacteristicsForService:(CBService *)service forPeripheralKey:(NSString *)key;
- (BOOL)hasNonConnectedPeripheralWithKey:(NSString *)key;
- (BOOL)hasConnectedPeripheralWithKey:(NSString *)key;
- (void)setCharacteristicUUIDToNotify:(NSString *)uuid forPeripheralWithKey:(NSString *)key;
/*
 * not connected peripheral methods
 */
- (void)setNotConnectedPeripheral:(SEBLEPeripheral *)blePeripheral forKey:(NSString *)key;
- (void)removeNotConnectPeripheralForKey:(NSString *)key;
- (SEBLEPeripheral *)notConnectedPeripheralForKey:(NSString *)key;

/*
 * connect peripheral methods
 */
- (void)disconnectFromPeripheralWithKey:(NSString *)key;
- (void)setConnectedPeripheral:(SEBLEPeripheral *)seblePeripheral forKey:(NSString *)key;
- (void)discoverServices:(NSArray *)services forPeripheralWithKey:(NSString *)key;

@end
