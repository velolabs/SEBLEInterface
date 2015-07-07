//
//  NSString+BLE.m
//  SEBLEInterface
//
//  Created by Andre Green on 7/6/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import "NSString+BLE.h"

@implementation NSString (BLE)

- (CBUUID *)CBUUID
{
    return [CBUUID UUIDWithString:self];
}

+ (id)stringWithCBUUID:(CBUUID *)cbUUID
{
    return [NSString stringWithFormat:@"%@", cbUUID];
}

@end
