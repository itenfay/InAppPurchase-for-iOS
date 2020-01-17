//
//  DYFStoreManager.h
//
//  Created by dyf on 2015/11/04.
//  Copyright © 2015 dyf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DYFVendedModel.h"

// 购买完成函数
typedef void (^DYFStorePurchaseDidCompleteBlock)(BOOL status, NSString *msg);

@interface DYFStoreManager : NSObject

// 售卖模型
@property (nonatomic, strong) DYFVendedModel *model;

// 商店管理员单例
+ (instancetype)sharedMgr;

// 请求商品
- (void)requestProductForIds:(NSArray *)productIds;

// 购买
- (void)purchaseProductForId:(NSString *)productId completion:(DYFStorePurchaseDidCompleteBlock)block;

// 恢复购买
- (void)restorePurchasesWithCompletion:(DYFStorePurchaseDidCompleteBlock)block;

@end
