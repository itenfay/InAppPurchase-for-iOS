//
//  DYFVendedModel.m
//
//  Created by dyf on 2017/11/20.
//  Copyright © 2017年 dyf. All rights reserved.
//

#import "DYFVendedModel.h"

@implementation DYFVendedModel

+ (instancetype)evm_modelWithType:(NSInteger)type {
    DYFVendedModel *model = [[self alloc] init];
    model.evm_type = type;
    return model;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.evm_type = [aDecoder decodeIntegerForKey:@"evm_type"];
        self.evm_albumId = [aDecoder decodeObjectForKey:@"evm_albumId"];
        self.evm_anchorId = [aDecoder decodeObjectForKey:@"evm_anchorId"];
        self.evm_price = [aDecoder decodeObjectForKey:@"evm_price"];
        self.evm_receipt = [aDecoder decodeObjectForKey:@"evm_receipt"];
        self.evm_status = [aDecoder decodeBoolForKey:@"evm_status"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.evm_type forKey:@"evm_type"];
    [aCoder encodeObject:self.evm_albumId forKey:@"evm_albumId"];
    [aCoder encodeObject:self.evm_anchorId forKey:@"evm_anchorId"];
    [aCoder encodeObject:self.evm_price forKey:@"evm_price"];
    [aCoder encodeObject:self.evm_receipt forKey:@"evm_receipt"];
    [aCoder encodeBool:self.evm_status forKey:@"evm_status"];
}

@end
