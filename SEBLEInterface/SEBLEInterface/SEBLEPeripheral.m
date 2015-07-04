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
    if (!self.services[service.UUID]) {
        self.services[service.UUID] = @{kSEBLEPeripheralService:service,
                                        kSEBLEPeripheralCharacteristics:[NSMutableDictionary new]
                                        };
    }
}
@end

