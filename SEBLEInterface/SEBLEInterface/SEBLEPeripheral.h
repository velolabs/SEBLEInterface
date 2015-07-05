//
//  SEBLEPeripheral.h
//  SEBLEInterface
//
//  Created by Andre Green on 7/3/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;


#define kSEBLEPeripheralService @"SEBLEPeripheralService"
#define kSEBLEPeripheralCharacteristics @"SEBLEPeripheralCharacteristics"


@interface SEBLEPeripheral : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSMutableDictionary *services;
@property (nonatomic, strong) CBUUID *UUID;
- (id)initWithPeripheral:(CBPeripheral *)peripheral UUID:(CBUUID *)UUID;

+ (id)withPeripheral:(CBPeripheral *)peripheral UUID:(CBUUID *)UUID;
- (void)addService:(CBService *)service;
- (NSString *)CBUUIDAsString;
- (void)addCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service;

@end
