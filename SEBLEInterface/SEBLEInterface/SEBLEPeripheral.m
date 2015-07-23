//
//  SEBLEPeripheral.m
//  SEBLEInterface
//
//  Created by Andre Green on 7/3/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "SEBLEPeripheral.h"
#import "NSString+BLE.h"

@implementation SEBLEPeripheral

- (id)initWithPeripheral:(CBPeripheral *)peripheral uuid:(CBUUID *)uuid
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _services = [NSMutableDictionary new];
        _uuid = uuid;
    }
    
    return  self;
}

+ (id)withPeripheral:(CBPeripheral *)peripheral uuid:(CBUUID *)uuid
{
    return [[self alloc] initWithPeripheral:peripheral uuid:uuid];
}

- (void)addService:(CBService *)service
{
    //NSString *serviceUUID = [NSString stringWithCBUUID:service.UUID];
    NSString *serviceUUID = [NSString stringWithFormat:@"%@", service.UUID];
    if (!self.services[serviceUUID]) {
        self.services[serviceUUID] = @{kSEBLEPeripheralService:service,
                                       kSEBLEPeripheralCharacteristics:[NSMutableDictionary new]
                                       };
    }
}

- (void)addCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service
{
    //NSString *characteristicUUID = [NSString stringWithCBUUID:characteristic.UUID];
    NSString *characteristicUUID = [NSString stringWithFormat:@"%@", characteristic.UUID];
    //NSString *serviceUUID = [NSString stringWithCBUUID:service.UUID];
    NSString *serviceUUID = [NSString stringWithFormat:@"%@", service.UUID];
    self.services[serviceUUID][kSEBLEPeripheralCharacteristics][characteristicUUID] = characteristic;
}

- (NSString *)CBUUIDAsString
{
    //return [NSString stringWithCBUUID:self.uuid];
    return [NSString stringWithFormat:@"%@", self.uuid];
}

@end

