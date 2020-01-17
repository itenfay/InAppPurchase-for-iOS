//
// DYFReceiptVerifier.m
//
//  Created by dyf on 2015/11/04.
//  Copyright © 2015 dyf. ( https://github.com/dgynfi/InAppPurchase-for-iOS )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "DYFReceiptVerifier.h"

// https://sandbox.itunes.apple.com/verifyReceipt
static const char __6FD0F31B976A325E[] = {0x68, 0x74, 0x74, 0x70, 0x73, 0x3a, 0x2f, 0x2f, 0x73, 0x61, 0x6e, 0x64, 0x62, 0x6f, 0x78, 0x2e, 0x69, 0x74, 0x75, 0x6e, 0x65, 0x73, 0x2e, 0x61, 0x70, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x76, 0x65, 0x72, 0x69, 0x66, 0x79, 0x52, 0x65, 0x63, 0x65, 0x69, 0x70, 0x74};

// https://buy.itunes.apple.com/verifyReceipt
static const char __68C346B47CD9834D[] = {0x68, 0x74, 0x74, 0x70, 0x73, 0x3a, 0x2f, 0x2f, 0x62, 0x75, 0x79, 0x2e, 0x69, 0x74, 0x75, 0x6e, 0x65, 0x73, 0x2e, 0x61, 0x70, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x76, 0x65, 0x72, 0x69, 0x66, 0x79, 0x52, 0x65, 0x63, 0x65, 0x69, 0x70, 0x74};

// Decodes C string.
CG_INLINE NSString *DYFDecodeCString(const char *bytes) {
    return bytes ? [NSString stringWithUTF8String:bytes] : nil;
}

// Returns a Boolean value that indicates whether the receiver implements or inherits a method that can respond to a specified message.
#define DYF_RESPONDS_TO_SEL(target, selector) (target && [target respondsToSelector:selector])

@interface DYFReceiptVerifier ()

// The store request data for a POST request.
@property (nonatomic, strong) NSData *storeRequestData;

@end

@implementation DYFReceiptVerifier

- (void)verifyReceipt:(NSData *)receiptData {
    [self verifyReceipt:receiptData sharedSecret:nil];
}

- (void)verifyReceipt:(NSData *)receiptData sharedSecret:(NSString *)secretKey {
    NSString *receiptBase64 = [receiptData base64EncodedStringWithOptions:0];
    
    // Create the JSON object that describes the request.
    NSError *error = nil;
    if(secretKey && secretKey.length > 0) {
        NSMutableDictionary *requestContents = [NSMutableDictionary dictionaryWithCapacity:0];
        [requestContents setValue:receiptBase64 forKey:@"receipt-data"];
        [requestContents setValue:secretKey forKey:@"password"];
        self.storeRequestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    } else {
        NSMutableDictionary *requestContents = [NSMutableDictionary dictionaryWithCapacity:0];
        [requestContents setValue:receiptBase64 forKey:@"receipt-data"];
        self.storeRequestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    }
    
    if (!error) {
        // https://buy.itunes.apple.com/verifyReceipt
        [self connectionWithURL:DYFDecodeCString(__68C346B47CD9834D)];
    } else {
        if (DYF_RESPONDS_TO_SEL(self.delegate, @selector(verifyReceiptDidComplete:error:))) {
            [self.delegate verifyReceiptDidComplete:nil error:error];
        }
    }
}

- (void)connectionWithURL:(NSString *)urlString {
    // Create a POST request with the receipt data.
    NSURL *requstURL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requstURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:self.storeRequestData];
    
    // Make a connection to the iTunes Store on a background queue.
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self connectionDidReceiveData:data response:response error:error];
    }];
    [dataTask resume];
}

// *******************************************************************************
// 0    : receipt校验通过
// 21000: App Store不能读取你提供的JSON对象
// 21002: receipt-data域的数据有问题
// 21003: receipt无法通过验证
// 21004: 提供的shared secret不匹配你账号中的shared secret
// 21005: receipt服务器当前不可用
// 21006: receipt合法，但是订阅已过期。服务器接收到这个状态码时，receipt数据仍然会解码并一起发送
// 21007: receipt是Sandbox receipt，但却发送至生产系统的验证服务
// 21008: receipt是生产receipt，但却发送至Sandbox环境的验证服务
// ******************************************************************************

- (void)connectionDidReceiveData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            NSError *m_error = nil;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&m_error];
            if (!m_error) {
                NSInteger status = [[jsonResponse objectForKey:@"status"] integerValue];
                if (status == 21007) {
                    // https://sandbox.itunes.apple.com/verifyReceipt
                    [self connectionWithURL:DYFDecodeCString(__6FD0F31B976A325E)];
                } else {
                    if (DYF_RESPONDS_TO_SEL(self.delegate, @selector(verifyReceiptDidComplete:error:))) {
                        [self.delegate verifyReceiptDidComplete:jsonResponse error:nil];
                    }
                }
            } else {
                if (DYF_RESPONDS_TO_SEL(self.delegate, @selector(verifyReceiptDidComplete:error:))) {
                    [self.delegate verifyReceiptDidComplete:nil error:m_error];
                }
            }
        } else {
            if (DYF_RESPONDS_TO_SEL(self.delegate, @selector(verifyReceiptDidComplete:error:))) {
                [self.delegate verifyReceiptDidComplete:nil error:error];
            }
        }
    });
}

@end
