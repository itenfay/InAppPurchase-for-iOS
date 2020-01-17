//
//  DYFVendedModel.m
//
//  Created by dyf on 2015/11/04.
//  Copyright © 2015 dyf. All rights reserved.
//

#import "DYFVendedModel.h"

@implementation DYFVendedModel

+ (instancetype)modelWithType:(NSInteger)type {
    DYFVendedModel *model = [[self alloc] init];
    model.type = type;
    return model;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.type = [aDecoder decodeIntegerForKey:@"type"];
        self.albumId = [aDecoder decodeObjectForKey:@"albumId"];
        self.anchorId = [aDecoder decodeObjectForKey:@"anchorId"];
        self.price = [aDecoder decodeObjectForKey:@"price"];
        self.receipt = [aDecoder decodeObjectForKey:@"receipt"];
        self.status = [aDecoder decodeBoolForKey:@"status"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.type forKey:@"type"];
    [aCoder encodeObject:self.albumId forKey:@"albumId"];
    [aCoder encodeObject:self.anchorId forKey:@"anchorId"];
    [aCoder encodeObject:self.price forKey:@"price"];
    [aCoder encodeObject:self.receipt forKey:@"receipt"];
    [aCoder encodeBool:self.status forKey:@"status"];
}

@end
