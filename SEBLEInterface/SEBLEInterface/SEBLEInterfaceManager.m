//
//  SEBLEInterfaceManager.m
//  SEBLEInterface
//
//  Created by Andre Green on 6/14/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "SEBLEInterfaceManager.h"
#import "SEBLEPeripheral.h"


#define kSEBLEInterfaceSubscribedServices   @"kSEBLEInterfaceSubscribedServices"
#define kSEBLEInterfaceDataLocalName        @"kCBAdvDataLocalName"
#define kSEBLEInterfaceDataServiceUUIDs     @"kCBAdvDataServiceUUIDs"
#define kSEBLEInterfacePeripheral           @"kSEBLEInterfacePeripheral"
#define kSEBLEInterfaceIdentifier           @"SEBLEInterfaceIdentifier"
#define kSEBLEInterfaceQueueIdentifier      "kSEBLEInterfaceQueueIdentifier"

@interface SEBLEInterfaceMangager()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableDictionary *notConnectedPeripherals;
@property (nonatomic, strong) NSMutableDictionary *connectedPeripherals;
@property (nonatomic, strong) NSSet *namesToConnectAutomatically;
@property (nonatomic, strong) NSSet *connectToNames;
@property (nonatomic, strong) NSArray *fragmentsToConnect;
@property (nonatomic, strong) NSSet *charToRead;
@property (nonatomic, strong) NSSet *servicesToRead;
@property (nonatomic, strong) NSSet *charToNotifiy;
@property (nonatomic, strong) NSSet *servicesToNotifyWhenDiscoverd;
@property (nonatomic, strong) NSArray *restoredPeripherals;

@end

@implementation SEBLEInterfaceMangager

- (id)init
{
    self = [super init];
    if (self) {
        dispatch_queue_t centralQueue = dispatch_queue_create(kSEBLEInterfaceQueueIdentifier, DISPATCH_QUEUE_CONCURRENT);
        NSDictionary *options = @{CBCentralManagerOptionRestoreIdentifierKey: kSEBLEInterfaceIdentifier,
                                  CBCentralManagerOptionShowPowerAlertKey: @(YES)
                                  };
        _centralManager                 = [[CBCentralManager alloc] initWithDelegate:self
                                                                               queue:centralQueue
                                                                             options:options];
        _notConnectedPeripherals        = [NSMutableDictionary new];
        _connectedPeripherals           = [NSMutableDictionary new];
    }
    
    return self;
}

+ (id)sharedManager
{
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    static SEBLEInterfaceMangager *bleManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleManager = [[self alloc] init];
    });
    
    return bleManager;
}

- (void)powerOn
{
    NSLog(@"SEBLEInterfaceManager turned on");
}

