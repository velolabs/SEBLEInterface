//
//  SEBLEPeripheral.m
//  SEBLEInterface
//
//  Created by Andre Green on 7/3/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "SEBLEPeripheral.h"

@implementation SEBLEPeripheral

- (id)initWithPeripheral:(CBPeripheral *)peripheral UUIDs:(NSArray *)UUIDs
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _UUIDs       = UUIDs;
    }
    
    return  self;
}

+ (id)withPeripheral:(CBPeripheral *)peripheral andUUIDs:(NSArray *)UUIDs
{
    return [[self alloc] initWithPeripheral:peripheral UUIDs:UUIDs];
}

- (NSString *)UUID
{
    return self.UUIDs.firstObject;
}
@end

