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


@interface SEBLEInterfaceMangager()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableDictionary *notConnectedPeripherals;
@property (nonatomic, strong) NSMutableDictionary *connectedPeripherals;
@property (nonatomic, strong) NSArray *connectToNames;
@property (nonatomic, strong) NSSet *charToRead;
@property (nonatomic, strong) NSSet *servicesToRead;
@property (nonatomic, strong) NSSet *charToNotifiy;
@property (nonatomic, assign) BOOL isPoweredOn;

@end

@implementation SEBLEInterfaceMangager

- (id)init
{
    self = [super init];
    if (self) {
        _centralManager             = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _notConnectedPeripherals    = [NSMutableDictionary new];
        _connectedPeripherals       = [NSMutableDictionary new];
        _isPoweredOn                = NO;
    }
    
    return self;
}

+ (id)manager
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
    if (self.isPoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)stopScan
{
    [self.centralManager stopScan];
}

- (void)setDeviceNamesToConnectTo:(NSArray *)namesToConnect
{
    self.connectToNames = namesToConnect;
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

- (void)addPeripheralNamed:(NSString *)name
{
    if (self.notConnectedPeripherals[name]) {
        NSLog(@"Adding peripheral named: %@", name);
        SEBLEPeripheral *blePeripheral = self.notConnectedPeripherals[name];
        [self.centralManager connectPeripheral:blePeripheral.peripheral options:nil];
    }
}

- (BOOL)shouldConnectToDeviceNamed:(NSString *)name
{
    BOOL shouldConnect = NO;
    for (NSString *approvedName in self.connectToNames) {
        if ([name.lowercaseString rangeOfString:approvedName.lowercaseString].location != NSNotFound) {
            shouldConnect = YES;
            break;
        }
    }
    
    return shouldConnect;
}

- (BOOL)shouldConnectToDeviceWithAdvertisementData:(NSDictionary *)advertisementData
{
    return advertisementData &&
    advertisementData[kSEBLEInterfaceDataLocalName] &&
    advertisementData[kSEBLEInterfaceDataServiceUUIDs] &&
    [self shouldConnectToDeviceNamed:advertisementData[kSEBLEInterfaceDataLocalName]];
}

- (void)removePeripheralNamed:(NSString *)name
{
    
}

- (void)removeNotConnectPeripherals
{
    [self.notConnectedPeripherals removeAllObjects];
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

- (void)writeToPeripheralWithName:(NSString *)peripheralName
                      serviceUUID:(NSString *)serviceUUID
               characteristicUUID:(NSString *)characteristicUUID
                            data:(NSData *)data
{
    SEBLEPeripheral *blePeripheral = self.connectedPeripherals[peripheralName];
    NSDictionary *characteristics = blePeripheral.services[serviceUUID][kSEBLEPeripheralCharacteristics];
    CBCharacteristic *characteristic = characteristics[characteristicUUID];
    u_int16_t a;
    [data getBytes:&a length:sizeof(a)];
    
    [blePeripheral.peripheral writeValue:data
                       forCharacteristic:characteristic
                                    type:CBCharacteristicWriteWithResponse];
}

- (void)readValueForPeripheralNamed:(NSString *)peripheralName
                     forServiceUUID:(NSString *)serviceUUID
              andCharacteristicUUID:(NSString *)characteristicUUID
{
    SEBLEPeripheral *blePeripheral = self.connectedPeripherals[peripheralName];
    NSDictionary *characteristics = blePeripheral.services[serviceUUID][kSEBLEPeripheralCharacteristics];
    CBCharacteristic *characteristic = characteristics[characteristicUUID];

    [blePeripheral.peripheral readValueForCharacteristic:characteristic];
}

#pragma mark - CBPeripheral Delegate Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            self.isPoweredOn = YES;
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
    NSLog(@"found periphial named: %@ with advertistment data: %@", peripheral.name, advertisementData.description);
    
    if ([self shouldConnectToDeviceWithAdvertisementData:advertisementData]) {
        NSArray *UUIDs = advertisementData[kSEBLEInterfaceDataServiceUUIDs];
        SEBLEPeripheral *blePeripheral = [SEBLEPeripheral withPeripheral:peripheral uuid:UUIDs[0]];
        if (!self.notConnectedPeripherals[peripheral.name]) {
            self.notConnectedPeripherals[peripheral.name] = blePeripheral;
            
            if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:discoveredPeripheral:)]) {
                [self.delegate bleInterfaceManager:self discoveredPeripheral:blePeripheral];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"connected peripheral named :%@", peripheral.name);
    
    if (self.notConnectedPeripherals[peripheral.name]) {
        SEBLEPeripheral *blePeripheral = self.notConnectedPeripherals[peripheral.name];
        [self.notConnectedPeripherals removeObjectForKey:peripheral.name];
        self.connectedPeripherals[peripheral.name] = blePeripheral;
        peripheral.delegate = self;
        [peripheral discoverServices:nil];
        
        if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:connectedPeripheral:)]) {
            [self.delegate bleInterfaceManager:self connectedPeripheral:blePeripheral];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSString *serviceUUID = [NSString stringWithFormat:@"%@", service.UUID];
        if ([self.servicesToRead containsObject:serviceUUID]) {
            NSLog(@"Subscribing to service: %@ for peripheral: %@", service.UUID, peripheral.name);
            SEBLEPeripheral *blePeripheral = [self seblePeripheralForCBPeripheral:peripheral];
            if (blePeripheral) {
                [blePeripheral addService:service];
            }
            
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"error discovering characteristic for service: %@", error.localizedDescription);
    } else {
        for (CBCharacteristic *characteristic in service.characteristics) {
            NSString *charUUID = [NSString stringWithFormat:@"%@", characteristic.UUID];
            if ([self.charToRead containsObject:charUUID]) {
                NSLog(@"Discoverd characteristic with UUID: %@", charUUID);
                SEBLEPeripheral *blePeripheral = [self seblePeripheralForCBPeripheral:peripheral];
                [blePeripheral addCharacteristic:characteristic forService:service];
                NSString *uuid = [NSString stringWithFormat:@"%@", characteristic.UUID];
                if ([self.charToNotifiy containsObject:uuid]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
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
        
        if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:updatedPeripheral:forCharacteristicUUID:withData:)]) {
            SEBLEPeripheral *blePeripheral = [self seblePeripheralForCBPeripheral:peripheral];
            [self.delegate bleInterfaceManager:self
                             updatedPeripheral:blePeripheral
                         forCharacteristicUUID:uuid
                                      withData:characteristic.value];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"error reading from Peripheral %@ with characteristic %@ %@",
              peripheral.name,
              characteristic.UUID,
              error);
        return;
    }
    
    NSLog(@"updated value for Peripheral %@ with characteristic %@",
          peripheral.name,
          characteristic.UUID);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: failed to update notification state for: %@ for characteristic: %@",
              peripheral.name,
              [NSString stringWithFormat:@"%@", characteristic.UUID]);
        return;
    }
   
    NSLog(@"Updating notification state for: %@ for characteristic: %@",
          peripheral.name,
          [NSString stringWithFormat:@"%@", characteristic.UUID]);
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
    
    SEBLEPeripheral *blePeripheral = [self seblePeripheralForCBPeripheral:peripheral];
    
    if (self.connectedPeripherals[peripheral.name]) {
        [self.connectedPeripherals removeObjectForKey:peripheral.name];
    }
    
    if (self.notConnectedPeripherals[peripheral.name]) {
        [self.notConnectedPeripherals removeObjectForKey:peripheral.name];
    }
    
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:disconnectedPeripheral:)]) {
        [self.delegate bleInterfaceManager:self disconnectedPeripheral:blePeripheral];
    }
}


@end
