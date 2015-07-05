//
//  SEBLEPeripheral.m
//  SEBLEInterface
//
//  Created by Andre Green on 7/3/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "SEBLEPeripheral.h"

@implementation SEBLEPeripheral

- (id)initWithPeripheral:(CBPeripheral *)peripheral UUID:(CBUUID *)UUID
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _services = [NSMutableDictionary new];
        _UUID = UUID;
    }
    
    return  self;
}

+ (id)withPeripheral:(CBPeripheral *)peripheral UUID:(CBUUID *)UUID
{
    return [[self alloc] initWithPeripheral:peripheral UUID:UUID];
}

- (void)addService:(CBService *)service
{
    NSString *serviceUUID = [self CBUUIDAsString:service.UUID];
    if (!self.services[serviceUUID]) {
        self.services[serviceUUID] = @{kSEBLEPeripheralService:service,
                                       kSEBLEPeripheralCharacteristics:[NSMutableDictionary new]
                                       };
    }
}

- (void)addCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service
{
    NSString *characteristicUUID = [self CBUUIDAsString:characteristic.UUID];
    NSString *serviceUUID = [self CBUUIDAsString:service.UUID];
    self.services[serviceUUID][kSEBLEPeripheralCharacteristics][characteristicUUID] = characteristic;
}

- (NSString *)CBUUIDAsString
{
    return [self CBUUIDAsString:self.UUID];
}

- (NSString *)CBUUIDAsString:(CBUUID *)UUID
{
    return [NSString stringWithFormat:@"%@", UUID];
}

- (CBUUID *)CBUUIDFromString:(NSString *)CBUUIDString
{
    return [CBUUID UUIDWithString:CBUUIDString];
}

@end

