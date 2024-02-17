//
//  ZlibCompressor.h
//  eboy
//
//  Created by Lucius Kwok on 12/7/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZlibCompressor : NSObject
+ (NSData*)compressData:(NSData *)inputData;
+ (NSData *)uncompressData:(NSData *)inputData;
+ (NSData *)uncompressFile:(NSURL *)inputFile;
@end
