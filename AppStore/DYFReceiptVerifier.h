//
//  DYFReceiptVerifier.h
//
//  Created by dyf on 15/11/4.
//  Copyright (c) 2015 dyf. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DYFReceiptVerifierDelegate <NSObject>

@optional

// Tells the delegate that the receipt validation has completed.
// The error that caused the receipt validation to fail.
- (void)verifyReceiptDidComplete:(nullable NSDictionary *)response error:(nullable NSError *)error;

@end
@interface DYFReceiptVerifier : NSObject

// The delegate that receives the response of the request.
@property (nonatomic, weak, nullable) id<DYFReceiptVerifierDelegate> delegate;

// Verifies receipt but recommend to use in server side instead of using this function.
- (void)verifyReceipt:(nonnull NSData *)receiptData;

// Verifies receipt but recommend to use in server side instead of using this function.
// Only used for receipts that contain auto-renewable subscriptions.
// Your app’s shared secret (a hexadecimal string).
- (void)verifyReceipt:(nonnull NSData *)receiptData sharedSecret:(nullable NSString *)secretKey;

@end
