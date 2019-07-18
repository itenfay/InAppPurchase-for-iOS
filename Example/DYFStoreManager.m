//
//  DYFStoreManager.m
//
//  Created by dyf on 2017/10/19.
//  Copyright © 2017年 dyf. All rights reserved.
//

#import "DYFStoreManager.h"
#import "DYFIAPHelper.h"

#define Alert_Tag             10

#define kIapDataStorage       @"kIAPData"

@interface DYFStoreManager () <DYFIAPHelperDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) DYFIAPHelper *iapHelper;
@property (nonatomic, strong) NSLock *m_lock;
@property (nonatomic,  copy ) NSString *m_productId;
@property (nonatomic,  copy ) NSString *m_storeTransId;
@property (nonatomic,  copy ) DYFStorePurchaseDidCompleteBlock didCompleteBlock;
@end

@implementation DYFStoreManager

+ (instancetype)sharedMgr {
    static DYFStoreManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.iapHelper = [DYFIAPHelper helper];
        self.iapHelper.delegate = self;
        self.m_lock = [[NSLock alloc] init];
        [self addStoreObserver];
    }
    return self;
}

- (void)requestProductForIds:(NSArray *)productIds {
    if ([self.iapHelper canMakePayments]) {
        [self.iapHelper requestProductForIds:productIds];
    }
}

- (void)purchaseProductForId:(NSString *)productId completion:(DYFStorePurchaseDidCompleteBlock)block {
    if ([self.iapHelper canMakePayments]) {
        if (productId.length > 0) {
            
            self.didCompleteBlock = block;
            self.m_productId      = productId;
            SKProduct *product    = [self getProduct:productId];
            
            if (product) {
                [self startPurchase:product];
            } else {
                [self showTipsWithMsg:@"正在获取商品信息"];
                [self.iapHelper requestProductForId:productId];
            }
            
        } else {
            
            [self showErrorWithMsg:@"商品ID不能为空"];
            
        }
    } else {
        
        [self showErrorWithMsg:@"此设备上禁用了购买"];
    }
}

- (void)restorePurchasesWithCompletion:(DYFStorePurchaseDidCompleteBlock)block {
    self.didCompleteBlock = block;
    [self.iapHelper restoreProducts];
}

- (void)startPurchase:(SKProduct *)product {
    [self showTipsWithMsg:@"正在发送购买请求"];
    [self.iapHelper buyProduct:product];
}

- (void)showTipsWithMsg:(NSString *)msg {
    //[SVProgressHUD showWithStatus:msg];
}

- (void)hideTips {
    //[SVProgressHUD dismiss];
}

- (void)showErrorWithMsg:(NSString *)msg {
    //[SVProgressHUD showErrorWithStatus:msg];
}

- (void)showInfoWithMsg:(NSString *)msg {
    //[SVProgressHUD showInfoWithStatus:msg];
}

#pragma mark - Observer

- (void)addStoreObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePurchasedNotification:) name:DYFIAPPurchaseNotification object:nil];
}

- (void)removeStoreObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DYFIAPPurchaseNotification object:nil];
}

#pragma mark - Getter

- (BOOL)iOS7orLater {
    return ([UIDevice currentDevice].systemVersion.doubleValue >= 7.0);
}

- (SKProduct *)getProduct:(NSString *)productId {
    return [self.iapHelper getProduct:productId];
}

- (NSString *)getStoreTransactionId:(SKPaymentTransaction *)trans {
    return trans.transactionIdentifier;
}

- (NSData *)getStoreReceipt:(SKPaymentTransaction *)trans {
    NSData *receipt = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([self iOS7orLater]) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        receipt           = [NSData dataWithContentsOfURL:receiptURL];
        if (!receipt) {
            receipt       = trans.transactionReceipt;
        }
    } else {
        receipt           = trans.transactionReceipt;
    }
#pragma clang diagnostic pop
    
    return receipt;
}

- (void)showAlertWithMessage:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alert.tag = Alert_Tag;
    [alert show];
}

- (void)showAlertWithCode:(NSInteger)code message:(NSString *)msg {
    NSString *title = [NSString stringWithFormat:@"%@\n%zi", msg, code];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重试", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag != Alert_Tag) {
            [self showTipsWithMsg:@"正在请求，请稍等"];
            [self retryHandleIapResult];
        } else {
            [self updateUserInfo];
        }
    } else {
        [self showInfoWithMsg:@"请尝试恢复购买或重启应用自动恢复购买"];
    }
}

