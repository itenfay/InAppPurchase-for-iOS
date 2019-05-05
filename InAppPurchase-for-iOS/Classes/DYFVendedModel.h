//
//  DYFVendedModel.h
//
//  Created by dyf on 2017/11/20.
//  Copyright © 2017年 dyf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYFVendedModel : NSObject <NSCoding>
// 类型
@property (nonatomic, assign) NSInteger evm_type;
// 专辑id
@property (nonatomic, copy) NSString *evm_albumId;
// 主播id
@property (nonatomic, copy) NSString *evm_anchorId;
// 价格
@property (nonatomic, copy) NSString *evm_price;
// 凭证
@property (nonatomic, copy) NSString *evm_receipt;
// 状态
@property (nonatomic, assign) BOOL evm_status;

// 创建模型
+ (instancetype)evm_modelWithType:(NSInteger)type;

@end
