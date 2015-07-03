//
//  SEBLEInterfaceManager.m
//  SEBLEInterface
//
//  Created by Andre Green on 6/14/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "SEBLEInterfaceManager.h"
#import "SENotifications.h"

#define kPeriphialName  @"SigEazeBLE"
#define kPeriphialDataLocalNameKey @"kCBAdvDataLocalName"
#define kPeriphialDataLocalName @"SigEazeBLE"
#define kPeriphialUIDD  @"713D0000-503E-4C75-BA94-3148F18D941E"
#define kServiceUIDD    @"713D0002-503E-4C75-BA94-3148F18D941E"
#define kSEBLEInterfaceSubscribedServices   @"kSEBLEInterfaceSubscribedServices"

typedef NS_ENUM(UInt8, SEDataId) {
    SEDataIdNone = 0,
    SEDataIdTach
};


@interface SEBLEInterfaceMangager()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *arduinoPeriphial;
@property (nonatomic, strong) NSMutableDictionary *devices;

@end

@implementation SEBLEInterfaceMangager

- (id)init
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _devices = [NSMutableDictionary new];
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

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    if (peripheral == self.arduinoPeriphial) {
//        NSLog(@"Connected Periphial: %@", self.arduinoPeriphial.name);
//        self.arduinoPeriphial.delegate = self;
//        [self.arduinoPeriphial discoverServices:nil];
//    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central
    didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"found periphial named: %@ with advertistment data: %@", peripheral.name, advertisementData.description);
//    if (advertisementData && [advertisementData[kPeriphialDataLocalNameKey] isEqualToString:kPeriphialDataLocalName] && !self.arduinoPeriphial) {
//        self.arduinoPeriphial = peripheral;
//        self.arduinoPeriphial.delegate = self;
//        [self.centralManager connectPeripheral:self.arduinoPeriphial options:nil];
//        [self.centralManager stopScan];
//    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the periphera
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
             NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
    didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    if (peripheral == self.arduinoPeriphial) {
        self.arduinoPeriphial = nil;
    }
    
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
    didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"error discovering characteristic for service: %@", error.localizedDescription);
        return;
    } else {
        NSLog(@"service characteristics: %@", service.characteristics);
        
        if (peripheral == self.arduinoPeriphial) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kServiceUIDD]]) {
                    [self.arduinoPeriphial setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSData *data = characteristic.value;
    const uint8_t *recievedData = data.bytes;
    uint16_t value = 0;
    NSMutableArray *numbers = [NSMutableArray new];
    
    for (int i=0; i < data.length; i++) {
        //[numbers addObject:@(recievedData[i])];
        uint8_t digit = recievedData[i];
        value += [self value:digit forIndex:i];
        if (i == data.length - 1 || i % 2 == 1) {
            [numbers addObject:@(value)];
            value = 0;
        }
    }
    
    [self valuesUpdated:numbers];
    NSLog(@"there are %ld sensor values. they are: %@", (long)numbers.count, numbers);
}

- (uint16_t)value:(uint8_t)value forIndex:(int)index
{
    uint16_t returnValue = 0;
    switch (index % 2) {
        case 0:
            returnValue = 256*value;
            break;
        case 1:
            returnValue = value;
            break;
        default:
            break;
    }
    
    return returnValue;
}

- (CBUUID *)CBUUIDFromString:(NSString *)CBUUIDString
{
    return [CBUUID UUIDWithString:CBUUIDString];
}

- (NSString *)stringFromCBUUID:(CBUUID *)cbUUID
{
    NSString *CBUUIDString = [NSString stringWithFormat:@"%@", cbUUID];
    return CBUUIDString;
}

- (void)valuesUpdated:(NSArray *)values
{
    if ([self.delegate respondsToSelector:@selector(bleInterfaceManager:didUpdateDeviceValues:)]) {
        // TODO -- Don't leave device values as nil.
        [self.delegate bleInterfaceManager:self didUpdateDeviceValues:nil];
    }
}

@end