#pragma mark - Match transaction

- (SKPaymentTransaction *)transaction:(NSString *)transactionId {
    SKPaymentTransaction *transaction = nil;
    for (SKPaymentTransaction *trans in self.iapHelper.purchasedProducts) {
        if ([trans.transactionIdentifier isEqualToString:transactionId]) {
            transaction = trans;
        }
    }
    for (SKPaymentTransaction *trans in self.iapHelper.restoredProducts) {
        if ([trans.transactionIdentifier isEqualToString:transactionId]) {
            transaction = trans;
        }
    }
    return transaction;
}

#pragma mark - DYFIAPHelperDelegate

- (void)productRequestDidComplete {
    DYFIAPProductRequestStatus status = self.iapHelper.productRequestStatus;
    if (status == DYFIAPProductFound || status == DYFIAPProductsFound) {
        SKProduct *product = [self.iapHelper getProduct:self.m_productId];
        [self startPurchase:product];
    } else if (status == DYFIAPProductRequestResponse) {
        // 发送产品信息
    } else if (status == DYFIAPIdentifiersNotFound) {
        [self showErrorWithMsg:@"商品不存在"];
    } else {
        [self showErrorWithMsg:self.iapHelper.productRequestError.localizedDescription];
    }
}

#pragma mark - Purchased Notification

- (void)handlePurchasedNotification:(NSNotification *)noti {
    [self.m_lock lock];
    
    DYFIAPPurchaseNotificationObject *nObject = [noti object];
    switch (nObject.status) {
        case DYFIAPStatusPurchasing: {
            [self showTipsWithMsg:@"购买中，请稍等"];
            //[SVProgressHUD dismissWithDelay:45 completion:^{}];
            break;
        }
            
        case DYFIAPPurchaseSucceeded: {
            NSString *storeTransId = nObject.transactionId;
            [self handleIapResult:[self transaction:storeTransId]];
            break;
        }
            
        case DYFIAPRestoredSucceeded: {
            NSString *storeTransId = nObject.transactionId;
            [self handleIapResult:[self transaction:storeTransId]];
            break;
        }
            
        case DYFIAPPurchaseFailed: {
            //DBLog(@"%@", nObject.message);
            [self hideTips];
            self.m_storeTransId = nObject.transactionId;
            [self removeTransaction];
            !self.didCompleteBlock ?: self.didCompleteBlock(NO, @"购买失败");
            break;
        }
            
        case DYFIAPRestoredFailed: {
            //DBLog(@"%@", nObject.message);
            [self hideTips];
            !self.didCompleteBlock ?: self.didCompleteBlock(NO, @"恢复失败，请重试");
            break;
        }
            
        case DYFIAPDownloadStarted: {
            //DBLog(@"Download started");
            break;
        }
            
        case DYFIAPDownloadInProgress: {
            //DBLog(@"Downloading: %.2f%%", nObject.downloadProgress);
            break;
        }
            
        case DYFIAPDownloadSucceeded: {
            //DBLog(@"Download complete: 100%%");
            break;
        }
            
        default: {
            [self hideTips];
            break;
        }
    }
    
    [self.m_lock unlock];
}

- (NSData *)iapInfoForID:(NSString *)storeTransId {
    NSDictionary *iapDataDict = [NSUserDefaults.standardUserDefaults objectForKey:kIapDataStorage];
    if (iapDataDict.count > 0) {
        return [iapDataDict objectForKey:storeTransId];
    }
    return nil;
}

- (void)storeIapInfo:(NSData *)data forId:(NSString *)storeTransId {
    NSDictionary *m_dict = [NSUserDefaults.standardUserDefaults objectForKey:kIapDataStorage];
    NSMutableDictionary *iapDataDict = [NSMutableDictionary dictionaryWithCapacity:0];
    [iapDataDict addEntriesFromDictionary:m_dict];
    [iapDataDict setValue:data forKey:storeTransId];
    [NSUserDefaults.standardUserDefaults setObject:iapDataDict forKey:kIapDataStorage];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)updateIapInfo:(BOOL)status forId:(NSString *)storeTransId {
    NSDictionary *m_dict = [NSUserDefaults.standardUserDefaults objectForKey:kIapDataStorage];
    NSMutableDictionary *iapDataDict = [NSMutableDictionary dictionaryWithCapacity:0];
    [iapDataDict addEntriesFromDictionary:m_dict];
    
    NSData *data = [iapDataDict objectForKey:storeTransId];
    DYFVendedModel *model = [self unarchiveObjectWithData:data];
    model.status = status;
    NSData *m_data = [self archivedDataWithObject:model];
    [iapDataDict setValue:m_data forKey:storeTransId];
    
    [NSUserDefaults.standardUserDefaults setObject:iapDataDict forKey:kIapDataStorage];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)removeIapInfoForId:(NSString *)storeTransId {
    NSDictionary *m_dict = [NSUserDefaults.standardUserDefaults objectForKey:kIapDataStorage];
    NSMutableDictionary *iapDataDict = [NSMutableDictionary dictionaryWithCapacity:0];
    [iapDataDict addEntriesFromDictionary:m_dict];
    [iapDataDict removeObjectForKey:storeTransId];
    [NSUserDefaults.standardUserDefaults setObject:iapDataDict forKey:kIapDataStorage];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSData *)archivedDataWithObject:(DYFVendedModel *)model {
    return [NSKeyedArchiver archivedDataWithRootObject:model];
}

