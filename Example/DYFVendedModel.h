//
//  DYFVendedModel.h
//
//  Created by dyf on 2017/11/20.
//  Copyright © 2017年 dyf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYFVendedModel : NSObject <NSCoding>
// 类型
@property (nonatomic, assign) NSInteger type;
// 专辑id
@property (nonatomic, copy) NSString *albumId;
// 主播id
@property (nonatomic, copy) NSString *anchorId;
// 价格
@property (nonatomic, copy) NSString *price;
// 凭证
@property (nonatomic, copy) NSString *receipt;
// 状态
@property (nonatomic, assign) BOOL status;

// 创建模型
+ (instancetype)modelWithType:(NSInteger)type;

@end
