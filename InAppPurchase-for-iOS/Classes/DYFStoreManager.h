//
//  DYFStoreManager.h
//
//  Created by dyf on 2017/10/19.
//  Copyright © 2017年 dyf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DYFVendedModel.h"

// 购买完成函数
typedef void (^DYFStorePurchaseDidCompleteBlock)(BOOL status, NSString *msg);

@interface DYFStoreManager : NSObject

// 售卖模型
@property (nonatomic, strong) DYFVendedModel *esm_model;

// 获取商店管理员单例
+ (instancetype)esm_sharedMgr;

// 请求商品
- (void)esm_requestProductForIds:(NSArray *)productIds;

// 购买
- (void)esm_purchaseProductForId:(NSString *)productId;

// 恢复购买
- (void)esm_restorePurchases;

// 购买完成处理
- (void)esm_addPurchasedCompletionHandler:(DYFStorePurchaseDidCompleteBlock)block;

@end
