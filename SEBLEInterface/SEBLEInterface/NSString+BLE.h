//
//  NSString+BLE.h
//  SEBLEInterface
//
//  Created by Andre Green on 7/6/15.
//  Copyright (c) 2015 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

@interface NSString (BLE)

- (CBUUID *)CBUUID;

+ (instancetype)stringWithCBUUID:(CBUUID *)cbUUID;

@end
