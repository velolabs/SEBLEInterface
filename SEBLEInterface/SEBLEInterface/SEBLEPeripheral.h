//
//  SEBLEPeripheral.h
//  SEBLEInterface
//
//  Created by Andre Green on 7/3/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

@interface SEBLEPeripheral : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSArray *UUIDs;

- (id)initWithPeripheral:(CBPeripheral *)peripheral UUIDs:(NSArray *)UUIDs;

+ (id)withPeripheral:(CBPeripheral *)peripheral andUUIDs:(NSArray *)UUIDs;
- (NSString *)UUID;

@end