- (void)startScan
{
    if (self.isPowerOn && !self.isCurrentlyScanning) {
        if (self.servicesToRead) {
            NSMutableArray *serviceCBUUIDs = [NSMutableArray new];
            for (NSString *service in self.servicesToRead.allObjects) {
                [serviceCBUUIDs addObject:[CBUUID UUIDWithString:service]];
            }
            
            [self.centralManager scanForPeripheralsWithServices:serviceCBUUIDs options:nil];
        } else {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
}

- (void)stopScan
{
    [self.centralManager stopScan];
}

- (BOOL)isCurrentlyScanning
{
    return self.centralManager.isScanning;
}

- (BOOL)isPowerOn
{
    return self.centralManager.state == CBCentralManagerStatePoweredOn;
}

- (void)setServiceToReadFrom:(NSSet *)serviceNames
{
    self.servicesToRead = serviceNames;
}

- (void)setCharacteristicsToReadFrom:(NSSet *)characteristicsToRead
{
    self.charToRead = characteristicsToRead;
}

- (void)setCharacteristicsToReceiveNotificationsFrom:(NSSet *)notificationsToRecieve
{
    self.charToNotifiy = notificationsToRecieve;
}

- (void)setServicesToNotifyWhenTheyAreDiscoverd:(NSSet *)servicesToNotify
{
    self.servicesToNotifyWhenDiscoverd = servicesToNotify;
}

- (void)connectToPeripheralWithKey:(NSString *)key
{
    NSLog(@"Attempting to connect to peripheral with key: %@", key);
    NSLog(@"Not connected peripherals: %@", self.notConnectedPeripherals.description);
    
    if (self.notConnectedPeripherals[key]) {
        NSLog(@"Adding peripheral with key: %@", key);
        SEBLEPeripheral *blePeripheral = self.notConnectedPeripherals[key];
        if (!blePeripheral.peripheral.delegate) {
            blePeripheral.peripheral.delegate = self;
        }
        
        [self.centralManager connectPeripheral:blePeripheral.peripheral options:nil];
    } else {
        NSLog(@"WARNING - Trying to add %@, but it is not in notConnectedPeripherals", key);
    }
}

- (BOOL)hasNonConnectedPeripheralWithKey:(NSString *)key
{
    return self.notConnectedPeripherals[key] != nil;
}

- (BOOL)hasConnectedPeripheralWithKey:(NSString *)key
{
    return self.connectedPeripherals[key] != nil;
}

- (BOOL)shouldConnectToDeviceNamed:(NSString *)name
{
    for (NSString *fragment in self.fragmentsToConnect) {
        if ([name.lowercaseString rangeOfString:fragment.lowercaseString].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)shouldDiscoverDeviceWithAdvertisementData:(NSDictionary *)advertisementData
{
    return advertisementData &&
    advertisementData[kSEBLEInterfaceDataLocalName] &&
    advertisementData[kSEBLEInterfaceDataServiceUUIDs] &&
    [self shouldConnectToDeviceNamed:advertisementData[kSEBLEInterfaceDataLocalName]];
}

- (void)removeConnectedPeripheralForKey:(NSString *)key
{
    if (self.connectedPeripherals[key]) {
        [self.connectedPeripherals removeObjectForKey:key];
    }
}

- (void)removePeripheralForKey:(NSString *)key
{
    [self removeConnectedPeripheralForKey:key];
    [self removeNotConnectPeripheralForKey:key];
}

- (void)removeNotConnectPeripherals
{
    [self.notConnectedPeripherals removeAllObjects];
}

- (void)setDeviceNamesToConnectTo:(NSSet *)namesToConnect
{
    self.namesToConnectAutomatically = namesToConnect;
}

- (void)setDeviceNameFragmentsToConnect:(NSArray *)fragmentsToConnect
{
    self.fragmentsToConnect = fragmentsToConnect;
}

- (SEBLEPeripheral *)seblePeripheralForCBPeripheral:(CBPeripheral *)peripheral
{
    SEBLEPeripheral *blePeripheral;
    if (self.connectedPeripherals[peripheral.name]) {
        blePeripheral = self.connectedPeripherals[peripheral.name];
    } else if (self.notConnectedPeripherals[peripheral.name]) {
        blePeripheral = self.notConnectedPeripherals[peripheral.name];
    }

    return blePeripheral;
}

- (void)writeToPeripheralWithKey:(NSString *)key
                     serviceUUID:(NSString *)serviceUUID
              characteristicUUID:(NSString *)characteristicUUID
                            data:(NSData *)data
{
    SEBLEPeripheral *blePeripheral = self.connectedPeripherals[key];
    NSDictionary *characteristics = blePeripheral.services[serviceUUID][kSEBLEPeripheralCharacteristics];
    CBCharacteristic *characteristic = characteristics[characteristicUUID];
    
    [blePeripheral.peripheral writeValue:data
                       forCharacteristic:characteristic
                                    type:CBCharacteristicWriteWithResponse];
}

- (void)readValueForPeripheralWithKey:(NSString *)key
                       forServiceUUID:(NSString *)serviceUUID
                andCharacteristicUUID:(NSString *)characteristicUUID
{
    SEBLEPeripheral *blePeripheral = self.connectedPeripherals[key];
    NSDictionary *characteristics = blePeripheral.services[serviceUUID][kSEBLEPeripheralCharacteristics];
    CBCharacteristic *characteristic = characteristics[characteristicUUID];
    
    [blePeripheral.peripheral readValueForCharacteristic:characteristic];
}

- (void)updateConnectPeripheralKey:(NSString *)oldKey newKey:(NSString *)newKey
{
    SEBLEPeripheral *peripheral = self.connectedPeripherals[oldKey];
    if (peripheral) {
        [self.connectedPeripherals removeObjectForKey:oldKey];
        self.connectedPeripherals[newKey] = peripheral;
    }
}

- (void)setNotConnectedPeripheral:(SEBLEPeripheral *)seblePeripheral forKey:(NSString *)key
{
    self.notConnectedPeripherals[key] = seblePeripheral;
}

- (void)removeNotConnectPeripheralForKey:(NSString *)key
{
    if (self.notConnectedPeripherals[key]) {
        [self.notConnectedPeripherals removeObjectForKey:key];
    }
    
    NSLog(@"%@", self.connectedPeripherals.description);
}

- (SEBLEPeripheral *)notConnectedPeripheralForKey:(NSString *)key
{
    return self.notConnectedPeripherals[key];
}

- (SEBLEPeripheral *)connectedPeripheralForKey:(NSString *)key
{
    return self.connectedPeripherals[key];
}

- (void)setConnectedPeripheral:(SEBLEPeripheral *)blePeripheral forKey:(NSString *)key
{
    blePeripheral.peripheral.delegate = self;
    self.connectedPeripherals[key] = blePeripheral;
}

- (void)disconnectFromPeripheralWithKey:(NSString *)key
{
    if (!self.connectedPeripherals[key]) {
        return;
    }
    
    SEBLEPeripheral *peripheral = self.connectedPeripherals[key];
    [self.centralManager cancelPeripheralConnection:peripheral.peripheral];
}

- (void)connectToPeripheralFromBackgroundWithUUID:(NSString *)uuid
{
    if (!self.restoredPeripherals || self.restoredPeripherals.count == 0) {
        return;
    }
    
    CBPeripheral *peripheral = nil;
    for (CBPeripheral *cbPeripheral in self.restoredPeripherals) {
        if ([cbPeripheral.identifier.UUIDString isEqualToString:uuid]) {
            peripheral = cbPeripheral;
            break;
        }
    }
    
    if (peripheral) {
        SEBLEPeripheral *seblePeripheral = [[SEBLEPeripheral alloc] initWithPeripheral:peripheral
                                                                                  uuid:[CBUUID UUIDWithString:uuid]
                                                                                  name:peripheral.name];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}
- (void)setCharacteristicUUIDToNotify:(NSString *)uuid forPeripheralWithKey:(NSString *)key
{
    if (!self.connectedPeripherals[uuid]) {
        NSLog(@"Could not set %@ to notify for peripheral %@ since it is not connected", uuid, key);
        return;
    }
    
    SEBLEPeripheral *blePeripheral = self.connectedPeripherals[uuid];
    CBCharacteristic *characteristic = [blePeripheral characteristicForUUID:uuid];
    if (characteristic) {
        [blePeripheral.peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

- (void)discoverServices:(NSArray *)services forPeripheralWithKey:(NSString *)key
{
    if (self.connectedPeripherals[key]) {
        SEBLEPeripheral *peripheral = self.connectedPeripherals[key];
        [peripheral.peripheral discoverServices:services];
    }
}

- (void)discoverCharacteristicsForService:(CBService *)service forPeripheralKey:(NSString *)key
{
    if (self.connectedPeripherals[key]) {
        SEBLEPeripheral *blePeripheral = self.connectedPeripherals[key];
        for (CBCharacteristic *characteristic in service.characteristics) {
            NSString *charUUID = [NSString stringWithFormat:@"%@", characteristic.UUID];
            if ([self.charToRead containsObject:charUUID]) {
                NSLog(@"Discoverd characteristic with UUID: %@", charUUID);
                [blePeripheral addCharacteristic:characteristic forService:service];
                NSString *uuid = [NSString stringWithFormat:@"%@", characteristic.UUID];
                if ([self.charToNotifiy containsObject:uuid]) {
                    [blePeripheral.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)discoverServicesForPeripheralKey:(NSString *)key
{
    if (self.connectedPeripherals[key]) {
        SEBLEPeripheral *blePeripheral = self.connectedPeripherals[key];
        for (CBService *service in blePeripheral.peripheral.services) {
            NSString *serviceUUID = [NSString stringWithFormat:@"%@", service.UUID];
            if ([self.servicesToRead containsObject:serviceUUID]) {
                NSLog(@"Subscribing to service: %@ for peripheral: %@", service.UUID, blePeripheral.name);
                [blePeripheral addService:service];
                [blePeripheral.peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
}

#pragma mark - CBPeripheral Delegate Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            if ([self.delegate respondsToSelector:@selector(bleInterfaceManagerIsPoweredOff:)]) {
                [self.delegate bleInterfaceManagerIsPoweredOff:self];
            }
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            if ([self.delegate respondsToSelector:@selector(bleInterfaceManagerIsPoweredOn:)]) {
                [self.delegate bleInterfaceManagerIsPoweredOn:self];
            }
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"found periphial named: %@ with advertistment data: %@",
          peripheral.name,
          advertisementData.description);
    
    if ([self shouldDiscoverDeviceWithAdvertisementData:advertisementData]) {
        NSArray *UUIDs = advertisementData[kSEBLEInterfaceDataServiceUUIDs];
        NSString *name = advertisementData[kSEBLEInterfaceDataLocalName];
        SEBLEPeripheral *blePeripheral = [SEBLEPeripheral withPeripheral:peripheral uuid:UUIDs[0] name:name];
        if ([self.delegate respondsToSelector:
             @selector(bleInterfaceManager:discoveredPeripheral:withAdvertisemntData:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate bleInterfaceManager:self
                              discoveredPeripheral:blePeripheral
                              withAdvertisemntData:advertisementData];
            });
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"connected peripheral named :%@", peripheral.name);
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:connectedPeripheralNamed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
           [self.delegate bleInterfaceManager:self connectedPeripheralNamed:peripheral.name];
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"error discovering services for peripheral named: %@. Failed with error: %@",
              peripheral,
              error.localizedDescription);
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:discoveredServicesForPeripheralNamed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bleInterfaceManager:self discoveredServicesForPeripheralNamed:peripheral.name];
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"error discovering characteristic for service: %@", error.localizedDescription);
        // TODO add a resposne to calling object...maybe a completion block
        return;
    }
    
    NSLog(@"BLEManager discoved characteristics for service: %@", service.UUID.UUIDString);
    if ([self.delegate respondsToSelector:
         @selector(bleInterfaceManager:discoveredCharacteristicsForService:forPeripheralNamed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bleInterfaceManager:self
           discoveredCharacteristicsForService:service
                            forPeripheralNamed:peripheral.name];
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"error reading from Peripheral %@ with characteristic %@ %@",
              peripheral.name,
              characteristic.UUID,
              error);
        return;
    }
    
    NSString *uuid = [NSString stringWithFormat:@"%@", characteristic.UUID];
    if ([self.charToRead containsObject:uuid]) {
        NSLog(@"Valued updated for peripheral: %@ for characteristic uuid :%@ with number of bytes: %@",
              peripheral.name,
              uuid,
              @(characteristic.value.length));
        
        if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:updatedPeripheralNamed:forCharacteristicUUID:withData:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate bleInterfaceManager:self
                            updatedPeripheralNamed:peripheral.name
                             forCharacteristicUUID:uuid
                                          withData:characteristic.value];
            });
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    BOOL success = YES;
    if (error) {
        NSLog(@"error reading from Peripheral %@ with characteristic %@ %@",
              peripheral.name,
              characteristic.UUID,
              error);
        success = NO;
    }
    
    if (success) {
        NSLog(@"updated value for Peripheral %@ with characteristic %@",
              peripheral.name,
              characteristic.UUID);
    }
    
    if ([self.delegate respondsToSelector:
         @selector(bleInterfaceManager:wroteValueToPeripheralNamed:forUUID:withWriteSuccess:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bleInterfaceManager:self
                   wroteValueToPeripheralNamed:peripheral.name
                                       forUUID:[NSString stringWithFormat:@"%@", characteristic.UUID]
                              withWriteSuccess:success];
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error && error.code != 15) {
        NSLog(@"Error: failed to update notification state for: %@ for characteristic: %@ with error: %@",
              peripheral.name,
              [NSString stringWithFormat:@"%@", characteristic.UUID],
              error);
    } else {
        NSLog(@"Updating notification state for: %@ for characteristic: %@",
              peripheral.name,
              [NSString stringWithFormat:@"%@", characteristic.UUID]);
        if ([self.delegate respondsToSelector:
             @selector(bleInterfaceManager:peripheralName:changedUpdateStateForCharacteristic:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *uuid = [NSString stringWithFormat:@"%@", characteristic.UUID];
                [self.delegate bleInterfaceManager:self
                                    peripheralName:peripheral.name
               changedUpdateStateForCharacteristic:uuid];
            });
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: disconnecting from periphreal: %@, with error: %@",
              peripheral.name,
              error);
    }
    
    
    if (self.isInBackground) {
        [central retrievePeripheralsWithIdentifiers:@[peripheral.identifier]];
    }
    
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:disconnectedPeripheralNamed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bleInterfaceManager:self disconnectedPeripheralNamed:peripheral.name];
        });
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
    if (!dict[CBCentralManagerRestoredStatePeripheralsKey]) {
        return;
    }
    
    self.restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    NSMutableArray *blePeripherals = [NSMutableArray new];
    for (CBPeripheral *peripheral in self.restoredPeripherals) {
        CBUUID *uuid = [CBUUID UUIDWithString:peripheral.identifier.UUIDString];
        SEBLEPeripheral *blePeripheral = [SEBLEPeripheral withPeripheral:peripheral
                                                                    uuid:uuid
                                                                    name:peripheral.name];
        [blePeripherals addObject:blePeripheral];
    }
    
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:restoredPeripherals:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bleInterfaceManager:self restoredPeripherals:blePeripherals];
        });
    }
}

@end