- (DYFVendedModel *)unarchiveObjectWithData:(NSData *)archivedData {
    return (DYFVendedModel *)[NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
}

- (void)handleIapResult:(SKPaymentTransaction *)transaction {
    NSString *storeTransId = [self getStoreTransactionId:transaction];
    self.m_storeTransId = storeTransId;
    NSData *iapData = [self iapInfoForID:storeTransId];
    
    if (iapData.length > 0) {
        DYFVendedModel *model = [self unarchiveObjectWithData:iapData];
        [self sendDataToServerByModel:model];
    } else {
        NSData *receiptData = [self getStoreReceipt:transaction];
        NSString *base64Receipt = [receiptData base64EncodedStringWithOptions:0];
        self.model.receipt = base64Receipt;
        NSData *m_data = [self archivedDataWithObject:self.model];
        [self storeIapInfo:m_data forId:storeTransId];
        [self sendDataToServerByModel:self.model];
    }
}

- (void)sendDataToServerByModel:(DYFVendedModel *)model {
    NSInteger type = model.type;
    switch (type) {
        case 1: { // 专辑
            [self buyAlbum:model];
            break;
        }
            
        case 2: { // 打赏
            [self rewardAnchor:model];
            break;
        }
            
        case 3: { // 会员
            [self buyVip:model];
            break;
        }
            
        default:
            break;
    }
}

- (void)retryHandleIapResult {
    /**
    if (IsReachable()) {
        [self handleIapResult:[self transaction:self.m_storeTransId]];
    } else {
        [self showAlertWithCode:(NSInteger)NSURLErrorNotConnectedToInternet message:@"没有连接到网络"];
    }
    */
}

- (void)removeTransaction {
    SKPaymentTransaction *transaction = [self transaction:self.m_storeTransId];
    [self.iapHelper finishTransaction:transaction];
}

- (void)buyAlbum:(DYFVendedModel *)model {
    /**
    @WeakObject(self)
    [[AFN Manager] SendUrl:HttpURLString(@"/public/applepayback") SendData:@{@"token": [NSUserDefaults.standardUserDefaults objectForKey:@"token"], @"type": @(model.type), @"albumid": model.albumId, @"receipt": model.receipt} TimeoutInterval:20.f Completion:^(id responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        
        if (code == 1) {
            
            //NSString *orderId = responseObject[@"data"][@"ordernumber"];
            //DBLog(@"orderId: %@", orderId);
            //[weak_self verifyWithOrderID:orderID];
            [weak_self updateIapInfo:YES forId:weak_self.m_storeTransId];
            
            //NSData *m_data = [weak_self iapInfoForID:weak_self.m_storeTransId];
            //DYFVendedModel *m_model = [weak_self unarchiveObjectWithData:m_data];
            
            [weak_self removeTransaction];
            [weak_self verifyToken:responseObject[@"data"][@"token"]];
            
            if (weak_self.didCompleteBlock) {
                weak_self.didCompleteBlock(YES, responseObject[@"message"]);
            }
            
        } else {
            
            DBLog(@"%@", responseObject[@"message"]);
            [weak_self showAlertWithCode:code message:responseObject[@"message"]];
        }
        
        [weak_self hideTips];
        
    } Failure:^(NSError *error) {
        
        [weak_self hideTips];
        DBLog(@"%@", error.localizedDescription);
        [weak_self showAlertWithCode:error.code message:error.localizedDescription];
    }];
    */
}

- (void)buyVip:(DYFVendedModel *)model {
    /**
    @WeakObject(self)
    [[AFN Manager] SendUrl:HttpURLString(@"/public/applepayback/") SendData:@{@"token": [NSUserDefaults.standardUserDefaults objectForKey:@"token"], @"type": @(model.type), @"receipt": model.receipt} TimeoutInterval:20.f Completion:^(id responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        
        if (code == 1) {
            
            [weak_self updateIapInfo:YES forId:weak_self.m_storeTransId];
            
            [weak_self removeTransaction];
            [weak_self verifyToken:responseObject[@"data"][@"token"]];
            
            if (weak_self.didCompleteBlock) {
                weak_self.didCompleteBlock(YES, responseObject[@"message"]);
            }
            
        } else {
            
            DBLog(@"%@", responseObject[@"message"]);
            [weak_self showAlertWithCode:code message:responseObject[@"message"]];
        }
        
        [weak_self hideTips];
        
    } Failure:^(NSError *error) {
        
        [weak_self hideTips];
        DBLog(@"%@", error.localizedDescription);
        [weak_self showAlertWithCode:error.code message:error.localizedDescription];
    }];
    */
}

- (void)rewardAnchor:(DYFVendedModel *)model {
    /**
    @WeakObject(self)
    [[AFN Manager] SendUrl:HttpURLString(@"/public/applepayback") SendData:@{@"token": [NSUserDefaults.standardUserDefaults objectForKey:@"token"], @"type": @(model.type), @"anchorid": model.anchorId, @"albumid": model.albumId, @"price": model.price, @"receipt": model.receipt} TimeoutInterval:20.f Completion:^(id responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        
        if (code == 1) {
            
            [weak_self updateIapInfo:YES forId:weak_self.m_storeTransId];
            
            [weak_self removeTransaction];
            [weak_self verifyToken:responseObject[@"data"][@"token"]];
            
            if (weak_self.didCompleteBlock) {
                weak_self.didCompleteBlock(YES, responseObject[@"message"]);
            }
            
        } else {
            
            DBLog(@"%@", responseObject[@"message"]);
            [weak_self showAlertWithCode:code message:responseObject[@"message"]];
        }
        
        [weak_self hideTips];
        
    } Failure:^(NSError *error) {
        
        [weak_self hideTips];
        DBLog(@"%@", error.localizedDescription);
        [weak_self showAlertWithCode:error.code message:error.localizedDescription];
    }];
    */
}

// deprecate
- (void)verifyWithOrderID:(NSString *)orderId {
    /**
    NSData *iapData = [self iapInfoForID:self.m_storeTransId];
    DYFVendedModel *model = [self unarchiveObjectWithData:iapData];
    @WeakObject(self)
    [[AFN Manager] SendUrl:HttpURLString(@"/public/applepayback/") SendData:@{@"ordernumber": orderId, @"receipt": model.receipt} TimeoutInterval:20.f Completion:^(id responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        
        if (code == 1) {
            
            [weak_self updateIapInfo:YES forId:weak_self.m_storeTransId];
            
            NSData *m_data = [weak_self iapInfoForID:weak_self.m_storeTransId];
            DYFVendedModel *m_model = [weak_self unarchiveObjectWithData:m_data];
            
            [weak_self removeTransaction];
            if (m_model.type == 3) {
                [DefaultNotiCenter postNotificationName:@"getInfo" object:nil];
            }
            
            if (weak_self.didCompleteBlock) {
                weak_self.didCompleteBlock(YES, responseObject[@"message"]);
            }
            
        } else {
            
            DBLog(@"%@", responseObject[@"message"]);
            [weak_self showAlertWithCode:code message:responseObject[@"message"]];
        }
        
        [weak_self hideTips];
        
    } Failure:^(NSError *error) {
        
        [weak_self hideTips];
        DBLog(@"%@", error.localizedDescription);
        [weak_self showAlertWithCode:error.code message:error.localizedDescription];
    }];
    */
}

- (void)verifyToken:(NSString *)token {
//    NSString *currToken = [NSUserDefaults.standardUserDefaults objectForKey:@"token"];
//    if (StringEqual(token, currToken)) {
        [self updateUserInfo];
//    } else {
//      [self showAlertWithMessage:@"检测您当前的身份与购买的身份不相符，是否同意切换？若您不同意切换，则无法将购买的产品发放给您。"];
//    }
}

- (void)updateUserInfo {
    [NSNotificationCenter.defaultCenter postNotificationName:@"kUpdateUserInfo" object:nil];
}

- (void)dealloc {
    [self removeStoreObserver];
}

@end
